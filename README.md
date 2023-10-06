🚧 Readme.md is under maintenance. 🚧

# Keycloak Wrapper
[![pub package](https://img.shields.io/pub/v/keycloak_wrapper.svg)](https://pub.dartlang.org/packages/keycloak_wrapper)

<br/><a href="https://www.keycloak.org"><img src="https://github.com/fa-fifi/keycloak-wrapper/raw/master/assets/keycloak.png" alt="cover image" url="https://www.keycloak.org"/></a><br/>

Integrate **Keycloak Single Sign-On (SSO)** authentication into your Flutter apps seamlessly using this package. Tokens are automatically managed in the background, and when needed, you can easily access them without writing any extra code. A user authentication state stream is also provided for the app to listen to in order to stay in sync with authentication status changes.

## 👟 Getting Started

<!-- For user authentication and authorization, this package is using AppAuth native SDKs to connect with OpenID and all tokens 

Using Appauth sdk to connect and secure storage to store tokens. -->

- **AndroidX** is required for this package. Starting from Flutter v1.12.13, newly created projects already enable AndroidX by default. In case your project was created prior to this Flutter version, please migrate it before using this package. You can follow this migration [guide](https://docs.flutter.dev/release/breaking-changes/androidx-migration) provided by the Flutter team.

## 🕹️ Platform Configuration
Below are the configurations for each supported platform.

### Android Setup
Go to the `build.gradle` file for your Android app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value.

```
...groovy
android {
    ...
    defaultConfig {
        ...
        manifestPlaceholders += [
                'appAuthRedirectScheme': '<your_custom_scheme>'
        ]
    }
}
```

Alternatively, the redirect URI can be directly configured by adding an
intent-filter for AppAuth's RedirectUriReceiverActivity to your
AndroidManifest.xml:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.my_app">
...
<activity
        android:name="net.openid.appauth.RedirectUriReceiverActivity"
        android:exported="true"
        tools:node="replace">
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="<your_custom_scheme>"
              android:host="<your_custom_host>"/>
    </intent-filter>
</activity>
...
```

Please ensure that value of `<your_custom_scheme>` is all in lowercase as there've been reports from the community who had issues with redirects if there were any capital letters. You may also notice the `+=` operation is applied on `manifestPlaceholders` instead of `=`. This is intentional and required as newer versions of the Flutter SDK has made some changes underneath the hood to deal with multidex. Using `=` instead of `+=` can lead to errors like the following.

```
Attribute application@name at AndroidManifest.xml:5:9-42 requires a placeholder substitution but no value for <applicationName> is provided.
```

If you see this error then update your `build.gradle` to use `+=` instead.

### iOS Setup
Go to the `Info.plist` for your iOS/macOS app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value.


```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string><your_custom_scheme></string>
        </array>
    </dict>
</array>
```

## 🚀 Usage
The first step is to create an instance of the keycloak wrapper class.

```
final keycloakWrapper = KeycloakWrapper();
```

<!-- 
Afterwards, you'll reach a point where end-users need to be authorized and authenticated. A convenience method is provided that will perform an authorization request and automatically exchange the authorization code. This can be done in a few different ways, one of which is to use the OpenID Connect Discovery

```dart
final AuthorizationTokenResponse result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      '<client_id>',
                      '<redirect_url>',
                      discoveryUrl: '<discovery_url>',
                      scopes: ['openid','profile', 'email', 'offline_access', 'api'],
                    ),
                  );
```

Here the `<client_id>` and `<redirect_url>` should be replaced by the values registered with your identity provider. The `<discovery_url>` would be the URL for the discovery endpoint exposed by your provider that will return a document containing information about the OAuth 2.0 endpoints among other things. This URL is obtained by concatenating the issuer with the path `/.well-known/openid-configuration`. For example, the full URL for the IdentityServer instance is `https://demo.duendesoftware.com/.well-known/openid-configuration`. As demonstrated in the above sample code, it's also possible specify the `scopes` being requested.

Rather than using the full discovery URL, the issuer could be used instead so that the process retrieving the discovery document is skipped

```dart
final AuthorizationTokenResponse result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      '<client_id>',
                      '<redirect_url>',
                      issuer: '<issuer>',
                      scopes: ['openid','profile', 'email', 'offline_access', 'api'],
                    ),
                  );
```

In the event that discovery isn't supported or that you already know the endpoints for your server, they could be explicitly specified

```dart
final AuthorizationTokenResponse result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      '<client_id>',
                      '<redirect_url>',
                      serviceConfiguration: AuthorizationServiceConfiguration(authorizationEndpoint: '<authorization_endpoint>',  tokenEndpoint: '<token_endpoint>', endSessionEndpoint: '<end_session_endpoint>'),
                      scopes: [...]
                    ),
                  );
```

Upon completing the request successfully, the method should return an object (the `result` variable in the above sample code is an instance of the `AuthorizationTokenResponse` class) that contain details that should be stored for future use e.g. access token, refresh token etc.

If you would prefer to not have the automatic code exchange to happen then can call the `authorize` method instead of the `authorizeAndExchangeCode` method. This will return an instance of the `AuthorizationResponse` class that will contain the nonce value and code verifier (note: code verifier is used as part of implement PKCE) that AppAuth generated when issuing the authorization request, the authorization code and additional parameters should they exist. The nonce, code verifier and authorization code would need to be stored so they can then be reused to exchange the code later on e.g.

```dart
final TokenResponse result = await appAuth.token(TokenRequest('<client_id>', '<redirect_url>',
        authorizationCode: '<authorization_code>',
        discoveryUrl: '<discovery_url>',
        codeVerifier: '<code_verifier>',
        nonce: 'nonce',
        scopes: ['openid','profile', 'email', 'offline_access', 'api']));
```

Reusing the nonce and code verifier is particularly important as the AppAuth SDKs (especially on Android) may return an error (e.g. ID token validation error due to nonce mismatch) if this isn't done -->

## 🔧 Troubleshooting
<!-- **When connecting to Azure B2C or Azure AD, the login request redirects properly on Android but not on iOS. What's going on?**

The AppAuth iOS SDK has some logic to validate the redirect URL to see if it should be responsible for processing the redirect. This appears to be failing under certain circumstances. Adding a trailing slash to the redirect URL specified in your code has been reported to fix the issue. -->

P.S. Feel free to report any encountered issues at the Github repository page. Pull requests are very welcome in order to improve this package. Any contribution towards the maintenance of this open-source project is very much appreciated.