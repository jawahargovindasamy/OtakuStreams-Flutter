// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

/// A production-ready Socket.io WebSocket service implementing the Singleton pattern,
/// featuring automatic reconnect, token authentication, and a broadcast stream for events.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  socket_io.Socket? _socket;
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of real-time notification messages.
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;

  /// Checks if the connection is active.
  bool get isConnected => _socket?.connected ?? false;

  /// Establishes connection to the specified [baseUrl] with the user's [token].
  void connect(String baseUrl, String token) {
    if (_socket != null) {
      if (_socket!.connected) return;
      _socket!.disconnect();
    }

    final String socketUrl = baseUrl.replaceAll('/api', '');
    debugPrint('Connecting to Socket.io WebSocket: $socketUrl');

    _socket = socket_io.io(
      socketUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('==================================================');
      print('🟢 WEBSOCKET: Socket.io connected successfully!');
      print('==================================================');
    });

    _socket!.onDisconnect((_) {
      print('==================================================');
      print('🔴 WEBSOCKET: Socket.io disconnected from server.');
      print('==================================================');
    });

    _socket!.onConnectError((err) {
      print('==================================================');
      print('⚠️ WEBSOCKET: Socket.io connection error: $err');
      print('==================================================');
    });

    _socket!.on('newNotification', (data) {
      print('🟢 WEBSOCKET: Received newNotification event: $data');
      if (data != null) {
        try {
          if (data is Map<String, dynamic>) {
            _notificationController.add(data);
          } else if (data is Map) {
            _notificationController.add(Map<String, dynamic>.from(data));
          }
        } catch (e) {
          print('❌ WEBSOCKET: Error parsing notification data: $e');
        }
      }
    });

    _socket!.connect();
  }

  /// Disconnects the socket and cleans up resources.
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    debugPrint('Socket.io WebSocket disconnected and cleared');
  }
}
