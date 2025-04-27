#!/bin/sh

set -e

RAW_CONTENT_URL="https://raw.githubusercontent.com/shetty-tejas/devsetup/refs/heads/master"
DESTINATION_FOLDER="/usr/local/bin"
BINARY_NAME="devsetup"
BINARY_FILE_LOCATION="$DESTINATION_FOLDER/$BINARY_NAME"

install() {
  if [ -e "$BINARY_FILE_LOCATION" ]; then
    printf "Error: %s already exists in %s.\n\nOptions:\n  - To update: Run '%s update-self'.\n  - To add to PATH: Add '%s' to your PATH variable.\n\n" "$BINARY_NAME" "$DESTINATION_FOLDER" "$BINARY_NAME" "$DESTINATION_FOLDER"
    return 1
  fi

  binary_url="$RAW_CONTENT_URL/$BINARY_NAME.sh"
  temp_file=$(mktemp)

  echo "Installing devsetup..."

  if type curl >/dev/null 2>&1; then
    # Use -f to fail on server errors and -S to show errors
    if ! curl -s -S -f -L "$binary_url" -o "$temp_file"; then
      echo "Error: Failed to download the latest version"
      rm -f "$temp_file"
      return 1
    fi
  else
    echo "Error: curl not found."
    rm -f "$temp_file"
    return 1
  fi

  # Check if the download was successful and the file is not empty
  if [ ! -s "$temp_file" ]; then
    echo "Error: Downloaded file is empty"
    rm -f "$temp_file"
    return 1
  fi
  
  # Make sure the downloaded file is a valid shell script
  first_line=$(head -n 1 "$temp_file")

  if printf "%s" "$first_line" | grep -Eq '^#!.*[ /](bash|sh)'; then
    :
  else
    echo "Error: Downloaded file doesn't appear to be a valid shell script"
    rm -f "$temp_file"
    return 1
  fi

  echo "Making directory at $DESTINATION_FOLDER if it doesn't exist."
  
  if ! mkdir -p "$DESTINATION_FOLDER"; then
    rm -f "$temp_file"
    echo "Error: Permission denied. Please run the script with 'sudo' command."
    return 1
  fi

  if ! touch "$BINARY_FILE_LOCATION"; then
    rm -f "$temp_file"
    echo "Error: Permission denied. Please run the script with 'sudo' command."
    return 1
  fi

  cat "$temp_file" > "$BINARY_FILE_LOCATION"
  chmod +x "$BINARY_FILE_LOCATION"
  rm -f "$temp_file"

  printf "Installed %s at %s.\nPlease add this location to your PATH if not already done.\n" "$BINARY_NAME" "$DESTINATION_FOLDER"
}

install
