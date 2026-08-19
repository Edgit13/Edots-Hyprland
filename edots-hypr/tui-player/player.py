#!/usr/bin/env python3
from pathlib import Path
import os
import sys
import argparse
import socket
import asyncio
import time
import threading
import json
import vlc

from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, ListView, ListItem, Button, Static, Input
from textual.containers import Horizontal, Vertical


AUDIO_EXTS = {".mp3", ".wav", ".flac", ".ogg", ".m4a", ".aac"}
SOCKET_PATH = Path("/tmp/tui_music_player.sock")


def ensure_venv():
    """Automatically re-executes the script using .venv python if available."""
    script_dir = Path(__file__).parent.resolve()
    venv_python = script_dir / ".venv" / "bin" / "python"

    if venv_python.exists():
        try:
            if Path(sys.executable).resolve() != venv_python.resolve():
                os.execv(str(venv_python), [str(venv_python)] + sys.argv)
        except Exception:
            pass


class HeadlessAudioEngine:
    """Core audio playback and socket IPC server (headless background engine)."""

    def __init__(self, start_folder: str = "~/Music/Default", ui_app: App | None = None):
        self.ui_app = ui_app
        path_obj = Path(start_folder).expanduser()
        if not path_obj.exists():
            path_obj.mkdir(parents=True, exist_ok=True)
        self.folder = path_obj.resolve()

        self.tracks: list[Path] = []
        self.current_index: int | None = None
        self.target_volume: int = 100
        self.is_fading: bool = False

        # VLC player instance
        self.instance = vlc.Instance()
        self.player = self.instance.media_player_new()
        self.player.audio_set_volume(self.target_volume)

        # Initial track scan
        self.load_folder(self.folder, auto_play=False)

    def notify_ui(self, callback, *args, **kwargs):
        """Dispatches state updates safely back to the Textual UI if attached."""
        if self.ui_app is not None:
            try:
                self.ui_app.call_from_thread(callback, *args, **kwargs)
            except Exception:
                pass

    # --- Smooth Fade Transitions ---
    def fade_out(self, duration: float = 0.25) -> None:
        steps = 10
        step_time = duration / steps
        current_vol = self.player.audio_get_volume()
        if current_vol < 0:
            current_vol = self.target_volume

        for i in range(steps, -1, -1):
            vol = int(current_vol * (i / steps))
            self.player.audio_set_volume(vol)
            time.sleep(step_time)

    def fade_in(self, duration: float = 0.25) -> None:
        steps = 10
        step_time = duration / steps
        self.player.audio_set_volume(0)

        for i in range(0, steps + 1):
            vol = int(self.target_volume * (i / steps))
            self.player.audio_set_volume(vol)
            time.sleep(step_time)

    def transition_and_run(self, action_func) -> None:
        if self.is_fading:
            return

        def _transition_thread():
            self.is_fading = True
            state = self.player.get_state()
            if state == vlc.State.Playing:
                self.fade_out(duration=0.2)

            action_func()

            new_state = self.player.get_state()
            if new_state == vlc.State.Playing:
                self.fade_in(duration=0.2)
            self.is_fading = False

        threading.Thread(target=_transition_thread, daemon=True).start()

    # --- Media Logic ---
    def load_folder(self, folder: Path, auto_play: bool = False) -> None:
        self.folder = folder
        self.tracks = []
        self.current_index = None

        if not folder.exists() or not folder.is_dir():
            self.refresh_ui()
            return

        for p in sorted(folder.iterdir()):
            if p.is_file() and p.suffix.lower() in AUDIO_EXTS:
                self.tracks.append(p)

        if self.tracks:
            self.current_index = 0
            if auto_play:
                self.play_current()

        self.refresh_ui()

    def refresh_ui(self) -> None:
        if self.ui_app is not None and hasattr(self.ui_app, "update_ui_state"):
            self.notify_ui(self.ui_app.update_ui_state)

    def play_current(self) -> None:
        if self.current_index is None or not self.tracks:
            return

        track = self.tracks[self.current_index]
        media = vlc.Media(str(track))
        self.player.set_media(media)
        self.player.play()
        self.refresh_ui()

    def toggle_play_pause(self) -> None:
        def _toggle():
            state = self.player.get_state()
            if state in (vlc.State.Playing,):
                self.player.pause()
            else:
                if self.current_index is None:
                    self.current_index = 0
                if not self.tracks:
                    return
                if self.player.get_media() is None:
                    self.play_current()
                else:
                    self.player.play()
            self.refresh_ui()

        self.transition_and_run(_toggle)

    def stop_playback(self) -> None:
        def _stop():
            self.player.stop()
            self.refresh_ui()

        self.transition_and_run(_stop)

    def next_track(self) -> None:
        if not self.tracks:
            return
        if self.current_index is None:
            self.current_index = 0
        else:
            self.current_index = (self.current_index + 1) % len(self.tracks)
        self.transition_and_run(self.play_current)

    def prev_track(self) -> None:
        if not self.tracks:
            return
        if self.current_index is None:
            self.current_index = 0
        else:
            self.current_index = (self.current_index - 1) % len(self.tracks)
        self.transition_and_run(self.play_current)

    def get_status_info(self) -> dict:
        state = str(self.player.get_state())
        track = self.tracks[self.current_index].name if (self.current_index is not None and self.tracks) else None
        return {
            "state": state,
            "now_playing": track,
            "folder": str(self.folder),
            "track_count": len(self.tracks),
            "current_index": self.current_index
        }

    # --- IPC Server Handler ---
    async def start_cmd_server(self) -> None:
        if SOCKET_PATH.exists():
            SOCKET_PATH.unlink()

        async def handle_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
            data = await reader.read(512)
            raw_cmd = data.decode().strip()
            parts = raw_cmd.split(maxsplit=1)
            cmd = parts[0].lower() if parts else ""
            arg = parts[1] if len(parts) > 1 else ""

            response = f"Executed: {cmd}"

            if cmd in ("play", "pause", "toggle"):
                self.toggle_play_pause()
            elif cmd == "next":
                self.next_track()
            elif cmd == "prev":
                self.prev_track()
            elif cmd == "stop":
                self.stop_playback()
            elif cmd == "load" and arg:
                p = Path(arg).expanduser().resolve()
                self.load_folder(p, auto_play=True)
                response = f"Loaded folder: {p}"
            elif cmd == "status":
                response = json.dumps(self.get_status_info())

            writer.write(f"{response}\n".encode())
            await writer.drain()
            writer.close()

        await asyncio.start_unix_server(handle_client, path=str(SOCKET_PATH))


