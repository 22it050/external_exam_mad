import 'package:flutter/material.dart';
import 'package:app/models/trancs.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>(); 
  
  // Default category
  String _category = 'Food'; 
  TextEditingController _amountController = TextEditingController();
  bool _isIncome = false;
  
  // Default date as current date
  DateTime _selectedDate = DateTime.now(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // Form with validation
          key: _formKey, 
          child: ListView(
            children: [
                
              // Input for transaction amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                      
                    // Validate amount
                    return 'Please enter an amount'; 
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown for selecting category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.category),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
                items: <String>['Food', 'Transportation', 'Entertainment']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Switch for Income/Expense selection
              SwitchListTile(
                title: const Text('Income'),
                value: _isIncome,
                onChanged: (bool value) {
                  setState(() {
                    _isIncome = value;
                  });
                },
                secondary: Icon(
                  _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),

              // Date picker for transaction date
              ListTile(
                title: Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                
                // Opens date picker
                onTap: () => _selectDate(context), 
              ),
              const SizedBox(height: 16),

              // Button to add the transaction
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                      
                    // Save form data
                    _formKey.currentState!.save(); 

                    // Create and save transaction
                    final transaction = Transaction(
                      category: _category,
                      amount: _amountController.text.isNotEmpty
                          ? double.parse(_amountController.text)
                          : 0.0,
                      isIncome: _isIncome,
                      date: _selectedDate,
                    );
                    Hive.box('transactions').add(transaction);

                    // Reset form after submission
                    setState(() {
                      _category = 'Food';
                      _amountController.clear();
                      _isIncome = false;
                      _selectedDate = DateTime.now();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction added'),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: const Text('Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Update selected date
      });
    }
  }
}