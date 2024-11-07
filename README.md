# Keycloak Wrapper
[![pub package](https://img.shields.io/pub/v/keycloak_wrapper.svg)](https://pub.dartlang.org/packages/keycloak_wrapper)
[![likes](https://img.shields.io/pub/likes/keycloak_wrapper)](https://pub.dev/packages/keycloak_wrapper/score)
[![pub points](https://img.shields.io/pub/points/keycloak_wrapper)](https://pub.dev/packages/keycloak_wrapper/score)
[![popularity](https://img.shields.io/pub/popularity/keycloak_wrapper)](https://pub.dev/packages/keycloak_wrapper/score)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
[![StandWithPalestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/badges/StandWithPalestine.svg)](https://github.com/TheBSD/StandWithPalestine/blob/main/docs/README.md)

<br/><a href="https://www.keycloak.org"><img src="https://www.keycloak.org/resources/images/logo.svg" width="100%" alt="cover image" url="https://www.keycloak.org"/></a><br/>

Integrate **Keycloak Single Sign-On (SSO)** authentication into your Flutter apps seamlessly using this package. Tokens are automatically managed under the hood and are easily accessible. A user authentication state stream is also provided for the app to listen to in order to stay in sync with authentication status changes.

## Getting Started

For end-user authentication and authorization, this package integrates with the [**AppAuth**](https://appauth.io) SDK to establish connections using [**OAuth 2.0**](https://datatracker.ietf.org/doc/html/rfc6749) and [**OpenID Connect (OIDC)**](https://openid.net/specs/openid-connect-core-1_0.html). This integration allows users to securely log in and access protected resources, such as APIs or user data from third-party providers. Meanwhile, for token security, the [**flutter_secure_storage**](https://pub.dev/packages/flutter_secure_storage) package will be implemented to securely store all the tokens within the Keychain for iOS and Keystore for Android.

> [!NOTE]
> - [**AndroidX**](https://developer.android.com/jetpack/androidx) is required for this package. Starting from Flutter v1.12.13, newly created projects already enable AndroidX by default. In case your project was created prior to this Flutter version, please migrate it before using this package. You can follow this migration [guide](https://docs.flutter.dev/release/breaking-changes/androidx-migration) provided by the Flutter team.
>
> - Starting with Android API 28 and iOS 9, insecure HTTP connections are disabled by default. Check out this [guide](https://docs.flutter.dev/release/breaking-changes/network-policy-ios-android) if you want to allow cleartext connections for your build. However, it is not recommended to do this for your release build. Please use secure connections whenever possible.

### **Keycloak**
Head over to your **Keycloak Administration Console** and select your Client ID. Inside the access setting section, insert `<bundle_identifier>:/*` as a **valid redirect URI**, and do the same for the **valid post logout redirect URI**. Make sure your bundle identifier value does not contain any characters that are not allowed inside a hostname, such as spaces, underscores, etc.

### **Android**
Go to the `build.gradle` file for your Android app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<package_name>` with the desired value.

```groovy
android {
    ...
    defaultConfig {
        ...
        manifestPlaceholders += [
                'appAuthRedirectScheme': '<package_name>'
        ]
    }
}
```

Please ensure that value of `<package_name>` is all in lowercase as there've been reports from the community who had issues with redirects if there were any capital letters. You may also notice the `+=` operation is applied on `manifestPlaceholders` instead of `=`. This is intentional and required as newer versions of the Flutter SDK has made some changes underneath the hood to deal with multidex. Using `=` instead of `+=` can lead to errors like the following.

```
Attribute application@name at AndroidManifest.xml:5:9-42 requires a placeholder substitution but no value for <applicationName> is provided.
```

If you see this error then update your `build.gradle` to use `+=` instead.

> [!WARNING]
> - Starting from Flutter v3.22.0, newly created projects will disallow [task affinity](https://github.com/flutter/flutter/pull/144018) by default to prevent the [StrandHogg attack](https://developer.android.com/privacy-and-security/risks/strandhogg). However, these changes have broken the package, as users will no longer be able to redirect back to the app after login. Currently, the only way to fix this issue is to remove `android:taskAffinity=""` from your `AndroidManifest.xml` file.

### **iOS/macOS**
Go to the `Info.plist` for your iOS/macOS app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<bundle_identifier>` with the desired value.

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string><bundle_identifier></string>
        </array>
    </dict>
</array>
```

## Usage
Create an instance of `KeycloakWrapper` class somewhere inside your code, like below. Make sure to replace all the placeholders with your own configuration values.

```dart
final keycloakConfig = KeycloakConfig(
  bundleIdentifier: '<bundle_identifier>',
  clientId: '<client_id>',
  frontendUrl: '<frontend_url>',
  realm: '<realm>',
);

final keycloakWrapper = KeycloakWrapper(config: keycloakConfig);
```

Initialize the package within the `main()` method of your Flutter app to set up the user authentication stream as soon as your app launches.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  keycloakWrapper.initialize();
  ...
  runApp(const MyApp());
}
```

To listen to the user authentication state stream, create a StreamBuilder widget that listens to the `keycloakWrapper.authenticationStream` and navigates the user to the login screen when the stream returns false and redirects the user to the home screen when the login is successful. Set the initial value of the StreamBuilder widget to `false` to make sure the stream will never return null.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: StreamBuilder<bool>(
            initialData: false,
            stream: keycloakWrapper.authenticationStream,
            builder: (context, snapshot) =>
                snapshot.data! ? const HomeScreen() : const LoginScreen()),
      );
}
```

Afterwards, create a button somewhere inside your login screen and use the following method to initiate the login process.

```dart
Future<void> login() async {
  final isLoggedIn = await keycloakWrapper.login();
}
```

Once logged in, you'll be able to retrieve the user's information and tokens as shown below.

```dart
// Retrieve user's information.
final user = await keycloakWrapper.getUserInfo();

final name = user?['name'];
final email = user?['email'];

// Retrieve tokens.
final accessToken = keycloakWrapper.accessToken;
final idToken = keycloakWrapper.idToken;
final refreshToken = keycloakWrapper.refreshToken;
```

For logout, just this simple method will do. Make sure to pop off all stacked screens, if there are any.

```dart
Future<void> logout() async {
  final isLoggedOut = await keycloakWrapper.logout();
}
```

By default, all errors and exceptions are handled by the `onError` method of the `KeycloakWrapper` class, which prints the error directly inside the console. You can customize this behavior if you want to display a custom message to users when specific errors, such as authorization failures, occur. Below is an example of how you can override the method and handle errors and exceptions in your own way.

```dart
keycloakWrapper.onError = (message, error, stackTrace) {
    // Insert your logic here.
};
```

You can refer to the [example](https://pub.dev/packages/keycloak_wrapper/example) to see how this package works inside a real-life app.

## Contributing

Contributions are welcome! However, please make sure to follow the guidelines below to avoid unnecessary waste of time and resources.

- **Found a bug?**
<br> Ensure the bug was not already reported by searching on GitHub under [Issues](https://github.com/fa-fifi/keycloak_wrapper/issues). If you're unable to find an open issue addressing the problem, open a new one. Be sure to include a title and clear description, as much relevant information as possible, and a code sample or an executable test case demonstrating the expected behavior that is not occurring.

- **Need some help?**
<br> Feel free to open up a new [discussions](https://github.com/fa-fifi/keycloak_wrapper/discussions) on Github if you need any help from the community. I'll try my best to help you as soon as possible. If you want to make any feature requests, you can reach out using the same platform for us to discuss your idea further.

- **Want to contribute?**
<br> Since I am the only maintainer of this package, frequent bug fixes or updates might not be feasible. Therefore, any [pull requests](https://github.com/fa-fifi/keycloak_wrapper/pulls) are greatly appreciated! Please ensure that the PR description clearly outlines both the problem and its proposed solution. If applicable, include the relevant issue number in the description.

Thanks! ❤️