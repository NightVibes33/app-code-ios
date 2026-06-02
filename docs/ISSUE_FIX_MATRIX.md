# Recent upstream issues reviewed for App Code

Reviewed on 2026-06-02 from `thebaselab/codeapp` recent created/updated issues and comment threads.

## Fixes implemented in this fork

| Upstream issue | Signal | App Code change |
| --- | --- | --- |
| #1307 UI Pull overwrites modified files | Pull/merge could destroy local work | Pull now blocks when the working tree has local changes before integrating remote changes. Fast-forward and merge follow-up checkouts use safe checkout. |
| #1326 / #1308 / #1322 stage and commit actions fail or silently do nothing | Source-control plus/stage UI looked inert | Stage/unstage controls now surface synchronous errors instead of swallowing them; diff OID lookup checks both head-to-index and index-to-workdir status entries. |
| #1324 Cannot copy relative path | Folder relative path copying failed without active editor context | Copy Relative Path falls back to the workspace root and path-based relative computation. |
| #1323 SFTP directory delete says unable to perform | SFTP remove always called file deletion | SFTP deletion now checks remote attributes and calls directory deletion for directories. |
| #1278 Settings sync via iCloud | Remote hosts had to be re-created per device | Remote host list is mirrored through `NSUbiquitousKeyValueStore`; credentials remain local/keychain-backed. |
| #1279 iPadOS 26 UI modernization | Users asked for iPadOS 26 polish | Main shell surfaces now use an iOS 26 Liquid Glass helper and deployment target is iOS 26.0. |
| Local-only positioning | User requested no cloud runtime | Upstream Judge0 remote-execution extension is disabled and Fastlane writes empty Judge0 secrets. |
| #1297 forked builds missing resources | Forked builds missed Node/Java/WASM resources | CI now caches `Resources` and validates runtime/framework folders before building. |

## Reviewed but not fully fixed in this first pass

| Upstream issue | Reason |
| --- | --- |
| #1313 Node app not working | Needs macOS/Xcode device or CI artifact validation to reproduce runtime behavior. |
| #1287 Node fetch/WebAssembly error | Requires runtime-level NodeMobile/undici validation on device. |
| #1283 Java output/compiler instability | Requires Java runtime execution testing on iOS 26 hardware. |
| #1320 / #1289 TypeScript language server | Larger language-service feature, not a quick reliability patch. |
| #1280 multi-hop SSH | Larger SSH feature; not needed for first App Store-safe release. |
| #1305 / #1084 cross-file C++ direct run | Build-task UX feature; could be next paid-release differentiator. |
| #1292 replace and regex match | Editor feature request; useful next improvement. |

## First validation checklist

1. Run the Unsigned IPA workflow and install `AppCode-unsigned.ipa` through SideStore/AltStore.
2. Create a local Git repo, edit a file, and verify Pull is blocked while dirty.
3. Stage/unstage individual files and Stage All; verify errors show as banners.
4. Connect to SFTP and delete an empty remote folder.
5. Copy relative path from a folder with no active editor.
6. Run Python, JavaScript, C/C++, and Java hello-world files on a real device.
7. Archive through TestFlight Prep after configuring signing/App Store Connect secrets.
