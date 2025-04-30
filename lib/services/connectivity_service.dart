import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal();
  
  // Connectivity status stream
  final _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityResult>.broadcast();
  
  // Queue of pending operations when offline
  late Box<Map<dynamic, dynamic>> _pendingOperationsBox;
  
  Stream<ConnectivityResult> get connectivityStream => _controller.stream;
  
  Future<void> initialize() async {
    // Open Hive box for pending operations
    _pendingOperationsBox = await Hive.openBox<Map<dynamic, dynamic>>('pendingOperations');
    
    // Initialize connectivity stream
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _controller.add(result);
      
      // When connectivity is restored, sync pending operations
      if (result != ConnectivityResult.none) {
        syncPendingOperations();
      }
    });
    
    // Check initial connectivity
    ConnectivityResult initialResult = await _connectivity.checkConnectivity();
    _controller.add(initialResult);
  }
  
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  Future<void> addPendingOperation(String operationType, Map<String, dynamic> data) async {
    await _pendingOperationsBox.add({
      'type': operationType,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }
  
  Future<void> syncPendingOperations() async {
    if (_pendingOperationsBox.isEmpty) return;
    
    // Check if online
    bool connected = await isConnected();
    if (!connected) return;
    
    // Process each pending operation
    for (int i = 0; i < _pendingOperationsBox.length; i++) {
      final operation = _pendingOperationsBox.getAt(i);
      
      if (operation != null) {
        await _processPendingOperation(operation);
        await _pendingOperationsBox.deleteAt(i);
      }
    }
  }
  
  Future<void> _processPendingOperation(Map<dynamic, dynamic> operation) async {
    // In a real app, this would make API calls to sync with the server
    // For this example, we're just simulating the process
    
    final type = operation['type'];
    final data = operation['data'];
    
    switch (type) {
      case 'material_add':
        debugPrint('Syncing added material: ${data['name']}');
        await Future.delayed(const Duration(milliseconds: 500));
        break;
        
      case 'material_update':
        debugPrint('Syncing updated material: ${data['id']}');
        await Future.delayed(const Duration(milliseconds: 500));
        break;
        
      case 'consumption_log':
        debugPrint('Syncing consumption log: ${data['productName']}');
        await Future.delayed(const Duration(milliseconds: 500));
        break;
        
      default:
        debugPrint('Unknown operation type: $type');
    }
  }
  
  void dispose() {
    _controller.close();
  }
} 