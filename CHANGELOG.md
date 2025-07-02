# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.6] - 2025/7/2

- Update dependencies to the latest version.
- Automate publishing using the official workflow provided by Dart team.
- Rename `updateToken` method to `exchangeTokens` method.

## [1.4.4] - 2024/11/12

- Change `hasRunbefore` key value to avoid similar values.
- Update README.md to include token explanation.
- Bump `flutter_appauth` from 7.0.1 to 8.0.0+1.

## [1.4.3] - 2024/10/14

- Update dependencies.
- Update default scopes value.

## [1.4.1] - 2024/9/4

- Clear secure storage during each reinstallation. [#42](https://github.com/fa-fifi/keycloak_wrapper/issues/42)
- Change example app package name.

## [1.4.0] - 2024/8/22

- Unawait `updateToken` during initialization.
- Create a fully working example app.
- Remove deprecated `jwtDecode` method.

## [1.3.0] - 2024/7/16

- Create `JWT` class to manage JSON web token.
- Refresh token using `updateToken` method.
- Configure additional scopes.

## [1.2.2] - 2024/6/22

- Update dependencies.
- Update CI/CD pipelines.

## [1.1.2] - 2024/4/1

- Rename repository.

## [1.1.1] - 2024/3/20

- Update the default error message.
- Make `isInitialized` variable as private.

## [1.1.0] - 2024/3/04

- Ensure the validity of `bundleIdentifier` value. #29
- Remove `redirectUrl` parameter from `KeycloakLogin` constructor.
- Update readme.md.

## [1.0.3] - 2024/2/26

- Configure your own custom `redirectUrl` instead of using `bundleIdentifier` value.
- Update default onError function.

## [1.0.2] - 2024/2/23

- Apply stricter linter rules.
- Update dependencies.

## [1.0.1] - 2024/2/21

- Assert the initialization method to be called first.
- Deprecate `getWithBearerAuthentication()` function.
- Add a new badge inside README.md.

## [1.0.0] - 2023/12/22

- Initial stable release of this package.
- Add contribution guidelines.
- Improve automated publishing workflow.