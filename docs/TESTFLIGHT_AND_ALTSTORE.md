# App Code distribution setup

## Unsigned IPA for AltStore/SideStore

Use **Actions -> Unsigned IPA -> Run workflow**. The workflow builds `AppCode-unsigned.ipa` with code signing disabled. AltStore/SideStore users sign that IPA locally with their own Apple developer credentials.

The workflow caches:

- downloaded runtime/framework resources in `Resources`
- SwiftPM cache
- Xcode DerivedData

## TestFlight prep

Use **Actions -> TestFlight Prep -> Run workflow** after setting repository secrets.

Required default identifiers:

- app bundle ID: `com.nightvibes.appcode`
- extension bundle ID: `com.nightvibes.appcode.extension`
- app group: `group.com.nightvibes.appcode`
- iCloud KVS: `$(TeamIdentifierPrefix)com.nightvibes.appcode`

Required secrets:

- `APP_STORE_CONNECT_TEAM_ID`
- `DEVELOPER_APP_ID`
- `DEVELOPER_APP_IDENTIFIER`
- `DEVELOPER_APP_EXTENSION_IDENTIFIER`
- `DEVELOPER_PORTAL_TEAM_ID`
- `FASTLANE_APPLE_ID`
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`
- `MATCH_PASSWORD`
- `MATCH_GIT_URL` if not using `https://github.com/NightVibes33/app-code-certificates`
- `GIT_AUTHORIZATION`
- `TEMP_KEYCHAIN_PASSWORD`
- `TEMP_KEYCHAIN_USER`
- `APPLE_KEY_ID`
- `APPLE_ISSUER_ID`
- `APPLE_KEY_CONTENT`

The app target uses the existing Xcode scheme `Code App`; the user-facing display name is `App Code`.
