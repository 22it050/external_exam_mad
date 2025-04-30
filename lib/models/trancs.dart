// Importing Hive package for local storage
import 'package:hive/hive.dart'; 

// Part statement is used for code
// generation for the Transaction class.
part 'trancs.g.dart'; 

// Defining a Hive Type with a unique
// typeId of 0 to store Transaction objects.
@HiveType(typeId: 0)
class Transaction extends HiveObject {
      
      // Field to store the category of the
      // transaction (e.g., Food, Transportation).
      @HiveField(0)
      final String category;
    
      // Field to store the transaction amount.
      @HiveField(1)
      final double amount;
    
      // Field to store whether the transaction
      // is an income (true) or an expense (false).
      @HiveField(2)
      final bool isIncome;
    
      // Field to store the date of the transaction.
      @HiveField(3)
      final DateTime date;
    
      // Constructor for the Transaction class
      // with required fields.
      Transaction({
        required this.category,
        required this.amount,
        required this.isIncome,
        required this.date,
      });
}