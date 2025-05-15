#!/bin/sh

# Test script for devsetup

# Source the main script so we can test functions directly
. "$(dirname "$0")/devsetup"

# Create test directory if it doesn't exist
test_dir="/tmp/devsetup_tests"
mkdir -p "$test_dir"

run_test() {
  test_name="$1"
  expected="$2"
  result="$3"

  if [ "$result" = "$expected" ]; then
    echo "✅ $test_name passed"
  else
    echo "❌ $test_name failed: Expected '$expected', got '$result'"
  fi
}

test_parse_config() {
  echo "Running parse_config tests..."

  # Test 1: Basic JSON parsing
  echo '{"test": "value"}' >"$test_dir/test1.json"
  DEVSETUP_CONFIG_LOCATION="$test_dir/test1.json"
  result="$(parse_config ".test")"
  run_test "Basic JSON parsing" "value" "$result"

  # Test 2: Formatted JSON with spaces and newlines
  cat >"$test_dir/test2.json" <<'EOF'
{
  "test": "value with spaces",
  "nested": {
    "key": "nested value"
  }
}
EOF
  DEVSETUP_CONFIG_LOCATION="$test_dir/test2.json"
  result="$(parse_config ".test")"
  run_test "Formatted JSON with spaces" "value with spaces" "$result"

  # Test 3: Nested object access
  result="$(parse_config ".nested.key")"
  run_test "Nested object access" "nested value" "$result"

  # Test 4: Array access
  cat >"$test_dir/test3.json" <<'EOF'
{
  "array": [
    "first",
    "second",
    "third with spaces"
  ]
}
EOF
  DEVSETUP_CONFIG_LOCATION="$test_dir/test3.json"
  result="$(parse_config ".array.0")"
  run_test "Array access (first element)" "first" "$result"

  # Test 5: Array access with spaces in value
  result="$(parse_config ".array.2")"
  run_test "Array access with spaces in value" "third with spaces" "$result"

  # Test 6: Complex nested structure
  cat >"$test_dir/test4.json" <<'EOF'
{
  "complex": {
    "nested": [
      {
        "key": "value with spaces and \"quotes\""
      }
    ]
  }
}
EOF
  DEVSETUP_CONFIG_LOCATION="$test_dir/test4.json"
  result="$(parse_config ".complex.nested.0.key")"
  run_test "Complex nested structure with quotes" 'value with spaces and \"quotes\"' "$result"

  # Test 7: Empty values
  cat >"$test_dir/test5.json" <<'EOF'
{
  "empty": "",
  "space": " ",
  "null": null
}
EOF
  DEVSETUP_CONFIG_LOCATION="$test_dir/test5.json"
  result="$(parse_config ".empty")"
  run_test "Empty string" "" "$result"

  # Test 8: String with just a space
  result="$(parse_config ".space")"
  run_test "String with just a space" " " "$result"

  # Test 9: Test with real config format
  cat >"$test_dir/test6.json" <<'EOF'
{
  "commands": {
    "nodejs": {
      "install": "npm install -g {tool}{version: \"@{version}\"}"
    }
  },
  "tools": {
    "nodejs": [
      "typescript",
      {
        "tool": "vscode-langservers-extracted",
        "version": 4.8
      }
    ]
  }
}
EOF
  DEVSETUP_CONFIG_LOCATION="$test_dir/test6.json"
  result="$(parse_config ".tools.nodejs.1.tool")"
  run_test "Real config format" "vscode-langservers-extracted" "$result"

  # Test 10: Heavily formatted JSON with lots of whitespace
  cat >"$test_dir/test7.json" <<'EOF'
{
    "deeply": {
        "nested": {
            "object": {
                "with": {
                    "lots": {
                        "of": {
                            "levels": "and spaces"
                        }
                    }
                }
            }
        }
    },
    "array_with_spaces": [
        "item 1",
        "  item with leading spaces  ",
        "item with \"quotes\" inside"
    ]
}
EOF
  DEVSETUP_CONFIG_LOCATION="$test_dir/test7.json"
  result="$(parse_config ".deeply.nested.object.with.lots.of.levels")"
  run_test "Deeply nested object with lots of whitespace" "and spaces" "$result"

  result="$(parse_config ".array_with_spaces.1")"
  run_test "Array item with preserved leading/trailing spaces" "  item with leading spaces  " "$result"

  echo "All parse_config tests completed"
}

# Run the tests
test_parse_config

# Clean up test files
rm -rf "$test_dir"

echo "All tests completed"
