import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duration/duration.dart';
import 'package:intl/intl.dart';

import 'pluralkit.dart' as pk;

class SwitchList extends StatefulWidget {
  final SharedPreferences prefs;

  const SwitchList({Key? key, required this.prefs}) : super(key: key);

  @override
  _SwitchListState createState() => _SwitchListState();
}

enum SwitchOptions { showInfo, delete, timestamp, members }

class _SwitchListState extends State<SwitchList> {
  static final tsFormat = DateFormat.yMMMMEEEEd().add_jms();

  late final String _token;

  late Future<List<pk.Member>?> _future;
  final _switches = <pk.Switch>[];

  @override
  void initState() {
    super.initState();
    _token = widget.prefs.getString('token')!;
    _future = pk.getMembers(_token);
  }

  Future<void> _switchMenu({
    required BuildContext context,
    required List<pk.Member> members,
    required pk.Switch pkSwitch,
    DateTime? nextSwitch,
  }) async {
    final option = await showModalBottomSheet<SwitchOptions>(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: ListView(
            children: [
              ListTile(
                title: const Text('Details'),
                leading: const Icon(Icons.info),
                onTap: () => Navigator.pop(context, SwitchOptions.showInfo),
              ),
              ListTile(
                title: const Text('Delete'),
                leading: const Icon(Icons.delete),
                onTap: () => Navigator.pop(context, SwitchOptions.delete),
              ),
            ],
          ),
        );
      },
    );

    switch (option) {
      case SwitchOptions.showInfo:
        _switchPage(context, members, pkSwitch, nextSwitch: nextSwitch);
        break;
      case SwitchOptions.delete:
        await _deleteSwitch(
          context: context,
          members: members,
          pkSwitch: pkSwitch,
        );
        break;
      default:
        break;
    }
  }

  Future<void> _deleteSwitch({
    required BuildContext context,
    required List<pk.Member> members,
    required pk.Switch pkSwitch,
  }) async {
    final resp = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete switch?'),
          content: const Text('Are you sure you want to delete this switch?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (resp != null && resp) {
      await pk.deleteSwitch(_token, pkSwitch.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully deleted switch!')),
      );

      setState(() {
        _switches.remove(pkSwitch);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch deletion cancelled')),
      );
    }
  }

  void _switchPage(
    BuildContext context,
    List<pk.Member> members,
    pk.Switch pkSwitch, {
    DateTime? nextSwitch,
  }) {
    final switchMembers = <pk.Member>[];
    for (final id in pkSwitch.members) {
      switchMembers.add(members.firstWhere((m) => m.id == id || m.uuid == id));
    }

    final children = switchMembers.map((m) => m.buildMemberCard()).toList();
    children.add(
      ListTile(
        title: Center(
          child: Text(tsFormat.format(pkSwitch.timestamp.toLocal())),
        ),
      ),
    );

    if (nextSwitch != null) {
      final duration = nextSwitch.difference(pkSwitch.timestamp);

      children.add(
        ListTile(
          contentPadding: const EdgeInsets.only(bottom: 10),
          title: Center(
            child: Text('For ${prettyDuration(duration)}'),
          ),
        ),
      );
    } else {
      final duration = DateTime.now().difference(pkSwitch.timestamp);

      children.add(
        ListTile(
          contentPadding: const EdgeInsets.only(bottom: 10),
          title: Center(
            child: Text('Since ${prettyDuration(duration)} ago'),
          ),
        ),
      );
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Switch'),
            ),
            body: ListView(
              children: children,
            ),
          );
        },
      ),
    );
  }

  Widget _switchCard({
    required BuildContext context,
    required List<pk.Member> members,
    required pk.Switch pkSwitch,
    DateTime? nextSwitch,
  }) {
    Color color;
    final memberNames = <String>[];

    if (pkSwitch.members.isEmpty) {
      memberNames.add('No fronter');
      color = const Color(0xFF000000);
    } else {
      final pkColor = members
          .firstWhere((m) =>
              m.id == pkSwitch.members.first ||
              m.uuid == pkSwitch.members.first)
          .color;
      color = (pkColor != null)
          ? pk.colorFromString(pkColor)
          : const Color(0xFF000000);
    }

    for (final id in pkSwitch.members) {
      memberNames
          .add(members.firstWhere((m) => m.id == id || m.uuid == id).name);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 6),
          ),
        ),
        child: InkWell(
          onTap: () => _switchPage(
            context,
            members,
            pkSwitch,
            nextSwitch: nextSwitch,
          ),
          onLongPress: () => _switchMenu(
            context: context,
            members: members,
            pkSwitch: pkSwitch,
            nextSwitch: nextSwitch,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberNames.join(', '),
                  style: const TextStyle(fontSize: 20),
                ),
                Text(tsFormat.format(pkSwitch.timestamp.toLocal())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _listView(BuildContext context, List<pk.Member> members) {
    return StreamBuilder<List<pk.Switch>>(
      stream: pk.getAllSwitches(_token),
      builder: (context, snapshot) {
        if (_switches.isEmpty && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          _switches.addAll(snapshot.data!);
        }

        if (_switches.isEmpty) {
          return ListView(
            children: const [
              ListTile(
                title: Text('No switches registered.'),
              )
            ],
          );
        }

        return ListView.builder(
          itemCount: _switches.length,
          itemBuilder: (context, index) {
            DateTime? nextSwitch;
            if (index != 0) {
              nextSwitch = _switches[index - 1].timestamp;
            }

            return _switchCard(
              context: context,
              members: members,
              pkSwitch: _switches[index],
              nextSwitch: nextSwitch,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switches'),
      ),
      body: FutureBuilder<List<pk.Member>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _listView(context, snapshot.data!);
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
