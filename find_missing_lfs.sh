#!/usr/bin/env bash
set -e

echo "🔍 Checking for missing Git LFS objects..."
echo

# Ensure we’re in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not inside a Git repository."
  exit 1
fi

# Ensure Git LFS is available
if ! git lfs version >/dev/null 2>&1; then
  echo "❌ Git LFS is not installed or not configured."
  exit 1
fi

# Run LFS integrity check
missing=$(git lfs fsck 2>&1 | grep "missing object" || true)

if [ -z "$missing" ]; then
  echo "✅ No missing LFS objects found."
  exit 0
fi

echo "⚠️ Missing LFS objects detected:"
echo "$missing"
echo

# Extract hashes
hashes=$(echo "$missing" | awk '{print $3}')

for hash in $hashes; do
  echo "🔎 Searching for files related to LFS object: $hash"
  
  # Try to find the pointer file in LFS tracking
  file=$(git lfs ls-files | grep "$hash" | awk '{print $3}' || true)
  
  if [ -n "$file" ]; then
    echo "   ✅ Found file: $file"
  else
    # Try deeper grep in Git data
    file=$(git grep -l "$hash" || true)
    if [ -n "$file" ]; then
      echo "   ⚠️ Found possible file reference: $file"
    else
      echo "   ❌ Could not locate file for hash $hash"
    fi
  fi
  
  echo
done

echo "🧾 Next steps:"
echo "1️⃣  If any files were found above and you still have the originals → restore them to those paths."
echo "2️⃣  Then run:"
echo "      git add <file>"
echo "      git commit --amend --no-edit"
echo "      git push origin <your-branch> --force"
echo "      git lfs push origin <your-branch>"
echo
echo "3️⃣  If the files cannot be recovered → remove them and commit the deletion."
echo
echo "Done ✅"
