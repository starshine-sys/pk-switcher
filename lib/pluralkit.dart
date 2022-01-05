import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

part 'pluralkit.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Member {
  Member(this.id, this.uuid, this.name, this.displayName, this.color,
      this.avatarUrl, this.privacy);

  final String id;
  final String uuid;
  final String name;
  final String? displayName;
  final String? color;
  final String? avatarUrl;
  final MemberPrivacy? privacy;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  Map<String, dynamic> toJson() => _$MemberToJson(this);

  Widget buildMemberCard({
    bool showImage = true,
    bool inList = false,
    void Function()? tapAction,
  }) {
    final color = (this.color != null)
        ? colorFromString(this.color!)
        : const Color(0xFF000000);

    final List<Widget> cardChildren = [];
    if (showImage) {
      final image = (avatarUrl != null)
          ? CircleAvatar(
              radius: 40,
              foregroundColor: color,
              child: CachedNetworkImage(
                width: 180,
                height: 180,
                imageUrl: avatarUrl!,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, _) => const Icon(Icons.error),
              ),
            )
          : const Icon(Icons.hide_image, size: 80);

      cardChildren
          .add(Padding(padding: const EdgeInsets.all(10), child: image));
    }

    final List<Widget> columnEntries = [
      Text(name, style: const TextStyle(fontSize: 18.0)),
    ];

    if (displayName != null) columnEntries.add(Text(displayName!));

    cardChildren.add(Column(
      children: columnEntries,
      crossAxisAlignment: CrossAxisAlignment.start,
    ));

    if (inList) cardChildren.add(const Icon(Icons.star));

    Widget child = Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 6),
        ),
      ),
      child: showImage
          ? Row(children: cardChildren)
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: cardChildren),
            ),
    );

    if (tapAction != null) {
      child = InkWell(
        child: child,
        onTap: tapAction,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MemberPrivacy {
  MemberPrivacy(this.visibility);

  final String? visibility;

  factory MemberPrivacy.fromJson(Map<String, dynamic> json) =>
      _$MemberPrivacyFromJson(json);

  Map<String, dynamic> toJson() => _$MemberPrivacyToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Switch {
  Switch(this.id, this.timestamp, this.members);

  final String id;
  final DateTime timestamp;
  final List<String> members;

  factory Switch.fromJson(Map<String, dynamic> json) => _$SwitchFromJson(json);

  Map<String, dynamic> toJson() => _$SwitchToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Front {
  Front(this.id, this.timestamp, this.members);

  final String id;
  final DateTime timestamp;
  final List<Member> members;

  factory Front.fromJson(Map<String, dynamic> json) => _$FrontFromJson(json);

  Map<String, dynamic> toJson() => _$FrontToJson(this);
}

Future<List<Member>?> getMembers(String token) async {
  final resp = await http.get(
      Uri.parse("https://api.pluralkit.me/v2/systems/@me/members"),
      headers: {
        'Authorization': token,
      });

  if (resp.statusCode < 200 || resp.statusCode >= 400) {
    return null;
  }

  final body = jsonDecode(resp.body);

  return (body as List<dynamic>)
      .map((e) => Member.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<Front?> getFronters(String token) async {
  final resp = await http.get(
      Uri.parse("https://api.pluralkit.me/v2/systems/@me/fronters"),
      headers: {
        'Authorization': token,
      });

  if (resp.statusCode < 200 || resp.statusCode >= 400) {
    return null;
  }

  final body = jsonDecode(resp.body);

  return Front.fromJson(body);
}

Future<List<Switch>?> getLatestSwitches(String token) async {
  final resp = await http.get(
      Uri.parse("https://api.pluralkit.me/v2/systems/@me/switches"),
      headers: {
        'Authorization': token,
      });

  if (resp.statusCode < 200 || resp.statusCode >= 400) {
    return null;
  }

  final body = jsonDecode(resp.body);

  return (body as List<dynamic>)
      .map((e) => Switch.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<Front?> createSwitch(String token, List<String> members) async {
  final resp = await http.post(
    Uri.parse("https://api.pluralkit.me/v2/systems/@me/switches"),
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': token,
    },
    body: jsonEncode({
      'members': members,
    }),
  );

  if (resp.statusCode < 200 || resp.statusCode >= 400) {
    return null;
  }

  final body = jsonDecode(resp.body);
  return Front.fromJson(body);
}

// Flutter functions

Color colorFromString(String str) {
  final num = int.tryParse(str, radix: 16);
  if (num == null) {
    return const Color(0xFF000000);
  }

  return Color.fromARGB(0xFF, (num >> 16) & 255, (num >> 8) & 255, num & 255);
}
