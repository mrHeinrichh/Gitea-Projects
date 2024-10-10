#!/bin/bash

echo 'Clean language script'

# Step 1: Define the project root and lib directory
PROJECT_ROOT=$(dirname "$(dirname "$(realpath "$0")")")
LIB_DIR="$PROJECT_ROOT/lib"
UTILS_DIR="$LIB_DIR/utils"
ASSETS_LANG_DIR="$PROJECT_ROOT/assets/lang"

# Step 2: Extract language keys from lang_util.dart files
declare -A availableLangKeys

for file in $(find "$UTILS_DIR" -name "lang_util.dart"); do
  while IFS= read -r line; do
    if [[ $line =~ const\ ([a-zA-Z0-9_]+)\ =\ \"(.*)\" ]]; then
      availableLangKeys[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
    elif [[ $line =~ const\ ([a-zA-Z0-9_]+)\ =\ \'(.*)\' ]]; then
      availableLangKeys[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
    fi
  done < "$file"
done

if [ ${#availableLangKeys[@]} -eq 0 ]; then
  echo 'No available language keys found in the project.'
  exit 1
fi

# Step 3: Go through every .dart file in the lib directory
declare -A localizedKeys

for file in $(find "$LIB_DIR" -name "*.dart"); do
  if [[ $file == *"lang_util"* ]]; then
    continue
  fi

  while IFS= read -r line; do
    for key in "${!availableLangKeys[@]}"; do
      if [[ $line == *"$key"* ]]; then
        localizedKeys[$key]=1
      fi
    done
  done < "$file"
done

echo 'Mapping done.'

if [ ${#localizedKeys[@]} -eq 0 ]; then
  echo 'No localized keys found in the project.'
  exit 1
fi

# Step 4: Make a copy of availableLangKeys that exist in localizedKeys
declare -A usedLangKeys

for key in "${!localizedKeys[@]}"; do
  if [ -n "${availableLangKeys[$key]}" ]; then
    usedLangKeys[$key]=${availableLangKeys[$key]}
  fi
done

echo "Length Diff after matching: ${#usedLangKeys[@]} | ${#availableLangKeys[@]}"

# Step 5: Write the used keys to a new file
USED_KEY_FILE="used_key.dart"
> "$USED_KEY_FILE"

for key in "${!usedLangKeys[@]}"; do
  echo "const $key = ${usedLangKeys[$key]};" >> "$USED_KEY_FILE"
done

# Step 6: Process JSON language files in assets/lang
for file in $(find "$ASSETS_LANG_DIR" -name "*.json"); do
  usedLangMaps=$(mktemp)
  # shellcheck disable=SC2068
  jq -r --argjson keys "$(echo ${!usedLangKeys[@]} | jq -R 'split(" ")')" '
    . as $data | $keys | map(select($data[.])) |
    map({"key": ., "value": $data[.]}) | from_entries' "$file" > "$usedLangMaps"

  if [ ! -s "$usedLangMaps" ]; then
    echo "No used language keys found in this file: $(basename "$file")"
    rm "$usedLangMaps"
    continue
  fi

  mv "$usedLangMaps" "$(basename "$file")"
done