class MusicPlayerApp(App):
    CSS = """
    /* Tactical Sci-Fi / Cyberpunk HUD Theme */
    Screen {
        background: #141613;
        color: #c5d19c;
    }

    Header {
        background: #1c1f19;
        color: #dae6ab;
        dock: top;
    }

    Footer {
        background: #1c1f19;
        color: #8c9869;
    }

    #now_playing {
        background: #191c16;
        color: #e5f2b8;
        border: heavy #7e8c54;
        padding: 1 2;
        margin: 1 1 0 1;
        text-align: center;
        text-style: bold;
    }

    #folder_row {
        height: auto;
        margin: 1;
        align: center middle;
    }

    #folder_input {
        background: #10120e;
        color: #dbe8af;
        border: ascii #6b7747;
        width: 1fr;
    }

    #folder_input:focus {
        border: double #b8ca7a;
        background: #191c16;
    }

    #load_btn {
        background: #252a20;
        color: #cde094;
        border: ascii #6b7747;
        min-width: 10;
        margin-left: 1;
    }

    #load_btn:hover {
        background: #363d2e;
        color: #f1ffbf;
        border: double #a3b56c;
    }

    ListView {
        background: #10120f;
        border: panel #647040;
        margin: 0 1 1 1;
        height: 1fr;
    }

    ListItem {
        padding: 0 1;
        color: #aab880;
        background: #10120f;
    }

    ListItem:hover {
        background: #20241b;
        color: #e3f2b1;
    }

    ListItem.--highlight {
        background: #2e3526;
        color: #f5ffca;
        text-style: bold;
    }

    #action_row {
        height: auto;
        margin: 0 1 1 1;
        align: center middle;
    }

    #action_row Button {
        background: #1d211a;
        color: #b3c480;
        border: ascii #596439;
        margin: 0 1;
        min-width: 14;
    }

    #action_row Button:hover {
        background: #31382a;
        color: #ecfcb3;
        border: double #a2b467;
    }

    #action_row Button:focus {
        background: #3d4634;
        color: #ffffff;
        border: heavy #cbe07d;
    }
    """

    def __init__(self, start_folder: str = "~/Music/Default"):
        super().__init__()
        self.engine = HeadlessAudioEngine(start_folder=start_folder, ui_app=self)

    def compose(self) -> ComposeResult:
        yield Header()
        yield Static("Now playing: (nothing yet)", id="now_playing")

        with Vertical():
            with Horizontal(id="folder_row"):
                yield Input(
                    placeholder="Folder path (e.g. ~/Music/Default)",
                    value=str(self.engine.folder),
                    id="folder_input"
                )
                yield Button("Load", id="load_btn")

            yield ListView(id="track_list")
            with Horizontal(id="action_row"):
                yield Button("Prev", id="prev_btn")
                yield Button("Play/Pause", id="play_btn")
                yield Button("Next", id="next_btn")

        yield Footer()

    async def on_mount(self) -> None:
        self.update_ui_state()
        await self.engine.start_cmd_server()

    def update_ui_state(self) -> None:
        # Refresh now playing label
        now_playing_widget = self.query_one("#now_playing", Static)
        if self.engine.current_index is not None and self.engine.tracks:
            track = self.engine.tracks[self.engine.current_index]
            now_playing_widget.update(
                f"Now playing: {track.name} ({self.engine.current_index + 1}/{len(self.engine.tracks)})"
            )
        else:
            now_playing_widget.update("Now playing: (nothing yet)")

        # Refresh track list
        lv = self.query_one("#track_list", ListView)
        lv.clear()

        if not self.engine.tracks:
            lv.append(ListItem(Static("No audio files found in this folder")))
            return

        for i, track in enumerate(self.engine.tracks):
            text = f"{i+1:02d}. {track.name}"
            item = ListItem(Static(text))
            item.data = i
            lv.append(item)

        self.query_one("#folder_input", Input).value = str(self.engine.folder)

    def on_list_view_selected(self, event) -> None:
        item = event.item
        if item is None:
            return
        index = getattr(item, "data", None)
        if isinstance(index, int):
            self.engine.current_index = index
            self.engine.transition_and_run(self.engine.play_current)

    def on_button_pressed(self, event) -> None:
        bid = event.button.id
        if bid == "load_btn":
            inp = self.query_one("#folder_input", Input).value
            self.engine.load_folder(Path(inp).expanduser().resolve(), auto_play=True)
        elif bid == "play_btn":
            self.engine.toggle_play_pause()
        elif bid == "next_btn":
            self.engine.next_track()
        elif bid == "prev_btn":
            self.engine.prev_track()


