#!/bin/sh
set -eu

RESOURCE_PATHS="
Resources/NodeJS/NodeMobile.xcframework
Resources/cpython
Resources/Java/java-frameworks
Resources/NMSSH.xcframework
Resources/Term/openssl.xcframework
Resources/Term/libssh2.xcframework
Resources/Term/ssh_cmd.xcframework
Resources/python-lsp
Resources/java-lsp
Resources/monaco-textmate.bundle
"

needs_download=0
for path in $RESOURCE_PATHS; do
  if [ ! -e "$path" ]; then
    needs_download=1
  fi
done

if [ "$needs_download" -eq 1 ]; then
  echo "Resources missing; downloading framework/runtime bundles"
  ./downloadFrameworks.sh
else
  echo "Resources cache hit; framework/runtime bundles already present"
fi

for path in $RESOURCE_PATHS; do
  test -e "$path" || { echo "Missing required resource: $path" >&2; exit 1; }
done
