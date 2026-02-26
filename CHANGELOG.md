# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-02-26

### Added
- Add `externalUserAgent` parameter to `KeycloakConfig` for iOS/macOS authentication customization (#74).
- Support for `ExternalUserAgent` enum with three options:
  - `asWebAuthenticationSession` (default): Uses ASWebAuthenticationSession APIs.
  - `ephemeralAsWebAuthenticationSession`: Uses ephemeral sessions for enhanced privacy.
  - `sfSafariViewController`: Uses SFSafariViewController to avoid system prompts during logout.
- Add `docker-compose.yaml` file to run Keycloak container.

### Fixed
- Handle "token_failed" error by automatically logging the user out if the session is killed on the server (#57).
- Disallow multiple concurrent call operations (#72).

### Changed
- BREAKING: Configuration is now a required parameter to the `initialize` method. Refer to the example for the changes.
- The `getUserInfo` method will return the cached user information if the request fails or is offline (#41).

### Removed
- Deprecated `updateToken` method.
- All test files since users must log in via the webview which is untestable.