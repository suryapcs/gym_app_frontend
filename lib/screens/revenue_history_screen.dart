import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import 'package:intl/intl.dart';

class RevenueHistoryScreen extends StatefulWidget {
  const RevenueHistoryScreen({super.key});

  @override
  State<RevenueHistoryScreen> createState() => _RevenueHistoryScreenState();
}

class _RevenueHistoryScreenState extends State<RevenueHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.expenseHistory),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final data = json.decode(response.body);
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Unexpected API response');
      }

      setState(() {
        _history = data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatMonthYear(String val) {
    if (val.isEmpty) return 'Unknown';
    try {
      // 2026-04 -> April 2026
      final parts = val.split('-');
      if (parts.length == 2) {
        final monthIdx = int.parse(parts[1]);
        final year = parts[0];
        final monthName = DateFormat(
          'MMMM',
        ).format(DateTime(int.parse(year), monthIdx));
        return '$monthName $year';
      }
      return val;
    } catch (_) {
      return val;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Revenue History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(
              child: Text(
                'No historical revenue data found',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final monthYearStr = item['month_year']?.toString() ?? '';
                  final title = _formatMonthYear(monthYearStr);

                  final totalIncome =
                      double.tryParse(
                        item['total_income']?.toString() ?? '0',
                      ) ??
                      0;
                  final totalExpenses =
                      double.tryParse(
                        item['total_expenses']?.toString() ?? '0',
                      ) ??
                      0;
                  final balance =
                      double.tryParse(item['balance']?.toString() ?? '0') ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Income vs Expenses
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricBlock(
                                  label: 'Total Income',
                                  amount: totalIncome,
                                  color: Colors.green.shade700,
                                  icon: Icons.arrow_upward,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: _buildMetricBlock(
                                  label: 'Total Expenses',
                                  amount: totalExpenses,
                                  color: Colors.red.shade700,
                                  icon: Icons.arrow_downward,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Closing Balance
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: balance >= 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Closing Balance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: balance >= 0
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  '₹${balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildMetricBlock({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
