#!/usr/bin/env bash

set -e

readonly RAW_CONTENT_URL="https://raw.githubusercontent.com/shetty-tejas/devsetup/refs/heads/master"
readonly DESTINATION_FOLDER="/usr/local/bin"
readonly BINARY_NAME="devsetup"
readonly BINARY_FILE_LOCATION="$DESTINATION_FOLDER/$BINARY_NAME"

# Function to self-update from a GitHub repository
update_self() {
  echo "Checking for updates..."
  
  local binary_url="$RAW_CONTENT_URL/$BINARY_NAME.sh"

  # Get the path of the current script
  local current_script="$0"
  
  # Create a temporary file for the download
  local temp_file=$(mktemp)
  
  # Download the latest version from GitHub 
  echo "Downloading latest version from $download_url"

  if command -v curl &> /dev/null; then
    # Use -f to fail on server errors and -S to show errors
    if ! curl -s -S -f -L "$binary_url" -o "$temp_file"; then
      echo "Failed to download the latest version"

      rm -f "$temp_file"
      return 1
    fi
  else
    echo "Error: curl not found."

    rm -f "$temp_file"
    return 1
  fi
  
  # Check if the download was successful and the file is not empty
  if [[ ! -s "$temp_file" ]]; then
    echo "Error: Downloaded file is empty"

    rm -f "$temp_file"
    return 1
  fi
  
  # Make sure the downloaded file is a valid shell script
  if ! head -n1 "$temp_file" | grep -q "^#!.*bash" && ! head -n1 "$temp_file" | grep -q "^#!.*sh"; then
    echo "Error: Downloaded file doesn't appear to be a valid shell script"

    rm -f "$temp_file"
    return 1
  fi
  
  # Compare versions (optional - you can add version checking logic here)
  # For basic usage, you could just check if files are different
  if cmp -s "$current_script" "$temp_file"; then
    echo "Already up to date"

    rm -f "$temp_file"
    return 0
  fi

  # Replace the current script with the new version
  echo "Updating to the latest version..."

  cat "$temp_file" > "$current_script"
  rm -f "$temp_file"
  chmod +x "$current_script"
  
  echo "Update successful! Please run the script again."

  exit 0
}

# Other functions will be added below

# Main function
main() {
  # Process command line arguments
  if [[ "$1" == "update-self" ]]; then
    update_self
    exit $?
  fi
  
  # Rest of your script logic will go here
  echo -e "devsetup\nRun with 'update-self' argument to update the script"
}

# Execute main function with all arguments
main "$@"
