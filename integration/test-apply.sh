#!/bin/bash
set -euo pipefail
source_checkout=${1:?Pass the unpatched Omarchy source checkout}
integration_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_checkout=$(mktemp -d -t drawer-extension-test.XXXXXX)
trap 'rm -rf -- "$test_checkout"' EXIT
files=(shell/plugins/bar/Bar.qml shell/Ui/PluginBarApi.qml shell/Ui/KeyboardPanel.qml shell/Ui/PopupCard.qml)
for file in "${files[@]}"; do
  mkdir -p -- "$test_checkout/$(dirname -- "$file")"
  cp -- "$source_checkout/$file" "$test_checkout/$file"
done
cp -- "$source_checkout/shell/plugins/bar/BarModel.js" "$test_checkout/shell/plugins/bar/BarModel.js"
git -C "$test_checkout" init -q
git -C "$test_checkout" add -- shell
git -C "$test_checkout" -c user.name=Test -c user.email=test@example.invalid commit -qm baseline
"$integration_dir/../scripts/apply-host-extension" "$test_checkout"
"$integration_dir/../scripts/apply-host-extension" "$test_checkout"
node "$integration_dir/host-contract.test.cjs" "$test_checkout"
git -C "$test_checkout" apply --reverse "$integration_dir/stock-bar-drawer.patch"
printf '\n// Existing user change\n' >> "$test_checkout/shell/Ui/PluginBarApi.qml"
expected=$(sha256sum "$test_checkout/shell/Ui/PluginBarApi.qml")
if "$integration_dir/../scripts/apply-host-extension" "$test_checkout"; then
  echo "Expected dirty-file refusal" >&2
  exit 1
fi
[[ $(sha256sum "$test_checkout/shell/Ui/PluginBarApi.qml") == "$expected" ]]
echo "Patch application, idempotence, reverse and dirty-file preservation passed."
