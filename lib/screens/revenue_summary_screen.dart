import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class RevenueSummaryScreen extends StatefulWidget {
  const RevenueSummaryScreen({super.key});

  @override
  State<RevenueSummaryScreen> createState() => _RevenueSummaryScreenState();
}

class _RevenueSummaryScreenState extends State<RevenueSummaryScreen> {
  final _trainerController = TextEditingController();
  final _electricityController = TextEditingController();
  final _maintenanceController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _otherController = TextEditingController();

  double _totalIncome = 0.0;
  double _closingBalance = 0.0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchRevenueData();
  }

  Future<void> _fetchRevenueData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.getMonthlyRevenue),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _totalIncome = (data['total_income'] ?? 0).toDouble();
            _closingBalance = (data['closing_balance'] ?? 0).toDouble();
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching revenue: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateInput() {
    // Check if all fields are empty
    if (_trainerController.text.isEmpty &&
        _electricityController.text.isEmpty &&
        _maintenanceController.text.isEmpty &&
        _equipmentController.text.isEmpty &&
        _otherController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one expense value'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    // Validate that all entered values are valid numbers
    final fields = [
      ('Trainer Fee', _trainerController.text),
      ('Electricity Fee', _electricityController.text),
      ('Maintenance Fee', _maintenanceController.text),
      ('Equipment Cost', _equipmentController.text),
      ('Other Expenses', _otherController.text),
    ];

    for (var field in fields) {
      if (field.$2.isNotEmpty) {
        try {
          final value = double.parse(field.$2);
          if (value < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${field.$1} cannot be negative'),
                duration: const Duration(seconds: 2),
              ),
            );
            return false;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${field.$1} must be a valid number'),
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _saveRevenue() async {
    // Validate input before saving
    if (!_validateInput()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConstants.saveRevenue),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {
          'trainer_fee': _trainerController.text.isEmpty
              ? '0'
              : _trainerController.text,
          'electricity_fee': _electricityController.text.isEmpty
              ? '0'
              : _electricityController.text,
          'maintenance_fee': _maintenanceController.text.isEmpty
              ? '0'
              : _maintenanceController.text,
          'equipment_fee': _equipmentController.text.isEmpty
              ? '0'
              : _equipmentController.text,
          'other_fee': _otherController.text.isEmpty
              ? '0'
              : _otherController.text,
        },
      );

      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revenue summary saved successfully!'),
            duration: Duration(seconds: 1),
          ),
        );
        // Navigate back to dashboard after a brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save summary'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving revenue: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _trainerController.dispose();
    _electricityController.dispose();
    _maintenanceController.dispose();
    _equipmentController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Monthly Revenue Summary',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildBalanceCard(
                    title: 'This Month Total Income',
                    amount: _totalIncome,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 16),
                  _buildBalanceCard(
                    title: 'Closing Balance',
                    amount: _closingBalance,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 32),
                  _buildExpenseField(
                    label: 'Trainer Fee',
                    controller: _trainerController,
                  ),
                  const SizedBox(height: 16),
                  _buildExpenseField(
                    label: 'Electricity Fee',
                    controller: _electricityController,
                  ),
                  const SizedBox(height: 16),
                  _buildExpenseField(
                    label: 'Maintenance Fee',
                    controller: _maintenanceController,
                  ),
                  const SizedBox(height: 16),
                  _buildExpenseField(
                    label: 'Equipment Cost',
                    controller: _equipmentController,
                  ),
                  const SizedBox(height: 16),
                  _buildExpenseField(
                    label: 'Other Expenses',
                    controller: _otherController,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveRevenue,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required double amount,
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF90CAF9), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.currency_rupee,
                color: Color(0xFF2196F3),
                size: 34,
              ),
              const SizedBox(width: 6),
              Text(
                amount.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




  Widget _buildExpenseField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDFF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.currency_rupee,
              color: Color(0xFF2196F3),
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minHeight: 24,
            minWidth: 40,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
