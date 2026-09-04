# Quickshell lock scaffold

This is a separate Quickshell lockscreen-style config inspired by the Ricelin lock layout.

## Purpose

- lives separately from `quickshell/bar`
- reuses `~/.config/quickshell/colors.json`
- reads the current wallpaper path from `~/.config/mango/swaylock/colors.conf`
- displays clock, date, avatar, weather, and media info

## Important note

This lock config is now wired for real session locking with:

- `Quickshell.Wayland.WlSessionLock`
- `Quickshell.Services.Pam`

So it is no longer only a visual scaffold. It should be treated as an experimental real locker config and tested carefully in your session.

## Run

```bash
qs -p ~/.config/quickshell/lock/shell.qml
```
