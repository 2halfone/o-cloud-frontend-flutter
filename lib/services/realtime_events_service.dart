import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/admin_events.dart';
import '../utils/token_manager.dart';

class RealTimeEventsService {
  static const String _wsBaseUrl = 'ws://34.140.122.146:3001'; // WebSocket URL
  
  WebSocketChannel? _channel;
  StreamController<EventUpdateNotification>? _updateController;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  
  // Singleton pattern
  static final RealTimeEventsService _instance = RealTimeEventsService._internal();
  factory RealTimeEventsService() => _instance;
  RealTimeEventsService._internal();

  Stream<EventUpdateNotification> get updateStream => 
      _updateController?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      _updateController = StreamController<EventUpdateNotification>.broadcast();
      
      final uri = Uri.parse('$_wsBaseUrl/events/updates');
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('🔌 RealTimeEventsService: Connecting to WebSocket...');

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleConnectionClosed,
      );

      _isConnected = true;
      print('✅ RealTimeEventsService: WebSocket connected successfully');

      // Send initial connection message
      _sendMessage({
        'type': 'subscribe',
        'data': {
          'events': ['status_update', 'user_scan', 'event_update']
        }
      });

    } catch (e) {
      print('❌ RealTimeEventsService: Connection failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      print('📨 RealTimeEventsService: Received message: $data');

      final notification = EventUpdateNotification.fromJson(data);
      _updateController?.add(notification);
      
    } catch (e) {
      print('❌ RealTimeEventsService: Error parsing message: $e');
    }
  }

  void _handleError(error) {
    print('❌ RealTimeEventsService: WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleConnectionClosed() {
    print('🔌 RealTimeEventsService: WebSocket connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;

    print('⏰ RealTimeEventsService: Scheduling reconnection in 5 seconds...');
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        print('🔄 RealTimeEventsService: Attempting to reconnect...');
        connect();
      }
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }
  void subscribeToEvent(String eventId) {
    _sendMessage({
      'type': 'subscribe_event',
      'data': {
        'event_id': eventId
      }
    });
    print('📡 RealTimeEventsService: Subscribed to event: $eventId');
  }

  Stream<Map<String, dynamic>> subscribeToEventUpdates(String eventId) {
    subscribeToEvent(eventId);
    
    return updateStream
        .where((notification) => notification.eventId == eventId)
        .map((notification) => {
          'type': notification.type,
          'event_id': notification.eventId,
          'user_id': notification.data['user_id'],
          'status': notification.data['status'],
          'statistics': notification.data['statistics'],
          'user': notification.data['user'],
        });
  }

  void unsubscribeFromEvent(String eventId) {
    _sendMessage({
      'type': 'unsubscribe_event',
      'data': {
        'event_id': eventId
      }
    });
    print('📡 RealTimeEventsService: Unsubscribed from event: $eventId');
  }

  void disconnect() {
    print('🔌 RealTimeEventsService: Disconnecting...');
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _updateController?.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
  }
}

class EventUpdateNotification {
  final String type;
  final String eventId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  EventUpdateNotification({
    required this.type,
    required this.eventId,
    required this.data,
    required this.timestamp,
  });

  factory EventUpdateNotification.fromJson(Map<String, dynamic> json) {
    return EventUpdateNotification(
      type: json['type'] as String,
      eventId: json['event_id'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  bool get isStatusUpdate => type == 'status_update';
  bool get isUserScan => type == 'user_scan';
  bool get isEventUpdate => type == 'event_update';

  UserAttendanceDetail? get updatedUser {
    if (isStatusUpdate || isUserScan) {
      try {
        return UserAttendanceDetail.fromJson(data['user'] as Map<String, dynamic>);
      } catch (e) {
        print('❌ EventUpdateNotification: Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }
  EventStatistics? get updatedStatistics {
    if (data.containsKey('statistics')) {
      try {
        return EventStatistics.fromJson(data['statistics'] as Map<String, dynamic>);
      } catch (e) {
        print('❌ EventUpdateNotification: Error parsing statistics: $e');
        // Log the raw data for debugging
        print('📊 Raw statistics data: ${data['statistics']}');
        return null;
      }
    }
    return null;
  }
}
