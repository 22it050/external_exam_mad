import 'package:flutter/material.dart';
import 'package:app/models/trancs.dart';
import 'package:app/models/material_item.dart';
import 'package:hive/hive.dart';
import 'package:app/screens/expence_home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register the adapters
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(MaterialItemAdapter());
  Hive.registerAdapter(MaterialConsumptionAdapter());

  // Open the Hive boxes
  await Hive.openBox('transactions');
  await Hive.openBox('materials');
  await Hive.openBox('consumptions');

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  runApp(const MaterialTrackingApp());
}

class MaterialTrackingApp extends StatelessWidget {
  const MaterialTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material Tracker & Inventory',
      home: ExpenseHomeScreen(),
    );
  }
}