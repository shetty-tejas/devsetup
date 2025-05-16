#!/bin/sh

# Create test directory if it doesn't exist
test_dir="/tmp/devsetup_tests"
mkdir -p "$test_dir"

# Source the main script with a modified environment to avoid actual config loading
DEVSETUP_CONFIG_FOLDER="$test_dir"

# Now source the main script
. "$(dirname "$0")/devsetup"

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
  echo '{"test": "value"}' >"$test_dir/devsetup.json"

  result="$(parse_config ".test")"
  run_test "Basic JSON parsing" "value" "$result"

  # Test 2: Formatted JSON with spaces and newlines
  cat >"$test_dir/devsetup.json" <<'EOF'
{
  "test": "value with spaces",
  "nested": {
    "key": "nested value"
  }
}
EOF

  result="$(parse_config ".test")"
  run_test "Formatted JSON with spaces" "value with spaces" "$result"

  # Test 3: Nested object access
  result="$(parse_config ".nested.key")"
  run_test "Nested object access" "nested value" "$result"

  # Test 4: Array access
  cat >"$test_dir/devsetup.json" <<'EOF'
{
  "array": [
    "first",
    "second",
    "third with spaces"
  ]
}
EOF

  result="$(parse_config ".array.0")"
  run_test "Array access (first element)" "first" "$result"

  # Test 5: Array access with spaces in value
  result="$(parse_config ".array.2")"
  run_test "Array access with spaces in value" "third with spaces" "$result"

  # Test 6: Complex nested structure
  cat >"$test_dir/devsetup.json" <<'EOF'
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
  result="$(parse_config ".complex.nested.0.key")"
  run_test "Complex nested structure with quotes" 'value with spaces and \"quotes\"' "$result"

  # Test 7: Empty values
  cat >"$test_dir/devsetup.json" <<'EOF'
{
  "empty": "",
  "space": " ",
  "null": null
}
EOF
  result="$(parse_config ".empty")"
  run_test "Empty string" "" "$result"

  # Test 8: String with just a space
  result="$(parse_config ".space")"
  run_test "String with just a space" " " "$result"

  # Test 9: Test with real config format
  cat >"$test_dir/devsetup.json" <<'EOF'
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
  result="$(parse_config ".tools.nodejs.1.tool")"
  run_test "Real config format" "vscode-langservers-extracted" "$result"

  # Test 10: Heavily formatted JSON with lots of whitespace
  cat >"$test_dir/devsetup.json" <<'EOF'
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
  result="$(parse_config ".deeply.nested.object.with.lots.of.levels")"
  run_test "Deeply nested object with lots of whitespace" "and spaces" "$result"

  result="$(parse_config ".array_with_spaces.1")"
  run_test "Array item with preserved leading/trailing spaces" "  item with leading spaces  " "$result"

  echo "All parse_config tests completed"
}

test_count_array_items() {
  echo "Running count_array_items tests..."

  # Test 1: Empty array
  result="$(count_array_items "[]")"
  run_test "Empty array count" "0" "$result"

  # Test 2: Simple array with strings
  result="$(count_array_items '["first", "second", "third"]')"
  run_test "Simple array count" "3" "$result"

  # Test 3: Array with mixed types
  result="$(count_array_items '[1, "string", true, null, {"key": "value"}]')"
  run_test "Mixed type array count" "5" "$result"

  # Test 4: Array with nested arrays
  result="$(count_array_items '[1, [2, 3], 4]')"
  run_test "Array with nested arrays count" "3" "$result"

  # Test 5: Array with objects containing commas
  result="$(count_array_items '[{"key1": "value1", "key2": "value2"}, {"key": "value,with,commas"}]')"
  run_test "Array with objects containing commas count" "2" "$result"

  # Test 6: Array with quoted strings containing commas
  result="$(count_array_items '["string,with,commas", "normal string"]')"
  run_test "Array with quoted strings containing commas count" "2" "$result"

  echo "All count_array_items tests completed"
}

