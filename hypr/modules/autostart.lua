-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/quickshell/bar/reload.sh")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("sleep 5 && hyprctl setcursor Moga-Black 24")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("swaync")
	hl.exec_cmd("blueman-applet & nm-applet --indicator &")
	hl.exec_cmd("~/edots-hypr/run.sh")
	hl.exec_cmd("python3 ~/edots-hypr/tui-player/forks/player.py -d")
end)