def send_cli_command(command: str) -> bool:
    if not SOCKET_PATH.exists():
        print("Player is not currently running.")
        return False

    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(str(SOCKET_PATH))
        client.sendall(command.encode())
        response = client.recv(1024).decode()
        print(response.strip())
        client.close()
        return True
    except Exception as e:
        print(f"Failed to communicate with player: {e}")
        return False


def run_headless_daemon(start_folder: str = "~/Music/Default"):
    """Runs the music engine completely in the background without UI."""
    print(f"Starting player in daemon background mode...")
    engine = HeadlessAudioEngine(start_folder=start_folder)

    async def _runner():
        await engine.start_cmd_server()
        print("Daemon background server initialized on IPC socket.")
        while True:
            await asyncio.sleep(3600)

    try:
        asyncio.run(_runner())
    except KeyboardInterrupt:
        if SOCKET_PATH.exists():
            SOCKET_PATH.unlink()
        print("Daemon stopped.")


if __name__ == "__main__":
    ensure_venv()

    parser = argparse.ArgumentParser(description="TUI & Background Music Player")
    parser.add_argument(
        "-c", "--command",
        help="Send command to running player instance (play, pause, toggle, next, prev, stop, status, load <path>, start)"
    )
    parser.add_argument(
        "-d", "--daemon",
        action="store_true",
        help="Run in headless background daemon mode without terminal UI"
    )

    args = parser.parse_args()

    if args.daemon:
        run_headless_daemon()
    elif args.command:
        if args.command == "start":
            if SOCKET_PATH.exists():
                send_cli_command("play")
            else:
                app = MusicPlayerApp(start_folder="~/Music/Default")
                app.run()
        else:
            send_cli_command(args.command)
    else:
        app = MusicPlayerApp(start_folder="~/Music/Default")
        app.run()
