import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_view.dart';
import 'member_view.dart';
import 'settings_view.dart';

import 'pluralkit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  runApp(PKSwitcher(prefs: prefs));
}

class PKSwitcher extends StatefulWidget {
  final SharedPreferences prefs;

  const PKSwitcher({Key? key, required this.prefs}) : super(key: key);

  static _PKSwitcherState? of(BuildContext context) =>
      context.findAncestorStateOfType<_PKSwitcherState>();

  @override
  _PKSwitcherState createState() => _PKSwitcherState();
}

class _PKSwitcherState extends State<PKSwitcher> {
  var _hadNoToken = false;
  var _darkTheme = false;

  void _exitWelcome() => setState(() {
        _hadNoToken = false;
      });

  void changeTheme(bool darkTheme) {
    setState(() {
      _darkTheme = darkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = widget.prefs.getString('token') != null;
    _darkTheme = widget.prefs.getBool('darkTheme') ?? false;

    Widget root = DefaultTabController(
      length: 4,
      initialIndex: hasToken ? 0 : 3,
      child: Scaffold(
        bottomNavigationBar: Container(
          color: _darkTheme ? Colors.black : Colors.white,
          child: TabBar(
            labelColor: _darkTheme ? Colors.white : Colors.black,
            indicatorColor: _darkTheme ? Colors.white : Colors.black,
            tabs: const [
              Tab(icon: Icon(Icons.account_circle), text: 'Fronters'),
              Tab(icon: Icon(Icons.list), text: 'Members'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text('PluralKit Switcher'),
        ),
        body: TabBarView(
          children: [
            CurrentFronterPage(prefs: widget.prefs),
            MemberList(prefs: widget.prefs),
            const Icon(Icons.history),
            SettingsScreen(prefs: widget.prefs),
          ],
        ),
      ),
    );

    // if no token is set, show welcome screen instead
    if (!hasToken || _hadNoToken) {
      _hadNoToken = true;

      root = WelcomeScreen(
        prefs: widget.prefs,
        exit: _exitWelcome,
      );
    }

    return MaterialApp(
        title: 'PluralKit Switcher',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.grey,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
        themeMode: _darkTheme ? ThemeMode.dark : ThemeMode.light,
        home: root);
  }
}

class WelcomeScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final void Function() exit;

  const WelcomeScreen({
    Key? key,
    required this.prefs,
    required this.exit,
  }) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  var _validToken = false;

  var _showImages = true;
  var _showHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PluralKit Switcher'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text('Set up'),
            subtitle: Text(
                'Get your system token with the "pk;token" command, then paste it here.'),
          ),
          const Divider(),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Token',
              icon: Icon(Icons.password),
            ),
            enabled: !_validToken,
            onSubmitted: (token) async => _onTokenSubmit(context, token),
          ),
          const Divider(),
          SwitchListTile(
            value: _showImages,
            onChanged: (value) async {
              await widget.prefs.setBool('showImages', value);
              setState(() {
                _showImages = value;
              });
            },
            title: const Text('Show member avatars'),
            subtitle: const Text(
                "Whether to show members' avatars in the member list"),
          ),
          const Divider(),
          SwitchListTile(
            value: _showHidden,
            onChanged: (value) async {
              await widget.prefs.setBool('showHidden', value);
              setState(() {
                _showHidden = value;
              });
            },
            title: const Text('Show private members'),
            subtitle: const Text(
                "Whether to show private members in the full member list"),
          ),
        ],
      ),
      floatingActionButton: _validToken
          ? FloatingActionButton(
              onPressed: widget.exit,
              backgroundColor: Colors.green,
              child: const Icon(Icons.save),
              tooltip: 'Save settings',
            )
          : null,
    );
  }

  Future<void> _onTokenSubmit(BuildContext context, String token) async {
    final resp = await getFronters(token);
    if (resp == null) {
      return await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid token'),
            content: const Text(
                "The token you provided doesn't seem to be valid. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    // otherwise, token is valid
    await widget.prefs.setString('token', token);
    setState(() {
      _validToken = true;
    });
  }
}
