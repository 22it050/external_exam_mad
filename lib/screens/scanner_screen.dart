import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:app/models/material_item.dart';
import 'dart:math';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String _scannedCode = '';
  MaterialItem? _foundMaterial;
  bool _isLoading = false;
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _scanBarcode() async {
    // This would normally use a barcode scanner plugin
    // For this example, we'll simulate scanning by manually entering a code
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    // Get the barcode from the text field
    final barcode = _barcodeController.text;
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a barcode')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _scannedCode = barcode;
    });

    // Look up the material in the Hive box
    final materialsBox = Hive.box('materials');
    final materials = materialsBox.values.toList().cast<MaterialItem>();
    _foundMaterial = materials.firstWhere(
      (material) => material.barcodeData == _scannedCode,
      orElse: () => MaterialItem(
        id: 'temp_${Random().nextInt(10000)}',
        name: 'Unknown Material',
        unitCost: 0,
        unitType: 'unit',
        stockQuantity: 0,
        barcodeData: _scannedCode,
      ),
    );

    if (_foundMaterial!.name == 'Unknown Material') {
      // If material not found, prompt to add it
      _showAddMaterialDialog();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showAddMaterialDialog() {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final unitTypeController = TextEditingController(text: 'unit');
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Material Name'),
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Unit Cost'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitTypeController,
                decoration: const InputDecoration(labelText: 'Unit Type (kg, liter, etc)'),
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Current Stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty || costController.text.isEmpty || stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final newMaterial = MaterialItem(
                id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                unitCost: double.parse(costController.text),
                unitType: unitTypeController.text,
                stockQuantity: double.parse(stockController.text),
                barcodeData: _scannedCode,
              );

              // Save to Hive
              Hive.box('materials').add(newMaterial);

              setState(() {
                _foundMaterial = newMaterial;
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Material added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _logConsumption() {
    if (_foundMaterial == null) return;

    final quantityController = TextEditingController();
    final productNameController = TextEditingController();
    final processingCostController = TextEditingController();
    final marginController = TextEditingController(text: '0.3'); // 30% default margin

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Consumption: ${_foundMaterial!.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (${_foundMaterial!.unitType})',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: productNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: processingCostController,
                decoration: const InputDecoration(labelText: 'Processing Cost'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: marginController,
                decoration: const InputDecoration(labelText: 'Desired Margin (0.3 = 30%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (quantityController.text.isEmpty || 
                  productNameController.text.isEmpty || 
                  processingCostController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final quantity = double.parse(quantityController.text);
              
              // Check if enough stock
              if (quantity > _foundMaterial!.stockQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough stock available')),
                );
                return;
              }

              // Create consumption record
              final consumption = MaterialConsumption(
                materialId: _foundMaterial!.id,
                quantityUsed: quantity,
                consumptionDate: DateTime.now(),
                productName: productNameController.text,
                processingCost: double.parse(processingCostController.text),
                desiredMargin: double.parse(marginController.text),
              );

              // Save consumption to Hive
              Hive.box('consumptions').add(consumption);

              // Update stock
              final materialsBox = Hive.box('materials');
              final materials = materialsBox.values.toList().cast<MaterialItem>();
              final index = materials.indexWhere((m) => m.id == _foundMaterial!.id);
              
              if (index != -1) {
                final material = materials[index];
                material.stockQuantity -= quantity;
                
                // If stock is low, show alert
                if (material.stockQuantity < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Low stock alert: ${material.name} (${material.stockQuantity} ${material.unitType} left)'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
                
                materialsBox.putAt(index, material);
                
                // Update local state
                setState(() {
                  _foundMaterial = material;
                });
              }

              Navigator.pop(context);
              
              // Show calculations
              _showCalculationsDialog(consumption, _foundMaterial!.unitCost);
            },
            child: const Text('Log Consumption'),
          ),
        ],
      ),
    );
  }

  void _showCalculationsDialog(MaterialConsumption consumption, double unitCost) {
    final rawMaterialCost = consumption.getRawMaterialCost(unitCost);
    final manufacturingCost = consumption.getManufacturingCost(unitCost);
    final finalPrice = consumption.getFinalProductPrice(unitCost);
    final profitMargin = consumption.getProfitMargin(unitCost);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cost Calculations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raw Material Cost: \$${rawMaterialCost.toStringAsFixed(2)}'),
            Text('Processing Cost: \$${consumption.processingCost.toStringAsFixed(2)}'),
            Text('Manufacturing Cost: \$${manufacturingCost.toStringAsFixed(2)}'),
            const Divider(),
            Text('Suggested Selling Price: \$${finalPrice.toStringAsFixed(2)}'),
            Text('Profit per Unit: \$${profitMargin.toStringAsFixed(2)}'),
            Text('Profit Margin: ${(consumption.desiredMargin * 100).toStringAsFixed(0)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Scanner input (would be camera view in a real app)
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Enter barcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _scanBarcode,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.camera_alt),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Material details
            if (_foundMaterial != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _foundMaterial!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Barcode: $_scannedCode'),
                      Text('Unit Cost: \$${_foundMaterial!.unitCost.toStringAsFixed(2)}'),
                      Text('Unit Type: ${_foundMaterial!.unitType}'),
                      Text(
                        'Available Stock: ${_foundMaterial!.stockQuantity} ${_foundMaterial!.unitType}',
                        style: TextStyle(
                          color: _foundMaterial!.stockQuantity < 10 ? Colors.red : Colors.black,
                          fontWeight: _foundMaterial!.stockQuantity < 10 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _logConsumption,
                        child: const Text('Log Material Consumption'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 