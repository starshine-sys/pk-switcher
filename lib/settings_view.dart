import 'package:flutter/material.dart';
import 'package:pk_switcher/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pluralkit.dart';

const _repo = 'https://github.com/starshine-sys/pk-switcher/';
const _license =
    'https://github.com/starshine-sys/pk-switcher/blob/main/LICENSE';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({Key? key, required this.prefs}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showImages;
  late bool _showHidden;
  late bool _darkTheme;
  late String _token;

  var _validToken = true;
  var _hasChangedSettings = false;

  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showImages = widget.prefs.getBool('showImages') ?? true;
    _showHidden = widget.prefs.getBool('showHidden') ?? true;
    _darkTheme = widget.prefs.getBool('darkTheme') ?? false;
    _token = widget.prefs.getString('token')!;
    _tokenController.text = _token;
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _showImages,
            onChanged: (value) {
              setState(() {
                _hasChangedSettings = true;
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
            onChanged: (value) {
              setState(() {
                _hasChangedSettings = true;
                _showHidden = value;
              });
            },
            title: const Text('Show private members'),
            subtitle: const Text(
                "Whether to show private members in the full member list"),
          ),
          const Divider(),
          const Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                'Theme',
                style: TextStyle(fontSize: 16),
              )),
          RadioListTile<bool>(
            value: false,
            groupValue: _darkTheme,
            onChanged: (_) {
              setState(() {
                _hasChangedSettings = true;
                _darkTheme = false;
              });
            },
            title: const Text('Light'),
          ),
          RadioListTile<bool>(
            value: true,
            groupValue: _darkTheme,
            onChanged: (_) {
              setState(() {
                _hasChangedSettings = true;
                _darkTheme = true;
              });
            },
            title: const Text('Dark'),
          ),
          const Divider(),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Token',
              icon: Icon(Icons.password),
            ),
            controller: _tokenController,
            onSubmitted: (token) async => _onTokenSubmit(context, token),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            onTap: () => _aboutScreen(context),
            leading: const Icon(Icons.info),
          )
        ],
      ),
      floatingActionButton: (_hasChangedSettings && _validToken)
          ? FloatingActionButton(
              onPressed: () async => _onSave(context),
              backgroundColor: Colors.green,
              child: const Icon(Icons.save),
              tooltip: 'Save settings',
            )
          : null,
    );
  }

  Future<void> _onSave(BuildContext context) async {
    await widget.prefs.setBool('showHidden', _showHidden);
    await widget.prefs.setBool('showImages', _showImages);
    await widget.prefs.setString('token', _token);
    await widget.prefs.setBool('darkTheme', _darkTheme);

    setState(() => _hasChangedSettings = false);

    PKSwitcher.of(context)?.changeTheme(_darkTheme);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved settings!')),
    );
  }

  Future<void> _onTokenSubmit(BuildContext context, String token) async {
    final resp = await getFronters(token);
    if (resp == null) {
      _validToken = false;

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
    setState(() {
      _hasChangedSettings = true;
      _validToken = true;
      _token = token;
    });
  }

  void _aboutScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('About'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const ListTile(
                  title: Text('Version'),
                  subtitle: Text('0.4.0'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Repository'),
                  subtitle: const Text('github.com/starshine-sys/pk-switcher'),
                  onTap: () async => await launch(_repo),
                ),
                const Divider(),
                ListTile(
                  title: const Text('License'),
                  subtitle: const Text(
                      'GNU General Public License, version 3 or later'),
                  onTap: () async => await launch(_license),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
