# App Code

App Code is a local-first iOS 26+ code editor and mobile development toolkit forked from the MIT-licensed Code App project. This fork focuses on reliability, iPhone/iPad polish, local runtimes, Git safety, and a Liquid Glass interface.

## Fork focus

- iOS 26+ only
- Liquid Glass shell surfaces
- local-only execution positioning; the upstream remote Judge0 panel is disabled
- safer Git pull/checkout behavior that blocks dirty working trees instead of overwriting user edits
- clearer source-control errors for stage/unstage actions
- SFTP directory deletion fix
- Copy Relative Path works from the workspace root when no editor is active
- cached GitHub Actions for faster unsigned IPA and TestFlight builds

## Build unsigned IPA

Run the **Unsigned IPA** GitHub Actions workflow. It builds for generic iOS devices with code signing disabled and uploads `AppCode-unsigned.ipa`, intended for AltStore/SideStore users to sign locally.

## TestFlight prep

Run the **TestFlight Prep** workflow after configuring these repository secrets:

- `APP_STORE_CONNECT_TEAM_ID`
- `DEVELOPER_APP_ID`
- `DEVELOPER_APP_IDENTIFIER`
- `DEVELOPER_APP_EXTENSION_IDENTIFIER`
- `DEVELOPER_PORTAL_TEAM_ID`
- `FASTLANE_APPLE_ID`
- `MATCH_PASSWORD`
- `GIT_AUTHORIZATION`
- `TEMP_KEYCHAIN_PASSWORD`
- `TEMP_KEYCHAIN_USER`
- `APPLE_KEY_ID`
- `APPLE_ISSUER_ID`
- `APPLE_KEY_CONTENT`

Default bundle IDs are `com.nightvibes.appcode` and `com.nightvibes.appcode.extension`.

## License

This fork keeps the upstream MIT license. See `LICENSE`. Privacy policy: https://nightvibes33.github.io/app-code-ios/privacy.html
