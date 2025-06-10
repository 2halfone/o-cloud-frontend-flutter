// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventInfo _$EventInfoFromJson(Map<String, dynamic> json) => EventInfo(
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String,
      date: json['date'] as String,
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$EventInfoToJson(EventInfo instance) => <String, dynamic>{
      'event_id': instance.eventId,
      'event_name': instance.eventName,
      'date': instance.date,
      'is_active': instance.isActive,
    };

EventUsersPagination _$EventUsersPaginationFromJson(
        Map<String, dynamic> json) =>
    EventUsersPagination(
      currentPage: (json['current_page'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
      totalUsers: (json['total_users'] as num).toInt(),
      usersPerPage: (json['users_per_page'] as num).toInt(),
    );

Map<String, dynamic> _$EventUsersPaginationToJson(
        EventUsersPagination instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'total_pages': instance.totalPages,
      'total_users': instance.totalUsers,
      'users_per_page': instance.usersPerPage,
    };

UserStatusUpdateResponse _$UserStatusUpdateResponseFromJson(
        Map<String, dynamic> json) =>
    UserStatusUpdateResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      user: UserAttendanceDetail.fromJson(json['user'] as Map<String, dynamic>),
      eventStatistics: EventStatistics.fromJson(
          json['event_statistics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserStatusUpdateResponseToJson(
        UserStatusUpdateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'user': instance.user,
      'event_statistics': instance.eventStatistics,
    };
