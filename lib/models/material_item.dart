import 'package:hive/hive.dart';

part 'material_item.g.dart';

@HiveType(typeId: 1)
class MaterialItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double unitCost;

  @HiveField(3)
  final String unitType;

  @HiveField(4)
  double stockQuantity;

  @HiveField(5)
  final String barcodeData;

  MaterialItem({
    required this.id,
    required this.name,
    required this.unitCost,
    required this.unitType,
    required this.stockQuantity,
    required this.barcodeData,
  });
}

@HiveType(typeId: 2)
class MaterialConsumption extends HiveObject {
  @HiveField(0)
  final String materialId;

  @HiveField(1)
  final double quantityUsed;

  @HiveField(2)
  final DateTime consumptionDate;

  @HiveField(3)
  final String productName;

  @HiveField(4)
  final double processingCost;

  @HiveField(5)
  final double desiredMargin;

  MaterialConsumption({
    required this.materialId,
    required this.quantityUsed,
    required this.consumptionDate,
    required this.productName,
    required this.processingCost,
    required this.desiredMargin,
  });

  double getRawMaterialCost(double unitCost) {
    return unitCost * quantityUsed;
  }

  double getManufacturingCost(double unitCost) {
    return getRawMaterialCost(unitCost) + processingCost;
  }

  double getFinalProductPrice(double unitCost) {
    return getManufacturingCost(unitCost) * (1 + desiredMargin);
  }

  double getProfitMargin(double unitCost) {
    return getFinalProductPrice(unitCost) - getManufacturingCost(unitCost);
  }
} 