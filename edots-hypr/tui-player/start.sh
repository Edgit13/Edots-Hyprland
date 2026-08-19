#!/usr/bin/bash

figlet "WELCOME"

echo ""
echo "Preparing environment..."

if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  python3 -m venv .venv
  source .venv/bin/activate
  echo "Installing libraries..."
  pip install --upgrade pip
  pip install textual python-vlc mutagen
else
  source .venv/bin/activate
fi

echo "Starting player..."
python3 player.py
