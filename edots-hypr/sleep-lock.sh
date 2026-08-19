#!/usr/bin/bash

hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf &

sleep 5
systemctl suspend
