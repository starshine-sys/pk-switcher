import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pluralkit.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({Key? key, required this.prefs}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showImages;
  late bool _showHidden;
  late String _token;

  var _validToken = true;
  var _hasChangedSettings = false;

  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showImages = widget.prefs.getBool('showImages') ?? true;
    _showHidden = widget.prefs.getBool('showHidden') ?? true;
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _showImages,
            onChanged: (value) async {
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
            onChanged: (value) async {
              await widget.prefs.setBool('showHidden', value);
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
          TextField(
            decoration: const InputDecoration(
              labelText: 'Token',
              icon: Icon(Icons.password),
            ),
            controller: _tokenController,
            onSubmitted: (token) async => _onTokenSubmit(context, token),
          ),
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

    setState(() => _hasChangedSettings = false);

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
}
