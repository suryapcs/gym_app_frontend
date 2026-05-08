import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_constants.dart';
import 'add_payment_screen.dart';

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

      // Fetch both profile and payments in parallel for faster loading
      final responses = await Future.wait([
        http
            .get(
              Uri.parse('${ApiConstants.memberProfile}?id=${widget.memberId}'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(ApiConstants.timeout),
        http
            .get(
              Uri.parse(
                '${ApiConstants.memberPayments}?member_id=${widget.memberId}',
              ),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(ApiConstants.timeout),
      ]);

      final profileResponse = responses[0];
      final paymentsResponse = responses[1];

      if (profileResponse.statusCode == 200 &&
          paymentsResponse.statusCode == 200) {
        final pData = json.decode(profileResponse.body);
        final pyData = json.decode(paymentsResponse.body);

        if (pData['status'] == 'success') {
          print('📸 Member Photo URL: ${pData['member']['photo']}');

          setState(() {
            _memberData = pData['member'];
            _payments = pyData['payments'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ Profile Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
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

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading image...')));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Read bytes and encode as base64 — no dart:io needed
      final imageBytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final ext = pickedFile.name.split('.').last.toLowerCase();

      // Send as plain POST with JSON body
      final response = await http
          .post(
            Uri.parse(ApiConstants.updateMember),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'id': widget.memberId,
              'name': _memberData!['name'] ?? '',
              'phone': _memberData!['phone'] ?? '',
              'address': _memberData!['address'] ?? '',
              'photo_base64': base64Image,
              'photo_ext': ext,
            }),
          )
          .timeout(ApiConstants.timeout);

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile image updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchProfileData(); // Refresh to show new image
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${data['message'] ?? 'Upload failed'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Image'),
        content: const Text('Choose image source:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Opens a fullscreen Telegram-style image viewer with Hero animation + pinch-to-zoom.
  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: _ImageViewerPage(
              imageUrl: imageUrl,
              heroTag: 'member_photo_${widget.memberId}',
              memberName: _memberData?['name'] ?? '',
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Opens a bottom sheet to edit member details.
  void _openEditSheet() {
    final nameCtrl = TextEditingController(text: _memberData!['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _memberData!['phone'] ?? '');
    final addressCtrl = TextEditingController(
      text: _memberData!['address'] ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;
              setSheetState(() => isSaving = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token') ?? '';

                final request =
                    http.MultipartRequest(
                        'POST',
                        Uri.parse(ApiConstants.updateMember),
                      )
                      ..headers['Authorization'] = 'Bearer $token'
                      ..fields['id'] = widget.memberId.toString()
                      ..fields['name'] = nameCtrl.text.trim()
                      ..fields['phone'] = phoneCtrl.text.trim()
                      ..fields['address'] = addressCtrl.text.trim();

                final streamed = await request.send().timeout(
                  ApiConstants.timeout,
                );
                final body = await streamed.stream.bytesToString();
                final data = json.decode(body);

                if (!ctx.mounted) return;

                if (data['status'] == 'success') {
                  Navigator.pop(ctx); // close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchProfileData(); // refresh
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ ${data['message'] ?? 'Update failed'}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (ctx.mounted) setSheetState(() => isSaving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Edit Member',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Name Field
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Phone is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: addressCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.blue.shade200,
                        ),
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          isSaving ? 'Saving...' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        actions: [
          if (_memberData != null)
            IconButton(
              onPressed: _openEditSheet,
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Profile',
            ),
        ],
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
          // Profile Image — tap to open fullscreen (Telegram style)
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (photoUrl != null && photoUrl.toString().isNotEmpty) {
                    _openImageViewer(context, photoUrl);
                  }
                },
                child: Hero(
                  tag: 'member_photo_${widget.memberId}',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade50,
                    child: (photoUrl != null && photoUrl.toString().isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              photoUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.blue,
                                  ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.blue,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Change Profile Image',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name and Phone
          Text(
            _memberData!['name'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
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
              const Text(
                'Join Date',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              Text(
                joinDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remaining Days',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
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
          const SizedBox(height: 24),

          // Renew button for expired members
          if (isExpired)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Renew Membership',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPaymentScreen(
                        memberId: widget.memberId,
                        memberName: _memberData!['name'] ?? 'Member',
                      ),
                    ),
                  );
                  if (result == true) {
                    _fetchProfileData(); // refresh profile
                    if (mounted) Navigator.pop(context, true); // refresh list
                  }
                },
              ),
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
            const Text(
              'No payment history found',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._payments.map((payment) => _buildPaymentCard(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final month = payment['month'] ?? 'Unknown';
    final amount =
        double.tryParse(payment['total_amount']?.toString() ?? '0') ?? 0;
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

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen Telegram-style Image Viewer
// ─────────────────────────────────────────────────────────────────────────────
class _ImageViewerPage extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String memberName;

  const _ImageViewerPage({
    required this.imageUrl,
    required this.heroTag,
    required this.memberName,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  late final Animation<double> _bgOpacity;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bgOpacity = CurvedAnimation(parent: _bgController, curve: Curves.easeOut);
    _bgController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _close() {
    _bgController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: AnimatedBuilder(
        animation: _bgOpacity,
        builder: (_, child) => ColoredBox(
          color: Colors.black.withOpacity(0.92 * _bgOpacity.value),
          child: child,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── Zoomable image ──────────────────────────────────────
              Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Top bar: close button ───────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _close,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom bar: member name ─────────────────────────────
              if (widget.memberName.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      widget.memberName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)],
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
}
