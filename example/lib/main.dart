import 'package:flutter/material.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';

final keycloakConfig = KeycloakConfig(
  bundleIdentifier: 'com.example.demo',
  clientId: '<client_id>',
  frontendUrl: '<frontend_url>',
  realm: '<realm>',
);
final keycloakWrapper = KeycloakWrapper(config: keycloakConfig);
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the plugin at the start of your app.
  keycloakWrapper.initialize();
  // Listen to the errors caught by the plugin.
  keycloakWrapper.onError = (message, _, __) {
    // Display the error message inside a snackbar.
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        // Listen to the user authentication stream.
        home: StreamBuilder<bool>(
          initialData: false,
          stream: keycloakWrapper.authenticationStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            } else if (snapshot.data!) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      );
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Login using the given configuration.
  Future<bool> login() async {
    // Check if user has successfully logged in.
    final isLoggedIn = await keycloakWrapper.login();

    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(onPressed: login, child: const Text('Login')),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Logout from the current realm.
  Future<bool> logout() async {
    // Check if user has successfully logged out.
    final isLoggedOut = await keycloakWrapper.logout();

    return isLoggedOut;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder(
                // Retrieve the user information.
                future: keycloakWrapper.getUserInfo(),
                builder: (context, snapshot) {
                  final name = snapshot.data?['name'];

                  return Text('$name ${snapshot.data}');
                },
              ),
              TextButton(onPressed: logout, child: const Text('Logout')),
            ],
          ),
        ),
      );
}
