import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      ),
      home: const ExpenseTrackerScreen(),
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final IconData icon;
  final Color color;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen>
    with TickerProviderStateMixin {
  final List<Expense> _expenses = [];
  late AnimationController _balanceAnimationController;
  late AnimationController _chartAnimationController;
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_car,
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': const Color(0xFFEC4899),
    },
    {'name': 'Bills', 'icon': Icons.receipt, 'color': const Color(0xFFF59E0B)},
    {
      'name': 'Health',
      'icon': Icons.local_hospital,
      'color': const Color(0xFF10B981),
    },
  ];

  @override
  void initState() {
    super.initState();
    _balanceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize with dummy data
    _expenses.addAll([
      Expense(
        id: '1',
        title: 'Grocery Shopping',
        amount: 125.50,
        category: 'Food',
        date: DateTime.now().subtract(const Duration(days: 1)),
        icon: Icons.restaurant,
        color: const Color(0xFFEF4444),
      ),
      Expense(
        id: '2',
        title: 'Uber Ride',
        amount: 35.00,
        category: 'Transport',
        date: DateTime.now().subtract(const Duration(days: 2)),
        icon: Icons.directions_car,
        color: const Color(0xFF3B82F6),
      ),
      Expense(
        id: '3',
        title: 'Netflix Subscription',
        amount: 15.99,
        category: 'Entertainment',
        date: DateTime.now().subtract(const Duration(days: 3)),
        icon: Icons.movie,
        color: const Color(0xFFEC4899),
      ),
      Expense(
        id: '4',
        title: 'Electricity Bill',
        amount: 85.00,
        category: 'Bills',
        date: DateTime.now().subtract(const Duration(days: 5)),
        icon: Icons.receipt,
        color: const Color(0xFFF59E0B),
      ),
      Expense(
        id: '5',
        title: 'New Shoes',
        amount: 79.99,
        category: 'Shopping',
        date: DateTime.now().subtract(const Duration(days: 7)),
        icon: Icons.shopping_bag,
        color: const Color(0xFF8B5CF6),
      ),
    ]);

    _balanceAnimationController.forward();
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  double get _totalBalance {
    const double initialBalance = 5000.0;
    return initialBalance -
        _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get _totalExpenses {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
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
            radius: 60,
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

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.insert(0, expense);
    });
    _balanceAnimationController.reset();
    _balanceAnimationController.forward();
    _chartAnimationController.reset();
    _chartAnimationController.forward();
  }

  void _showAddExpenseModal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = _categories[0]['name'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
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
                'Add New Expense',
                style: GoogleFonts.poppins(
                  fontSize: 24,
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
                  fillColor: Colors.grey[50],
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: '0.00',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  prefixText: '\$ ',
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
                  fillColor: Colors.grey[50],
                ),
                style: GoogleFonts.poppins(),
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
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      final categoryData = _categories.firstWhere(
                        (cat) => cat['name'] == selectedCategory,
                      );
                      final expense = Expense(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        amount: double.parse(amountController.text),
                        category: selectedCategory,
                        date: DateTime.now(),
                        icon: categoryData['icon'],
                        color: categoryData['color'],
                      );
                      _addExpense(expense);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Expense',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    // Total Balance Card with Glassmorphism
                    AnimatedBuilder(
                      animation: _balanceAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              0.9 + (_balanceAnimationController.value * 0.1),
                          child: Opacity(
                            opacity: _balanceAnimationController.value,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Balance',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${_totalBalance.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 36,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.trending_down,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Total Expenses: \$${_totalExpenses.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
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
                                          radius:
                                              60 *
                                              _chartAnimationController.value,
                                          titleStyle: section.titleStyle,
                                        );
                                      }).toList(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 50,
                                      startDegreeOffset: -90,
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
                    const SizedBox(height: 44),
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
            // Expense List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final expense = _expenses[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _ExpenseItem(expense: expense),
                );
              }, childCount: _expenses.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: FloatingActionButton.extended(
          onPressed: _showAddExpenseModal,
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

  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 17),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(scale: 0.95 + (value * 0.05), child: child);
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
                  children: [
                    Text(
                      expense.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          expense.category,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
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
                        Text(
                          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '-\$${expense.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
