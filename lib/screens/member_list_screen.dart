import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'member_profile_screen.dart';
import 'add_payment_screen.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List<dynamic> _allMembers = [];
  List<dynamic> _filteredActive = [];
  List<dynamic> _filteredExpired = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.membersList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _allMembers = data['members'] ?? [];
            _filterLists();
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading members: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _filterLists() {
    final searchLower = _searchQuery.toLowerCase();

    final active = _allMembers.where((m) => m['status'] != 'expired').toList();
    final expired = _allMembers.where((m) => m['status'] == 'expired').toList();

    setState(() {
      if (searchLower.isEmpty) {
        _filteredActive = active;
        _filteredExpired = expired;
      } else {
        _filteredActive = active.where((m) {
          final name = (m['name'] ?? '').toString().toLowerCase();
          final phone = (m['phone'] ?? '').toString().toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();

        _filteredExpired = expired.where((m) {
          final name = (m['name'] ?? '').toString().toLowerCase();
          final phone = (m['phone'] ?? '').toString().toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Members',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  _searchQuery = value;
                  _filterLists();
                },
                decoration: InputDecoration(
                  hintText: 'Search name / phone',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // TabBar
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Expired'),
              ],
            ),
            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildListView(_filteredActive, isActiveTab: true),
                        _buildListView(_filteredExpired, isActiveTab: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<dynamic> members, {required bool isActiveTab}) {
    if (members.isEmpty) {
      return const Center(
        child: Text('No members found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMembers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: members.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = members[index];
          final photoUrl = member['photo'];
          final name = member['name'] ?? 'Unknown';
          final phone = member['phone'] ?? 'N/A';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade50,
              child: (photoUrl != null && photoUrl.toString().isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blue,
                      ),
                    )
                  : const Icon(Icons.person, size: 30, color: Colors.blue),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                if (isActiveTab) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${member['remainingDays']} days left',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            trailing: !isActiveTab
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPaymentScreen(
                            memberId: int.parse(member['id'].toString()),
                            memberName: name,
                          ),
                        ),
                      );
                      if (result == true) {
                        _fetchMembers();
                      }
                    },
                    child: const Text(
                      'PAY NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: isActiveTab
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemberProfileScreen(
                          memberId: int.parse(member['id'].toString()),
                        ),
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }
}
