
import 'package:flutter/material.dart';
import 'package:app/models/trancs.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    // Retrieve the Hive box where
    // transactions are stored
    final transactionBox = Hive.box('transactions');

    return Scaffold(
      body: ValueListenableBuilder(
        
        // Listens to changes in the transactions
        // box and rebuilds UI accordingly
        valueListenable: transactionBox.listenable(),
        builder: (context, Box box, widget) {
          
          // Display message when there are no transactions
          if (box.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    
                    // Icon indicating no transactions
                    Icons.money_off, 
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet.',
                    
                    // Optionally style this text using theme later
                  ),
                ],
              ),
            );
          } else {
              
            // If transactions exist, display them in a ListView
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              
              // Number of transactions
              itemCount: box.length, 
              itemBuilder: (context, index) {
                
                // Retrieve the transaction at the current index
                final transaction = box.getAt(index) as Transaction;
                
                // Check if it's an income
                final isIncome = transaction.isIncome;
                
                // Format the date
                final formattedDate = DateFormat.yMMMd()
                    .format(transaction.date); 

                // Display each transaction inside a card
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(
                      isIncome
                          ? Icons.arrow_upward
                          : Icons.arrow_downward, // Icon depending on transaction type
                      color: isIncome
                          ? Colors.green
                          : Colors.red, // Color for income/expense
                    ),
                    title: Text(
                      // Transaction category name
                      transaction.category, 
                      
                      // style: theme.textTheme.subtitle1, // Optional text styling
                    ),
                    
                    // Formatted transaction date
                    subtitle: Text(formattedDate), 
                    trailing: Text(
                      isIncome
                          ? '+ \$${transaction.amount.toStringAsFixed(2)}' // Display income with plus sign
                          : '- \$${transaction.amount.toStringAsFixed(2)}', // Display expense with minus sign
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome
                            ? Colors.green
                            : Colors.red, // Color based on transaction type
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}