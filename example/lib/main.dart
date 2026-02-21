import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';

final keycloakWrapper = KeycloakWrapper();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the plugin at the start of your app.
  keycloakWrapper.initialize(
    config: KeycloakConfig(
      bundleIdentifier: 'com.example.demo',
      clientId: 'myclient',
      frontendUrl: Platform.isIOS
          ? 'http://localhost:8080'
          : 'http://10.0.2.2:8080',
      realm: 'myrealm',
    ),
  );
  // Listen to the errors caught by the plugin.
  if (kReleaseMode) {
    keycloakWrapper.onError = (message, _, _) {
      // Display the error message inside a snackbar.
      scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    };
  }
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
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var isLoading = false;

  // Login using the given configuration.
  Future<void> login() async {
    setState(() => isLoading = true);
    // Check if user has successfully logged in.
    final isLoggedIn = await keycloakWrapper.login();

    if (isLoggedIn) debugPrint('User has successfully logged in.');
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => isLoading
      ? LoadingScreen()
      : Scaffold(
          body: Center(
            child: FilledButton(onPressed: login, child: const Text('Login')),
          ),
        );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var isLoading = false;

  // Logout from the current realm.
  Future<void> logout() async {
    setState(() => isLoading = true);
    // Check if user has successfully logged out.
    final isLoggedOut = await keycloakWrapper.logout();

    if (isLoggedOut) debugPrint('User has successfully logged out.');
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => isLoading
      ? LoadingScreen()
      : Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder(
                  // Retrieve the user information.
                  future: keycloakWrapper.getUserInfo(),
                  builder: (context, snapshot) {
                    final userInfo = snapshot.data ?? {};

                    // Display the retrieved user information.
                    return Column(
                      children: [
                        ...userInfo.entries.map(
                          (n) => Text('${n.key}: ${n.value}'),
                        ),
                        if (userInfo.isNotEmpty) const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
                FilledButton(onPressed: logout, child: const Text('Logout')),
              ],
            ),
          ),
        );
}
