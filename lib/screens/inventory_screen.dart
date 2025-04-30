import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app/models/material_item.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addNewMaterial() {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final unitTypeController = TextEditingController(text: 'unit');
    final stockController = TextEditingController();
    final barcodeController = TextEditingController();

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
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode (optional)'),
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
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final newMaterial = MaterialItem(
                id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                unitCost: double.parse(costController.text),
                unitType: unitTypeController.text,
                stockQuantity: double.parse(stockController.text),
                barcodeData: barcodeController.text.isEmpty 
                    ? 'NOBC-${DateTime.now().millisecondsSinceEpoch}'
                    : barcodeController.text,
              );

              // Save to Hive
              Hive.box('materials').add(newMaterial);

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

  void _updateStock(MaterialItem material) {
    final stockController = TextEditingController(text: material.stockQuantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${material.name}'),
        content: TextField(
          controller: stockController,
          decoration: InputDecoration(labelText: 'New Stock (${material.unitType})'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a value')),
                );
                return;
              }

              // Update stock in Hive
              final materialsBox = Hive.box('materials');
              final materials = materialsBox.values.toList().cast<MaterialItem>();
              final index = materials.indexWhere((m) => m.id == material.id);
              
              if (index != -1) {
                material.stockQuantity = double.parse(stockController.text);
                materialsBox.putAt(index, material);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('materials').listenable(),
      builder: (context, box, widget) {
        if (box.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No materials in inventory'),
              ],
            ),
          );
        }

        final materials = box.values.toList().cast<MaterialItem>();
        
        // Filter materials based on search query
        final filteredMaterials = _searchQuery.isEmpty
            ? materials
            : materials.where((m) => 
                m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.barcodeData.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();

        return ListView.builder(
          itemCount: filteredMaterials.length,
          itemBuilder: (context, index) {
            final material = filteredMaterials[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(
                  material.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barcode: ${material.barcodeData}'),
                    Text('Cost: \$${material.unitCost.toStringAsFixed(2)} per ${material.unitType}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${material.stockQuantity} ${material.unitType}',
                          style: TextStyle(
                            color: material.stockQuantity < 10 ? Colors.red : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (material.stockQuantity < 10)
                          const Text(
                            'LOW STOCK',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _updateStock(material),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConsumptionHistory() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('consumptions').listenable(),
      builder: (context, box, widget) {
        if (box.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No consumption history'),
              ],
            ),
          );
        }

        final materialsBox = Hive.box('materials');
        final materials = materialsBox.values.toList().cast<MaterialItem>();
        
        final consumptions = box.values.toList().cast<MaterialConsumption>();
        
        // Sort by date (newest first)
        consumptions.sort((a, b) => b.consumptionDate.compareTo(a.consumptionDate));
        
        // Filter consumptions based on search query
        final filteredConsumptions = _searchQuery.isEmpty
            ? consumptions
            : consumptions.where((c) {
                // Find the material name for the material ID
                final material = materials.firstWhere(
                  (m) => m.id == c.materialId,
                  orElse: () => MaterialItem(
                    id: 'unknown',
                    name: 'Unknown Material',
                    unitCost: 0,
                    unitType: 'unit',
                    stockQuantity: 0,
                    barcodeData: '',
                  ),
                );
                
                return material.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                       c.productName.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

        return ListView.builder(
          itemCount: filteredConsumptions.length,
          itemBuilder: (context, index) {
            final consumption = filteredConsumptions[index];
            
            // Find the material name for the material ID
            final material = materials.firstWhere(
              (m) => m.id == consumption.materialId,
              orElse: () => MaterialItem(
                id: 'unknown',
                name: 'Unknown Material',
                unitCost: 0,
                unitType: 'unit',
                stockQuantity: 0,
                barcodeData: '',
              ),
            );
            
            final formattedDate = DateFormat.yMMMd().format(consumption.consumptionDate);
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(
                  'Product: ${consumption.productName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Material: ${material.name}'),
                    Text('Used: ${consumption.quantityUsed} ${material.unitType}'),
                    Text('Date: $formattedDate'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Raw Cost: \$${consumption.getRawMaterialCost(material.unitCost).toStringAsFixed(2)}',
                    ),
                    Text(
                      'Final: \$${consumption.getFinalProductPrice(material.unitCost).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Materials', icon: Icon(Icons.inventory)),
            Tab(text: 'Consumption History', icon: Icon(Icons.history)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search materials or products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMaterialsList(),
                _buildConsumptionHistory(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMaterial,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
} 