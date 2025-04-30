// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialItemAdapter extends TypeAdapter<MaterialItem> {
  @override
  final int typeId = 1;

  @override
  MaterialItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialItem(
      id: fields[0] as String,
      name: fields[1] as String,
      unitCost: fields[2] as double,
      unitType: fields[3] as String,
      stockQuantity: fields[4] as double,
      barcodeData: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.unitCost)
      ..writeByte(3)
      ..write(obj.unitType)
      ..writeByte(4)
      ..write(obj.stockQuantity)
      ..writeByte(5)
      ..write(obj.barcodeData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaterialConsumptionAdapter extends TypeAdapter<MaterialConsumption> {
  @override
  final int typeId = 2;

  @override
  MaterialConsumption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialConsumption(
      materialId: fields[0] as String,
      quantityUsed: fields[1] as double,
      consumptionDate: fields[2] as DateTime,
      productName: fields[3] as String,
      processingCost: fields[4] as double,
      desiredMargin: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialConsumption obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.materialId)
      ..writeByte(1)
      ..write(obj.quantityUsed)
      ..writeByte(2)
      ..write(obj.consumptionDate)
      ..writeByte(3)
      ..write(obj.productName)
      ..writeByte(4)
      ..write(obj.processingCost)
      ..writeByte(5)
      ..write(obj.desiredMargin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialConsumptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
} 