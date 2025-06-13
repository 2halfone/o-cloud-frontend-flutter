// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRContent _$QRContentFromJson(Map<String, dynamic> json) => QRContent(
      jwt: json['jwt'] as String,
      type: json['type'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$QRContentToJson(QRContent instance) => <String, dynamic>{
      'jwt': instance.jwt,
      'type': instance.type,
      'version': instance.version,
    };

AttendanceRequest _$AttendanceRequestFromJson(Map<String, dynamic> json) =>
    AttendanceRequest(
      qrContent: QRContent.fromJson(json['qr_content'] as Map<String, dynamic>),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$AttendanceRequestToJson(AttendanceRequest instance) =>
    <String, dynamic>{
      'qr_content': instance.qrContent,
      'reason': instance.reason,
    };

AttendanceResponse _$AttendanceResponseFromJson(Map<String, dynamic> json) =>
    AttendanceResponse(
      success: json['success'] as bool?,
      message: json['message'] as String,
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String,
      status: $enumDecode(_$AttendanceStatusEnumMap, json['status']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      validation: json['validation'] as String?,
      tableName: json['table_name'] as String?,
    );

Map<String, dynamic> _$AttendanceResponseToJson(AttendanceResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'event_id': instance.eventId,
      'event_name': instance.eventName,
      'status': _$AttendanceStatusEnumMap[instance.status]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'validation': instance.validation,
      'table_name': instance.tableName,
    };

const _$AttendanceStatusEnumMap = {
  AttendanceStatus.present: 'present',
  AttendanceStatus.hospital: 'hospital',
  AttendanceStatus.family: 'family',
  AttendanceStatus.emergency: 'emergency',
  AttendanceStatus.vacancy: 'vacancy',
  AttendanceStatus.personal: 'personal',
  AttendanceStatus.notRegistered: 'not_registered',
};

AttendanceHistoryItem _$AttendanceHistoryItemFromJson(
        Map<String, dynamic> json) =>
    AttendanceHistoryItem(
      id: (json['id'] as num).toInt(),
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String,
      status: $enumDecode(_$AttendanceStatusEnumMap, json['status']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$AttendanceHistoryItemToJson(
        AttendanceHistoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'event_name': instance.eventName,
      'status': _$AttendanceStatusEnumMap[instance.status]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'reason': instance.reason,
    };

AttendanceHistoryResponse _$AttendanceHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    AttendanceHistoryResponse(
      attendance: (json['attendance'] as List<dynamic>)
          .map((e) => AttendanceHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$AttendanceHistoryResponseToJson(
        AttendanceHistoryResponse instance) =>
    <String, dynamic>{
      'attendance': instance.attendance,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

TodayAttendance _$TodayAttendanceFromJson(Map<String, dynamic> json) =>
    TodayAttendance(
      id: (json['id'] as num).toInt(),
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String,
      status: $enumDecode(_$AttendanceStatusEnumMap, json['status']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$TodayAttendanceToJson(TodayAttendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'event_name': instance.eventName,
      'status': _$AttendanceStatusEnumMap[instance.status]!,
      'timestamp': instance.timestamp.toIso8601String(),
    };

TodayAttendanceResponse _$TodayAttendanceResponseFromJson(
        Map<String, dynamic> json) =>
    TodayAttendanceResponse(
      hasAttendance: json['has_attendance'] as bool,
      attendance: json['attendance'] == null
          ? null
          : TodayAttendance.fromJson(
              json['attendance'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$TodayAttendanceResponseToJson(
        TodayAttendanceResponse instance) =>
    <String, dynamic>{
      'has_attendance': instance.hasAttendance,
      'attendance': instance.attendance,
      'message': instance.message,
    };