test_get_object_keys() {
  echo "Running get_object_keys tests..."

  # Test 1: Empty object
  result="$(get_object_keys "{}")"
  run_test "Empty object keys" "" "$result"

  # Test 2: Simple object with one key
  result="$(get_object_keys '{"key": "value"}')"
  run_test "Single key object" "key" "$result"

  # Test 3: Object with multiple keys
  keys="$(get_object_keys '{"key1": "value1", "key2": "value2", "key3": "value3"}')"
  # We need to check if all keys are present, order might vary
  key1_found=$(echo "$keys" | grep -c "key1")
  key2_found=$(echo "$keys" | grep -c "key2")
  key3_found=$(echo "$keys" | grep -c "key3")
  total_keys=$(echo "$keys" | wc -l)

  if [ "$key1_found" -eq 1 ] && [ "$key2_found" -eq 1 ] && [ "$key3_found" -eq 1 ] && [ "$total_keys" -eq 3 ]; then
    run_test "Multiple keys object" "All keys found" "All keys found"
  else
    run_test "Multiple keys object" "All keys found" "Some keys missing: $keys"
  fi

  # Test 4: Object with nested objects
  keys="$(get_object_keys '{"key1": "value1", "nested": {"inner": "value"}}')"
  key1_found=$(echo "$keys" | grep -c "key1")
  nested_found=$(echo "$keys" | grep -c "nested")
  total_keys=$(echo "$keys" | wc -l)

  if [ "$key1_found" -eq 1 ] && [ "$nested_found" -eq 1 ] && [ "$total_keys" -eq 2 ]; then
    run_test "Object with nested objects" "All keys found" "All keys found"
  else
    run_test "Object with nested objects" "All keys found" "Some keys missing: $keys"
  fi

  # Test 5: Object with specific keys we care about (tool and version)
  keys="$(get_object_keys '{"tool": "value", "version": "1.0.0"}')"
  tool_found=$(echo "$keys" | grep -c "tool")
  version_found=$(echo "$keys" | grep -c "version")
  total_keys=$(echo "$keys" | wc -l)

  if [ "$tool_found" -eq 1 ] && [ "$version_found" -eq 1 ] && [ "$total_keys" -eq 2 ]; then
    run_test "Tool and version keys" "All keys found" "All keys found"
  else
    run_test "Tool and version keys" "All keys found" "Some keys missing: $keys"
  fi

  # Test 6: Object with more complex keys
  keys="$(get_object_keys '{"tool": "complex-tool", "version": "2.0", "flags": "--global"}')"
  tool_found=$(echo "$keys" | grep -c "tool")
  version_found=$(echo "$keys" | grep -c "version")
  flags_found=$(echo "$keys" | grep -c "flags")
  total_keys=$(echo "$keys" | wc -l)

  if [ "$tool_found" -eq 1 ] && [ "$version_found" -eq 1 ] && [ "$flags_found" -eq 1 ] && [ "$total_keys" -eq 3 ]; then
    run_test "Object with three keys" "All keys found" "All keys found"
  else
    run_test "Object with three keys" "All keys found" "Some keys missing: $keys"
    echo "Keys found: $keys"
  fi

  # Test 7: Specific object structure from the JSON example (.tools.nodejs.7)
  keys="$(get_object_keys '{"tool": "vscode-langservers-extracted", "version": "4.8"}')"
  tool_found=$(echo "$keys" | grep -c "tool")
  version_found=$(echo "$keys" | grep -c "version")
  total_keys=$(echo "$keys" | wc -l)

  if [ "$tool_found" -eq 1 ] && [ "$version_found" -eq 1 ] && [ "$total_keys" -eq 2 ]; then
    run_test "Real example tools.nodejs.7" "All keys found" "All keys found"
  else
    run_test "Real example tools.nodejs.7" "All keys found" "Some keys missing: $keys"
    echo "Keys found: $keys"
  fi

  echo "All get_object_keys tests completed"
}

# Simplified test for install_tools functionality
test_install_tools_mock() {
  echo "Running install_tools mock tests..."

  # Define test objects
  simple_tool="simple-tool"
  complex_tool_obj='{"tool": "complex-tool", "version": "1.2.3"}'
  extra_tool_obj='{"tool": "extra-tool", "version": "2.0", "flags": "--global"}'

  # Test get_object_keys directly with the objects
  echo "Testing simple tool: $simple_tool"

  echo "Testing complex tool object:"
  keys="$(get_object_keys "$complex_tool_obj")"
  echo "Keys found in complex tool: $keys"

  echo "Testing extra tool object:"
  keys="$(get_object_keys "$extra_tool_obj")"
  echo "Keys found in extra tool: $keys"

  # Verify key extraction works for specific cases
  complex_keys="$(get_object_keys "$complex_tool_obj")"
  tool_found=$(echo "$complex_keys" | grep -c "tool")
  version_found=$(echo "$complex_keys" | grep -c "version")

  if [ "$tool_found" -eq 1 ] && [ "$version_found" -eq 1 ]; then
    run_test "Complex tool object keys" "tool and version" "tool and version"
  else
    run_test "Complex tool object keys" "tool and version" "Not all keys found"
    echo "Keys found: $complex_keys"
  fi

  # Verify key extraction for extra tool
  extra_keys="$(get_object_keys "$extra_tool_obj")"
  tool_found=$(echo "$extra_keys" | grep -c "tool")
  version_found=$(echo "$extra_keys" | grep -c "version")
  flags_found=$(echo "$extra_keys" | grep -c "flags")

  if [ "$tool_found" -eq 1 ] && [ "$version_found" -eq 1 ] && [ "$flags_found" -eq 1 ]; then
    run_test "Extra tool object keys" "tool, version, and flags" "tool, version, and flags"
  else
    run_test "Extra tool object keys" "tool, version, and flags" "Not all keys found"
    echo "Keys found: $extra_keys"
  fi

  echo "All install_tools mock tests completed"
}

# Run the tests
test_parse_config
test_count_array_items
test_get_object_keys
test_install_tools_mock

# Clean up test files
rm -rf "$test_dir"

echo "All tests completed"
