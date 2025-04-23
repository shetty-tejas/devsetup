#!/usr/bin/env bash

# Function to self-update from a GitHub repository
update_self() {
  echo "Checking for updates..."
  
  local repo_owner="shetty-tejas"
  local repo_name="devsetup"
  local script_path="devsetup.sh"
  local branch="master"
  
  # Get the path of the current script
  local current_script="$0"
  
  # Create a temporary file for the download
  local temp_file=$(mktemp)
  
  # Download the latest version from GitHub
  local download_url="https://raw.githubusercontent.com/$repo_owner/$repo_name/refs/heads/$branch/$script_path"
  
  echo "Downloading latest version from $download_url"
  
  if command -v curl &> /dev/null; then
    # Use -f to fail on server errors and -S to show errors
    if ! curl -s -S -f -L "$download_url" -o "$temp_file"; then
      echo "Failed to download the latest version"
      rm -f "$temp_file"
      return 1
    fi
  elif command -v wget &> /dev/null; then
    # Use --server-response to check status code
    if ! wget -q --server-response "$download_url" -O "$temp_file" 2>&1 | grep -q "HTTP/1.1 200 OK"; then
      echo "Failed to download the latest version"
      rm -f "$temp_file"
      return 1
    fi
  else
    echo "Error: Neither curl nor wget is available"
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
  
  # Make the downloaded file executable
  chmod +x "$temp_file"
  
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
  echo "Dev Setup Tool"
  echo "Run with 'update-self' argument to update the script"
}

# Execute main function with all arguments
main "$@"
