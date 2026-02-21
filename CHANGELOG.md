# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Add `externalUserAgent` parameter to `KeycloakConfig` for iOS/macOS authentication customization.
- Support for `ExternalUserAgent` enum with three options:
  - `asWebAuthenticationSession` (default): Uses ASWebAuthenticationSession APIs.
  - `ephemeralAsWebAuthenticationSession`: Uses ephemeral sessions for enhanced privacy.
  - `sfSafariViewController`: Uses SFSafariViewController to avoid system prompts during logout.