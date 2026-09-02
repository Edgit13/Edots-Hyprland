# Quickshell MangoWM fork

This directory is a fork of `quickshell/bar` adapted as a starting point for MangoWM.

## What was changed

- color source moved from `~/.config/hypr/colors.json` to `~/.config/quickshell-mangowm/colors.json`
- `GameMode.qml` now calls `~/.config/quickshell-mangowm/scripts/gamemode.sh`
- `Workspaces.qml` no longer imports `Quickshell.Hyprland`
- `reload.sh` now targets the MangoWM fork path

## What still needs MangoWM integration

This fork is intentionally only minimally decoupled from Hyprland. Some surfaces and actions still assume Hyprland tools or config paths, for example:

- power/session actions that call `hyprlock` or `hyprctl`
- game mode logic if you want MangoWM-specific compositor toggles
- any external scripts that still live under your Hyprland config tree

## Suggested runtime layout

```text
~/.config/quickshell-mangowm/
├── bar/
│   └── shell.qml
├── scripts/
│   └── gamemode.sh
└── colors.json
```

## Run

```bash
qs -p ~/.config/quickshell-mangowm/bar
```
