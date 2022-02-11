import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duration/duration.dart';
import 'package:intl/intl.dart';

import 'pluralkit.dart';

class CurrentFronterPage extends StatefulWidget {
  final SharedPreferences prefs;

  const CurrentFronterPage({Key? key, required this.prefs}) : super(key: key);

  @override
  _CurrentFronterPageState createState() => _CurrentFronterPageState();
}

class _CurrentFronterPageState extends State<CurrentFronterPage> {
  static final tsFormat = DateFormat.yMMMMEEEEd().add_jms();

  late Future<Front?> _future;
  var _oneFronter = false;

  Widget _buildFrontList(Front front) {
    final duration = DateTime.now().difference(front.timestamp);
    if (front.members.isEmpty) {
      return ListView(
        children: [
          const ListTile(
            contentPadding: EdgeInsets.only(top: 10),
            title: Center(
              child: Text(
                'No fronters registered.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            title: Center(
              child: Text(
                  'Since ${tsFormat.format(front.timestamp.toLocal())}\n(${prettyDuration(duration)} ago)'),
            ),
          ),
        ],
      );
    }

    final tiles = front.members.map((m) => m.buildMemberCard()).toList();
    tiles.add(
      ListTile(
        contentPadding: const EdgeInsets.only(bottom: 10),
        title: Center(
          child: Text(
              'Since ${tsFormat.format(front.timestamp.toLocal())}\n(${prettyDuration(duration)} ago)'),
        ),
      ),
    );

    return ListView(children: tiles);
  }

  @override
  void initState() {
    super.initState();
    _future = getFronters(widget.prefs.getString('token')!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current fronter${_oneFronter ? "" : "s"}'),
      ),
      body: FutureBuilder<Front?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildFrontList(snapshot.data!);
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
