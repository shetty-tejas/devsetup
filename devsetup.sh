#!/bin/sh

set -e

RAW_CONTENT_URL="https://raw.githubusercontent.com/shetty-tejas/devsetup/refs/heads/master"
DESTINATION_FOLDER="/usr/local/bin"
BINARY_NAME="devsetup"
BINARY_FILE_LOCATION="$DESTINATION_FOLDER/$BINARY_NAME"

# Function to self-update from a GitHub repository
update_self() {
  printf '%s\n' "Checking for updates..."
  
  binary_url="$RAW_CONTENT_URL/$BINARY_NAME.sh"
  temp_file=$(mktemp)
  
  printf '%s\n' "Downloading latest version from $binary_url"

  if command -v curl >/dev/null 2>&1; then
    if ! curl -s -S -f -L "$binary_url" -o "$temp_file"; then
      printf '%s\n' "Failed to download the latest version"
      rm -f "$temp_file"
      return 1
    fi
  else
    printf '%s\n' "Error: curl not found."
    rm -f "$temp_file"
    return 1
  fi
  
  if [ ! -s "$temp_file" ]; then
    printf '%s\n' "Error: Downloaded file is empty"
    rm -f "$temp_file"
    return 1
  fi
  
  first_line=$(head -n 1 "$temp_file")

  if printf '%s\n' "$first_line" | grep -Eq '^#!.*[ /](bash|sh)'; then
    :
  else
    printf '%s\n' "Error: Downloaded file doesn't appear to be a valid shell script"
    rm -f "$temp_file"
    return 1
  fi
  
  if cmp -s "$BINARY_FILE_LOCATION" "$temp_file"; then
    printf '%s\n' "Already up to date"
    rm -f "$temp_file"
    return 0
  fi

  printf '%s\n' "Updating to the latest version..."

  if ! cat "$temp_file" > "$BINARY_FILE_LOCATION"; then
    rm -f "$temp_file"
    echo "Error: Permission denied. Please run the script with 'sudo' command."
    return 1
  fi

  rm -f "$temp_file"
  chmod +x "$BINARY_FILE_LOCATION"

  printf '%s\n' "Update successful! Please run the script again."
  exit 0
}

# Main function
main() {
  if [ "$1" = "update-self" ]; then
    update_self
    exit $?
  fi
  
  printf '%s\n' "devsetup"
  printf '%s\n' "Run with 'update-self' argument to update the script"
}

# Execute main function with all arguments
main "$@"
