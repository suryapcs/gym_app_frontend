import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../core/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MemberProfileScreen extends StatefulWidget {
  final int memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  Map<String, dynamic>? _memberData;
  List<dynamic> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Fetch Profile
      final profileResponse = await http.get(
        Uri.parse('${ApiConstants.memberProfile}?id=${widget.memberId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Fetch Payments
      final paymentsResponse = await http.get(
        Uri.parse('${ApiConstants.memberPayments}?member_id=${widget.memberId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (profileResponse.statusCode == 200 && paymentsResponse.statusCode == 200) {
        final pData = json.decode(profileResponse.body);
        final pyData = json.decode(paymentsResponse.body);

        if (pData['status'] == 'success') {
          setState(() {
            _memberData = pData['member'];
            _payments = pyData['payments'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _calculateRemainingDays(String? activeUntil) {
    if (activeUntil == null || activeUntil.isEmpty) return 'Expired';
    try {
      final expiryDate = DateTime.parse(activeUntil);
      final difference = expiryDate.difference(DateTime.now()).inDays;
      if (difference < 0) return 'Expired';
      return '$difference days';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Member Profile'),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memberData == null
              ? const Center(child: Text('Profile not found'))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final photoUrl = _memberData!['photo'];
    final joinDate = _formatDate(_memberData!['created_at']);
    final remainingDays = _calculateRemainingDays(_memberData!['active_until']);
    final isExpired = remainingDays == 'Expired';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue.shade50,
            child: (photoUrl != null && photoUrl.toString().isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                    errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: Colors.blue),
                  )
                : const Icon(Icons.person, size: 60, color: Colors.blue),
          ),
          const SizedBox(height: 16),

          // Name and Phone
          Text(
            _memberData!['name'] ?? 'Unknown',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            _memberData!['phone'] ?? 'N/A',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 32),

          // Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Join Date', style: TextStyle(fontSize: 16, color: Colors.black)),
              Text(
                joinDate,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remaining Days', style: TextStyle(fontSize: 16, color: Colors.black)),
              Text(
                remainingDays,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Payments Section
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Payment History (Monthly)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_payments.isEmpty)
            const Text('No payment history found', style: TextStyle(color: Colors.grey))
          else
            ..._payments.map((payment) => _buildPaymentCard(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final month = payment['month'] ?? 'Unknown';
    final amount = double.tryParse(payment['total_amount']?.toString() ?? '0') ?? 0;
    final date = _formatDate(payment['paid_date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                month,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E6091),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Paid on $date',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ],
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
