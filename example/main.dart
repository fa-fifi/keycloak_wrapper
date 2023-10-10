import 'package:flutter/material.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';

final keycloakWrapper = KeycloakWrapper();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await keycloakWrapper.initialize();
  keycloakWrapper.onError = (e, s) {
    // Display the error inside a snackbar.
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$e')));
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
            builder: (context, snapshot) =>
                snapshot.data! ? const HomeScreen() : const LoginScreen()),
      );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Logs user in using given configuration.
  Future<void> login() {
    final config = KeycloakConfig(
        bundleIdentifier: '<bundle_identifier>',
        clientId: '<client_id>',
        domain: '<domain>',
        realm: '<realm>');

    return keycloakWrapper.login(config);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: TextButton(onPressed: login, child: const Text('Login'))),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Logs user out from current realm.
  Future<void> logout() {
    return keycloakWrapper.logout();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: TextButton(onPressed: logout, child: const Text('Logout'))),
      );
}
