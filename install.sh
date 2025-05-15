#!/bin/sh

set -e

BINARY_NAME="devsetup"
DESTINATION_FOLDER="$HOME/.local/bin"
RAW_CONTENT_URL="https://raw.githubusercontent.com/shetty-tejas/devsetup/refs/heads/master"

BINARY_FILE_LOCATION="$DESTINATION_FOLDER/$BINARY_NAME"

# Utility Functions

# Function to echo messages to STDERR.
error() { printf "ERROR: %b\n" "$1" >&2; }
# Function to echo messages to STDOUT.
log() { printf "%b\n" "$1"; }

# Command Functions.

# Function to install devsetup.
install() {
  if [ -e "$BINARY_FILE_LOCATION" ]; then
    error "'$BINARY_NAME' already exists in '$DESTINATION_FOLDER'.\n\nOptions:\n  - To update: Run '$BINARY_NAME update-self'.\n  - To add to PATH: Add '$DESTINATION_FOLDER' to your PATH variable."

    exit 1
  fi

  binary_url="$RAW_CONTENT_URL/$BINARY_NAME"
  temp_file=$(mktemp)

  log "Downloading 'devsetup'..."

  if command -v curl >/dev/null 2>&1; then
    if ! curl -s -S -f "$binary_url" -o "$temp_file"; then
      error "Failed to download the latest version."

      rm -f "$temp_file"
      exit 1
    fi
  else
    error "'curl' not found."

    rm -f "$temp_file"
    exit 1
  fi

  # Check if the download was successful and the file is not empty
  if [ ! -s "$temp_file" ]; then
    error "Downloaded file is empty."

    rm -f "$temp_file"
    exit 1
  fi

  # Make sure the downloaded file is a valid shell script
  first_line=$(head -n 1 "$temp_file")

  if log "$first_line" | grep -Eq '^#!.*[ /](bash|sh)'; then
    :
  else
    error "Downloaded file doesn't appear to be a valid shell script."

    rm -f "$temp_file"
    exit 1
  fi

  log "Making directory at '$DESTINATION_FOLDER' if it doesn't exist..."
  mkdir -p "$DESTINATION_FOLDER"

  log "Writing the script at '$BINARY_FILE_LOCATION'..."
  touch "$BINARY_FILE_LOCATION"
  cat "$temp_file" >"$BINARY_FILE_LOCATION"
  chmod +x "$BINARY_FILE_LOCATION"

  log "Cleaning up..."
  rm -f "$temp_file"

  log "Installed '$BINARY_NAME' at '$DESTINATION_FOLDER'.\nPlease add this location to your PATH if not already done."
  log "Run '$BINARY_NAME init-config' to initialize a sample configuration file."
  exit 0
}

install
