// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pluralkit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => Member(
      json['id'] as String,
      json['uuid'] as String,
      json['name'] as String,
      json['display_name'] as String?,
      json['color'] as String?,
      json['avatar_url'] as String?,
      json['privacy'] == null
          ? null
          : MemberPrivacy.fromJson(json['privacy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'name': instance.name,
      'display_name': instance.displayName,
      'color': instance.color,
      'avatar_url': instance.avatarUrl,
      'privacy': instance.privacy,
    };

MemberPrivacy _$MemberPrivacyFromJson(Map<String, dynamic> json) =>
    MemberPrivacy(
      json['visibility'] as String?,
    );

Map<String, dynamic> _$MemberPrivacyToJson(MemberPrivacy instance) =>
    <String, dynamic>{
      'visibility': instance.visibility,
    };

Switch _$SwitchFromJson(Map<String, dynamic> json) => Switch(
      json['id'] as String,
      DateTime.parse(json['timestamp'] as String),
      (json['members'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SwitchToJson(Switch instance) => <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'members': instance.members,
    };

Front _$FrontFromJson(Map<String, dynamic> json) => Front(
      json['id'] as String,
      DateTime.parse(json['timestamp'] as String),
      (json['members'] as List<dynamic>)
          .map((e) => Member.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FrontToJson(Front instance) => <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'members': instance.members.map((e) => e.toJson()).toList(),
    };
