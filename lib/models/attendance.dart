import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';

enum AttendanceStatus {
  @JsonValue('present')
  present,
  
  @JsonValue('hospital')
  hospital,
  
  @JsonValue('family')
  family,
  
  @JsonValue('emergency')
  emergency,
  
  @JsonValue('vacancy')
  vacancy,
  
  @JsonValue('personal')
  personal,
  
  @JsonValue('not_registered')
  notRegistered,
}

@JsonSerializable()
class QRContent {
  final String jwt;
  final String type;
  final String version;

  QRContent({
    required this.jwt,
    required this.type,
    required this.version,
  });

  factory QRContent.fromJson(Map<String, dynamic> json) =>
      _$QRContentFromJson(json);

  Map<String, dynamic> toJson() => _$QRContentToJson(this);
}

@JsonSerializable()
class AttendanceRequest {
  @JsonKey(name: 'qr_content')
  final QRContent qrContent;
  final AttendanceStatus status;
  final String? reason;

  AttendanceRequest({
    required this.qrContent,
    required this.status,
    this.reason,
  });

  factory AttendanceRequest.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceRequestToJson(this);
}

@JsonSerializable()
class AttendanceResponse {
  final String message;
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'event_name')
  final String eventName;
  final AttendanceStatus status;
  final DateTime timestamp;

  AttendanceResponse({
    required this.message,
    required this.eventId,
    required this.eventName,
    required this.status,
    required this.timestamp,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceResponseToJson(this);
}

@JsonSerializable()
class AttendanceHistoryItem {
  final int id;
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'event_name')
  final String eventName;  final AttendanceStatus status;
  final DateTime timestamp;
  final String? reason;

  AttendanceHistoryItem({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.status,
    required this.timestamp,
    this.reason,
  });

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$AttendanceHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceHistoryItemToJson(this);
}

@JsonSerializable()
class AttendanceHistoryResponse {
  final List<AttendanceHistoryItem> attendance;
  final int total;
  final int page;
  final int limit;

  AttendanceHistoryResponse({
    required this.attendance,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceHistoryResponseToJson(this);
}

@JsonSerializable()
class TodayAttendance {
  final int id;
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'event_name')
  final String eventName;
  final AttendanceStatus status;
  final DateTime timestamp;

  TodayAttendance({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.status,
    required this.timestamp,
  });

  factory TodayAttendance.fromJson(Map<String, dynamic> json) =>
      _$TodayAttendanceFromJson(json);

  Map<String, dynamic> toJson() => _$TodayAttendanceToJson(this);
}

@JsonSerializable()
class TodayAttendanceResponse {
  @JsonKey(name: 'has_attendance')
  final bool hasAttendance;
  final TodayAttendance? attendance;
  final String? message;

  TodayAttendanceResponse({
    required this.hasAttendance,
    this.attendance,
    this.message,
  });

  factory TodayAttendanceResponse.fromJson(Map<String, dynamic> json) =>
      _$TodayAttendanceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TodayAttendanceResponseToJson(this);
}
