# MangoWM fork notes

## Minimal mode

This fork currently runs in a minimal mode that avoids Quickshell PipeWire-backed audio widgets.

Reason:
- your runtime showed repeated `quickshell.service.pipewire.node` errors
- these appear to come from PipeWire device/node enumeration rather than QML syntax errors

## Current behavior

- the old mixer entry now opens a generic `System` panel placeholder
- the dedicated PipeWire-based mixer surface is not used by `PillShell.qml`

## If you want audio back later

Possible next steps:
1. keep Quickshell UI and swap audio control to `wpctl` shell commands
2. reintroduce PipeWire widgets only after confirming your Quickshell/PipeWire environment is clean
3. make audio modules optional behind a boolean feature flag
