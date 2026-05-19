import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_endpoints.dart';
import 'notification_service.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  HubConnection? _hubConnection;
  bool _isConnecting = false;
  bool _handlerAttached = false;

  final _notificationController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get notificationStream => _notificationController.stream;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> connect(String token) async {
    if (_isConnecting || isConnected) return;
    _isConnecting = true;

    try {
      _hubConnection ??= HubConnectionBuilder()
          .withUrl(
            ApiEndpoints.notificationHub,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      if (!_handlerAttached) {
        _hubConnection!.on('ReceiveNotification', _onReceiveNotification);
        _handlerAttached = true;
      }

      _hubConnection!.onclose(({error}) {
        debugPrint('SignalR closed: $error');
      });

      await _hubConnection!.start();
      debugPrint('SignalR connected');
    } catch (e) {
      debugPrint('SignalR connect failed: $e');
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
    } catch (e) {
      debugPrint('SignalR disconnect error: $e');
    } finally {
      _hubConnection = null;
      _handlerAttached = false;
      _isConnecting = false;
    }
  }

  void _onReceiveNotification(List<Object?>? arguments) {
    if (arguments == null || arguments.length < 2) return;

    final title = arguments[0]?.toString().trim();
    final message = arguments[1]?.toString().trim();
    if (title == null || title.isEmpty || message == null || message.isEmpty) return;

    NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647,
      title: title,
      body: message,
    );

    _notificationController.add({'title': title, 'message': message});
  }
}
