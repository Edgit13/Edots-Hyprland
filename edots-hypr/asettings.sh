#!/usr/bin/bash

file="settings.edot"

clear
figlet "WELCOME"

echo ":"
echo ":"

echo "Preparing"
sleep 0.5

create_settings() {
  echo "creating settings..."
  cat >"$file" <<'EOF'
WELCOME to settings file for EDOT eco system:

to set some of settings use:
  {theme}:
    font: JetBrains Nerd Font
    theme: dark
  {plugin}:
    #your plugin
this is a default one

{theme}:
  font: JetBrains Nerd Font
  theme: dark
EOF
}

sleep 1

sleep 1
clear

echo "checking if file here..."
if [ -f "$file" ]; then
  echo "Exist: $file"
else
  echo "Missing: $file"
  sleep 1
  create_settings
fi

echo "done"
sleep 0.5
