import 'dart:ui';

import 'package:expense_tracker/models/expense_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const ExpenseTrackerScreen(),
    );
  }
}

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen>
    with TickerProviderStateMixin {
  late Box _expenseBox;
  List<Expense> _expenses = [];
  bool _isInitialized = false;
  
  late AnimationController _balanceAnimationController;
  late AnimationController _chartAnimationController;
  late AnimationController _fabAnimationController;
  
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': const Color(0xFFEF4444),
      'iconName': 'restaurant',
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_car,
      'color': const Color(0xFF3B82F6),
      'iconName': 'directions_car',
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFF8B5CF6),
      'iconName': 'shopping_bag',
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': const Color(0xFFEC4899),
      'iconName': 'movie',
    },
    {
      'name': 'Bills',
      'icon': Icons.receipt,
      'color': const Color(0xFFF59E0B),
      'iconName': 'receipt',
    },
    {
      'name': 'Health',
      'icon': Icons.local_hospital,
      'color': const Color(0xFF10B981),
      'iconName': 'local_hospital',
    },
  ];

  String _currencySymbol = 'Rs';
  double _initialBalance = 5000.0;

  @override
  void initState() {
    super.initState();
    _initializeHive();
    
    _balanceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    
    // Open or create the expense box
    _expenseBox = await Hive.openBox('expenses');
    
    // Load currency symbol preference
    _currencySymbol = _expenseBox.get('currency_symbol', defaultValue: 'Rs');
    
    // Load initial balance
    _initialBalance = _expenseBox.get('initial_balance', defaultValue: 5000.0).toDouble();
    
    // Check if this is the first launch
    final isFirstLaunch = _expenseBox.get('first_launch', defaultValue: true);
    
    if (isFirstLaunch == true) {
      // Add dummy data
      await _loadDummyData();
      await _expenseBox.put('first_launch', false);
    } else {
      // Load existing expenses
      await _loadExpenses();
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      
      _balanceAnimationController.forward();
      _chartAnimationController.forward();
      _fabAnimationController.forward();
    }
  }

  Future<void> _loadDummyData() async {
    final dummyExpenses = [
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Grocery Shopping',
        amount: 125.50,
        category: 'Food',
        date: DateTime.now().subtract(const Duration(days: 1)),
        iconName: 'restaurant',
        colorValue: const Color(0xFFEF4444).value,
      ),
      Expense(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'Uber Ride',
        amount: 35.00,
        category: 'Transport',
        date: DateTime.now().subtract(const Duration(days: 2)),
        iconName: 'directions_car',
        colorValue: const Color(0xFF3B82F6).value,
      ),
      Expense(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        title: 'Netflix Subscription',
        amount: 15.99,
        category: 'Entertainment',
        date: DateTime.now().subtract(const Duration(days: 3)),
        iconName: 'movie',
        colorValue: const Color(0xFFEC4899).value,
      ),
      Expense(
        id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
        title: 'Electricity Bill',
        amount: 85.00,
        category: 'Bills',
        date: DateTime.now().subtract(const Duration(days: 5)),
        iconName: 'receipt',
        colorValue: const Color(0xFFF59E0B).value,
      ),
      Expense(
        id: (DateTime.now().millisecondsSinceEpoch + 4).toString(),
        title: 'New Shoes',
        amount: 79.99,
        category: 'Shopping',
        date: DateTime.now().subtract(const Duration(days: 7)),
        iconName: 'shopping_bag',
        colorValue: const Color(0xFF8B5CF6).value,
      ),
    ];

    final expensesList = dummyExpenses.map((e) => e.toMap()).toList();
    await _expenseBox.put('expenses_list', expensesList);
    setState(() {
      _expenses = List.from(dummyExpenses);
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _loadExpenses() async {
    final expensesList = _expenseBox.get('expenses_list');
    if (expensesList != null && expensesList is List) {
      setState(() {
        _expenses = expensesList
            .map((map) => Expense.fromMap(Map<String, dynamic>.from(map as Map)))
            .toList();
        // Sort by date (newest first)
        _expenses.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  Future<void> _saveExpenses() async {
    final expensesList = _expenses.map((e) => e.toMap()).toList();
    await _expenseBox.put('expenses_list', expensesList);
    if (mounted) {
      setState(() {});
    }
  }

  double get _totalBalance {
    return _initialBalance - _totalExpenses;
  }
  
  Future<void> _updateInitialBalance(double newBalance) async {
    setState(() {
      _initialBalance = newBalance;
    });
    await _expenseBox.put('initial_balance', newBalance);
    _balanceAnimationController.reset();
    _balanceAnimationController.forward();
  }

  double get _totalExpenses {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<PieChartSectionData> get _pieChartData {
    final totals = _categoryTotals;
    final total = _totalExpenses;
    if (total == 0) return [];

    final List<PieChartSectionData> sections = [];
    for (var category in _categories) {
      final amount = totals[category['name']] ?? 0.0;
      if (amount > 0) {
        final percentage = (amount / total) * 100;
        sections.add(
          PieChartSectionData(
            value: amount,
            title: '${percentage.toStringAsFixed(0)}%',
            color: category['color'],
            radius: 70,
            titleStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    return sections;
  }

  Future<void> _addExpense(Expense expense) async {
    setState(() {
      _expenses.insert(0, expense);
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    });
    await _saveExpenses();
    _balanceAnimationController.reset();
    _balanceAnimationController.forward();
    _chartAnimationController.reset();
    _chartAnimationController.forward();
  }

  Future<void> _updateExpense(Expense updatedExpense) async {
    setState(() {
      final index = _expenses.indexWhere((e) => e.id == updatedExpense.id);
      if (index != -1) {
        _expenses[index] = updatedExpense;
        _expenses.sort((a, b) => b.date.compareTo(a.date));
      }
    });
    await _saveExpenses();
    _balanceAnimationController.reset();
    _balanceAnimationController.forward();
    _chartAnimationController.reset();
    _chartAnimationController.forward();
  }

  Future<void> _deleteExpense(String id) async {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
    await _saveExpenses();
    _balanceAnimationController.reset();
    _balanceAnimationController.forward();
    _chartAnimationController.reset();
    _chartAnimationController.forward();
  }

  Future<void> _duplicateExpense(Expense expense, BuildContext actionContext) async {
    // Close slidable first
    if (Slidable.of(actionContext) != null) {
      Slidable.of(actionContext)!.close();
    }
    
    // Wait a bit for the close animation
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    final duplicatedExpense = expense.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
    );
    await _addExpense(duplicatedExpense);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expense duplicated',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showAddExpenseModal({Expense? expenseToEdit, BuildContext? slidableContext}) async {
    // Close slidable if it exists
    if (slidableContext != null && Slidable.of(slidableContext) != null) {
      Slidable.of(slidableContext)!.close();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!mounted) return;
    
    final titleController = TextEditingController(text: expenseToEdit?.title ?? '');
    final amountController = TextEditingController(text: expenseToEdit?.amount.toString() ?? '');
    String selectedCategory = expenseToEdit?.category ?? _categories[0]['name'];
    DateTime selectedDate = expenseToEdit?.date ?? DateTime.now();
    bool isEditMode = expenseToEdit != null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEditMode ? 'Edit Expense' : 'Add New Expense',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: GoogleFonts.poppins(),
                    hintText: 'Enter expense title',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: GoogleFonts.poppins(),
                    hintText: '0.00',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    prefixText: '$_currencySymbol ',
                    prefixStyle: GoogleFonts.poppins(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                // Date picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF6366F1),
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setModalState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Category',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _categories.map((category) {
                    final isSelected = selectedCategory == category['name'];
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedCategory = category['name'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category['color'].withValues(alpha: 0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? category['color']
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category['icon'],
                              color: category['color'],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: category['color'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (titleController.text.isNotEmpty &&
                              amountController.text.isNotEmpty) {
                            final categoryData = _categories.firstWhere(
                              (cat) => cat['name'] == selectedCategory,
                            );
                            final expense = Expense(
                              id: expenseToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              title: titleController.text,
                              amount: double.parse(amountController.text),
                              category: selectedCategory,
                              date: selectedDate,
                              iconName: categoryData['iconName'],
                              colorValue: categoryData['color'].value,
                            );
                            
                            if (isEditMode) {
                              _updateExpense(expense);
                            } else {
                              _addExpense(expense);
                            }
                            
                            Navigator.pop(context);
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditMode ? 'Expense updated' : 'Expense added',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            isEditMode ? 'Update Expense' : 'Add Expense',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Expense expense, BuildContext actionContext) async {
    // Close slidable first
    if (Slidable.of(actionContext) != null) {
      Slidable.of(actionContext)!.close();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Expense',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '"${expense.title}"?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _deleteExpense(expense.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Expense deleted',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showBalanceEditDialog() {
    final balanceController = TextEditingController(text: _initialBalance.toStringAsFixed(2));
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Initial Balance',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Initial Balance',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: '0.00',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  prefixText: '$_currencySymbol ',
                  prefixStyle: GoogleFonts.poppins(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (balanceController.text.isNotEmpty) {
                              _updateInitialBalance(double.parse(balanceController.text));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Balance updated',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Text(
                              'Update',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCurrencySelectorDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Currency',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await _expenseBox.put('currency_symbol', 'Rs');
                        if (mounted) {
                          setState(() {
                            _currencySymbol = 'Rs';
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: _currencySymbol == 'Rs'
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                )
                              : null,
                          color: _currencySymbol == 'Rs' ? null : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _currencySymbol == 'Rs'
                                ? Colors.transparent
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Rs (Rupees)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _currencySymbol == 'Rs' ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await _expenseBox.put('currency_symbol', '\$');
                        if (mounted) {
                          setState(() {
                            _currencySymbol = '\$';
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: _currencySymbol == '\$'
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                )
                              : null,
                          color: _currencySymbol == '\$' ? null : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _currencySymbol == '\$'
                                ? Colors.transparent
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '\$ (Dollars)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _currencySymbol == '\$' ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    _chartAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF6366F1)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Tracker',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Glassmorphic Balance Card
                    AnimatedBuilder(
                      animation: _balanceAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.95 + (_balanceAnimationController.value * 0.05),
                          child: Opacity(
                            opacity: _balanceAnimationController.value,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Glassmorphism effect
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Balance',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _showCurrencySelectorDialog(),
                                                  behavior: HitTestBehavior.opaque,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.attach_money,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () => _showBalanceEditDialog(),
                                                  behavior: HitTestBehavior.opaque,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () => _showBalanceEditDialog(),
                                          child: Text(
                                            '$_currencySymbol${_totalBalance.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 42,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.trending_down,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Total Expenses: $_currencySymbol${_totalExpenses.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Chart Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Breakdown',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_totalExpenses > 0)
                            AnimatedBuilder(
                              animation: _chartAnimationController,
                              builder: (context, child) {
                                return SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _pieChartData.map((section) {
                                        return PieChartSectionData(
                                          value: section.value,
                                          title: section.title,
                                          color: section.color,
                                          radius: 70 * _chartAnimationController.value,
                                          titleStyle: section.titleStyle,
                                        );
                                      }).toList(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 50,
                                      startDegreeOffset: -90,
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            Center(
                              child: Text(
                                'No expenses yet',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Expenses',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expense List with Swipe Actions
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = _expenses[index];
                  return _ExpenseItem(
                    expense: expense,
                    currencySymbol: _currencySymbol,
                    onDelete: (ctx) => _showDeleteConfirmDialog(expense, ctx),
                    onEdit: (ctx) => _showAddExpenseModal(expenseToEdit: expense, slidableContext: ctx),
                    onDuplicate: (ctx) => _duplicateExpense(expense, ctx),
                  );
                },
                childCount: _expenses.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimationController.value,
            child: Transform.rotate(
              angle: (1 - _fabAnimationController.value) * 0.5,
              child: child,
            ),
          );
        },
        child: FloatingActionButton.extended(
          onPressed: () => _showAddExpenseModal(),
          backgroundColor: const Color(0xFF6366F1),
          elevation: 8,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Expense',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final Expense expense;
  final String currencySymbol;
  final Function(BuildContext) onDelete;
  final Function(BuildContext) onEdit;
  final Function(BuildContext) onDuplicate;

  const _ExpenseItem({
    required this.expense,
    required this.currencySymbol,
    required this.onDelete,
    required this.onEdit,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 12),
      child: Slidable(
        key: ValueKey(expense.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => onDelete(context),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => onEdit(context),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: BorderRadius.circular(20),
            ),
            SlidableAction(
              onPressed: (context) => onDuplicate(context),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              icon: Icons.copy,
              label: 'Duplicate',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (value * 0.05),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: expense.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(expense.icon, color: expense.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expense.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              expense.category,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(expense.date),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '-$currencySymbol${expense.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
