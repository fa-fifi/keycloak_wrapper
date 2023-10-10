# Keycloak Wrapper Plugin
[![pub package](https://img.shields.io/pub/v/keycloak_wrapper.svg)](https://pub.dartlang.org/packages/keycloak_wrapper)
[![likes](https://img.shields.io/pub/likes/keycloak_wrapper)](https://pub.dev/packages/keycloak_wrapper/score)
[![pub points](https://img.shields.io/pub/points/keycloak_wrapper)](https://pub.dev/packages/keycloak_wrapper/score)
[![popularity](https://img.shields.io/pub/popularity/keycloak_wrapper)](https://pub.dev/packages/keycloak_wrapper/score)

<br/><a href="https://www.keycloak.org"><img src="https://www.keycloak.org/resources/images/keycloak_logo_200px.svg" width="100%" alt="cover image" url="https://www.keycloak.org"/></a><br/>

Integrate **Keycloak Single Sign-On (SSO)** authentication into your Flutter apps seamlessly using this plugin. Tokens are automatically managed under the hood, and if necessary, you can easily access them without writing any extra code. A user authentication state stream is also provided for the app to listen to in order to stay in sync with authentication status changes.

## 👟 Getting Started

For end-user authentication and authorization, this plugin will integrate with the [**AppAuth**](https://appauth.io) SDKs to establish connections with OAuth 2.0 and OpenID Connect. This integration allows users to securely log in and access protected resources, such as APIs or user data from third-party providers.  Additionally, for token security, the [**flutter_secure_storage**](https://pub.dev/packages/flutter_secure_storage) package will be implemented to securely store all the tokens within the Keychain for iOS and Keystore for Android.

- [**AndroidX**](https://developer.android.com/jetpack/androidx) is required for this package. Starting from Flutter v1.12.13, newly created projects already enable AndroidX by default. In case your project was created prior to this Flutter version, please migrate it before using this package. You can follow this migration [guide](https://docs.flutter.dev/release/breaking-changes/androidx-migration) provided by the Flutter team.

## 🕹️ Platform Configuration
Below are the configurations for each supported platform.

### Android Setup
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

Currently, this plugin sets the Keycloak issuer URL to use cleartext HTTP traffic. To avoid any network error issues when using this plugin, it is a good practice to enable the `android:usesCleartextTraffic` attribute under the `<application>` tag inside your `AndroidManifest.xml` file. This setup might be removed in the future once we find a better solution.

```xml
<manifest ...>
    <application
        ...
        android:usesCleartextTraffic="true">
        ...
    </application>
</manifest>
```

### iOS/macOS Setup
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

## 🚀 Plugin Usage
Create an instance of the plugin somewhere inside your code, like below.

```dart
final keycloakWrapper = KeycloakWrapper();
```

Initialize the plugin within the `main()` method of your Flutter app to set up the user authentication stream as soon as your app launches.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await keycloakWrapper.initialize();
  ...
  runApp(const MyApp());
}
```

To listen to the user authentication stream, you can create a StreamBuilder widget that listens to the `keycloakWrapper.authenticationStream` and navigates the user to the login screen when the stream returns false and redirects the user to the home screen when the login is successful. Set the initial value of the StreamBuilder widget to `false` to make sure the stream will never return null.

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

Afterwards, create a button somewhere inside your login screen and use the following method to initiate the login process. Make sure to replace all the placeholders with your own values.

```dart
Future<void> login() {
    final config = KeycloakConfig(
        bundleIdentifier: '<bundle_identifier>',
        clientId: '<client_id>',
        domain: '<domain>',
        realm: '<realm>');

    return keycloakWrapper.login(config);
  }
```

For logout, just this simple method will do.

```dart
Future<void> logout() {
    return keycloakWrapper.logout();
  }
```

By default, all errors and exceptions are handled by the `onError` method of the `KeycloakWrapper` class, which prints the error directly inside the console. You can customize this behavior if you want to display a custom message to users when specific errors, such as authorization failures, occur. Below is an example of how you can override the method and handle errors and exceptions in your own way.

```dart
keycloakWrapper.onError = (e, s) {
    debugPrint('Error: $e');
};
```

You can refer to the [example](https://pub.dev/packages/keycloak_wrapper/example) to see how this plugin works inside a real-life app.