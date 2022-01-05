import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pluralkit.dart';

class MemberList extends StatefulWidget {
  final SharedPreferences prefs;

  const MemberList({
    Key? key,
    required this.prefs,
  }) : super(key: key);

  @override
  _MemberListState createState() => _MemberListState();
}

class _MemberListState extends State<MemberList> {
  late Future<List<Member>?> _future;
  final _toSwitchIn = <Member>{};

  @override
  void initState() {
    super.initState();
    _future = getMembers(widget.prefs.getString('token')!);
  }

  Widget _buildList(List<Member> list) {
    if (list.isEmpty) {
      return ListView(
        children: const [
          ListTile(
            title: Text('No members registered.'),
          )
        ],
      );
    }

    final showHidden = widget.prefs.getBool('showHidden') ?? true;
    final showImages = widget.prefs.getBool('showImages') ?? true;

    list.sort((a, b) => a.name.compareTo(b.name));

    final tiles = <Widget>[];
    for (final member in list) {
      if (member.privacy?.visibility == 'private') {
        if (!showHidden) continue;
      }

      tiles.add(member.buildMemberCard(
        showImage: showImages,
        inList: _toSwitchIn.contains(member),
        tapAction: () {
          setState(() {
            if (_toSwitchIn.contains(member)) {
              _toSwitchIn.remove(member);
            } else {
              _toSwitchIn.add(member);
            }
          });
        },
      ));
    }

    return ListView(
      children: tiles,
    );
  }

  Future<bool?> _showConfirmButton(BuildContext context) async {
    return showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        var title = _toSwitchIn.isEmpty
            ? 'Switch out?'
            : 'Switch ${_toSwitchIn.length} member';
        if (_toSwitchIn.length == 1) {
          title = '$title in?';
        } else if (_toSwitchIn.length > 1) {
          title = '${title}s in?';
        }

        String content;
        switch (_toSwitchIn.length) {
          case 0:
            content = 'Are you sure you want to switch out?';
            break;
          case 1:
            content =
                'Are you sure you want to switch ${_toSwitchIn.first.name} in?';
            break;
          default:
            content =
                'Are you sure you want to switch the following members in?\n' +
                    _toSwitchIn.map((m) => m.name).join(', ');
            break;
        }

        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: _toSwitchIn.isEmpty
                  ? const Text('Switch out')
                  : const Text('Switch in'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _doSwitch(BuildContext context) async {
    await createSwitch(widget.prefs.getString('token')!,
        _toSwitchIn.map((m) => m.uuid).toList());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully registered switch!')),
    );

    setState(_toSwitchIn.clear);
  }

  @override
  Widget build(BuildContext context) {
    final button = (_toSwitchIn.isNotEmpty)
        ? Wrap(
            direction: Axis.horizontal,
            spacing: 8,
            children: [
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _toSwitchIn.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deselected all members')),
                    );
                  });
                },
                child: const Icon(Icons.restore),
                tooltip: 'Deselect all',
                backgroundColor: Colors.red,
                mini: true,
              ),
              FloatingActionButton(
                onPressed: () async {
                  final doSwitch = await _showConfirmButton(context);
                  if (doSwitch != null && doSwitch) {
                    await _doSwitch(context);
                  }
                },
                child: const Icon(Icons.save),
                tooltip: 'Register switch',
                backgroundColor: Colors.green,
              ),
            ],
          )
        : FloatingActionButton.extended(
            onPressed: () async {
              final doSwitch = await _showConfirmButton(context);
              if (doSwitch != null && doSwitch) {
                await _doSwitch(context);
              }
            },
            label: const Text('Switch out'),
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.exit_to_app),
          );

    return Scaffold(
      floatingActionButton: button,
      body: FutureBuilder<List<Member>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildList(snapshot.data!);
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // if we have no data but future is done, show a user-friendly message
          if (snapshot.connectionState == ConnectionState.done) {
            return const Center(
              child: Text(
                'No data was returned, please double check your token.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
