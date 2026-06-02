#!/bin/sh
set -eu

DERIVED_DATA_PATH="${1:-build/DerivedData}"
RUNESTONE_FILE="$DERIVED_DATA_PATH/SourcePackages/checkouts/Runestone/Sources/Runestone/TextView/SearchAndReplace/UITextSearchingHelper.swift"

if [ -f "$RUNESTONE_FILE" ]; then
  python3 - "$RUNESTONE_FILE" <<'PYINNER'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = """extension UITextSearchingHelper: UIFindInteractionDelegate {
    @available(iOS 16, *)
    func findInteraction(_ interaction: UIFindInteraction, sessionFor view: UIView) -> UIFindSession? {
"""
new = """@available(iOS 16, *)
extension UITextSearchingHelper: UIFindInteractionDelegate {
    func findInteraction(_ interaction: UIFindInteraction, sessionFor view: UIView) -> UIFindSession? {
"""
if old in text:
    path.write_text(text.replace(old, new, 1))
    print("Patched Runestone UIFindInteractionDelegate availability")
else:
    print("Runestone availability patch not needed")
PYINNER
fi
