import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'add_member_screen.dart';
import 'member_list_screen.dart';
import 'revenue_summary_screen.dart';
import 'revenue_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalMembers = 0;
  double totalRevenue = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _logout(context);
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.dashboardSummary),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            totalMembers = data['data']['total_members'] ?? 0;
            totalRevenue = (data['data']['total_revenue'] ?? 0.0).toDouble();
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      // Handle error quietly
    }
  }

  void _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: const Text(
          'FITPRO GYM',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2196F3)),
              child: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.people_alt,
                      iconColor: Colors.blue,
                      iconBgColor: Colors.blue.withOpacity(0.1),
                      title: 'Members',
                      value: isLoading ? '...' : totalMembers.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.payments,
                      iconColor: Colors.indigo,
                      iconBgColor: Colors.indigo.withOpacity(0.1),
                      title: 'Revenue',
                      value: isLoading ? '...' : '₹$totalRevenue',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Menu Items
              _buildMenuItem(
                icon: Icons.people,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.1),
                title: 'Member List',
                subtitle: 'View all gym members',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MemberListScreen(),
                    ),
                  ).then((_) => _fetchDashboardData());
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.person_add,
                iconColor: Colors.lightBlue,
                iconBgColor: Colors.lightBlue.withOpacity(0.1),
                title: 'Add Members',
                subtitle: 'Add new members',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMemberScreen(),
                    ),
                  ).then((_) => _fetchDashboardData());
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.account_balance,
                iconColor: Colors.indigo,
                iconBgColor: Colors.indigo.withOpacity(0.1),
                title: 'Revenue Summary',
                subtitle: 'Calculate & save revenue',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RevenueSummaryScreen(),
                    ),
                  ).then((_) => _fetchDashboardData());
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.calendar_month,
                iconColor: Colors.blueAccent,
                iconBgColor: Colors.blueAccent.withOpacity(0.1),
                title: 'Monthly Revenue',
                subtitle: 'Month-wise profit & loss',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RevenueHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
