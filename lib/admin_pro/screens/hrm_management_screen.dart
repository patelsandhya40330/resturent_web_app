import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/tenant_service.dart';
import '../admin_theme.dart';

class HRMManagementScreen extends StatefulWidget {
  final String mode;
  const HRMManagementScreen({super.key, required this.mode});

  @override
  State<HRMManagementScreen> createState() => _HRMManagementScreenState();
}

class _HRMManagementScreenState extends State<HRMManagementScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController(text: "0.00");
  final _cycleController = TextEditingController(text: "30");
  final _currentAddrController = TextEditingController();
  final _permanentAddrController = TextEditingController();
  final _citizenshipController = TextEditingController();
  final _documentController = TextEditingController();

  String _selectedRole = 'Waiter';
  String _currentStatus = 'Active';
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _deletedStaffList = [];
  String _searchQuery = "";
  String? _selectedFilterRole;
  bool _showDeleted = false;
  int _displayCount = 10; // New: Limit for displayed items
  
  Map<String, dynamic>? _selectedStaff;
  bool _isEditing = false;
  bool _isPinVisible = false;
  bool _isAdding = false;

  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _currentProfileUrl;

  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  
  final Map<int, String> _attendanceMap = {};
  List<Map<String, dynamic>> _reportData = [];
  Map<String, dynamic>? _analyticsData;
  String _selectedRange = "Month";
  
  final Set<int> _completedToday = {};
  final Map<int, Timer> _undoTimers = {};
  final Map<int, String> _pendingSaves = {}; 
  final Set<int> _successSaves = {}; 

  Map<String, dynamic>? _individualStats;
  bool _isLoadingIndividual = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    for (var timer in _undoTimers.values) {
      timer.cancel();
    }
    _undoTimers.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HRMManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _loadStaff();
    }
  }

  Future<void> _loadStaff() async {
    final tenant = TenantService().currentTenant.value;
    
    setState(() {
      _isLoading = true;
      // Load demo data immediately if list is empty for a responsive feel
      if (_staffList.isEmpty) {
        _staffList = _getDemoData();
      }
    });

    if (tenant == null) {
      // In local/offline mode, we just stay with demo data
      setState(() => _isLoading = false);
      return;
    }
    
    _completedToday.clear();
    _pendingSaves.clear();
    _successSaves.clear();
    
    final data = await ApiService.fetchStaff(tenant.id);
    
    if (mounted) {
      if (data != null && data.isNotEmpty) {
        setState(() {
          _staffList = data;
        });
      }
        
      if (widget.mode.contains("Attendance")) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final attData = await ApiService.fetchAttendance(tenant.id, today);
        if (attData != null && mounted) {
          setState(() {
            for (var row in attData) {
              final int uid = int.parse(row['user_id'].toString());
              _attendanceMap[uid] = row['status'];
              _completedToday.add(uid);
            }
          });
        }
        if (widget.mode == "Attendance Report") {
          await _loadReport();
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReport() async {
    final tenant = TenantService().currentTenant.value;
    if (tenant == null) return;
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1).toString().split(' ')[0];
    final lastDay = DateTime(now.year, now.month + 1, 0).toString().split(' ')[0];
    final report = await ApiService.fetchAttendanceReport(tenant.id, firstDay, lastDay);
    final analytics = await ApiService.fetchAttendanceAnalytics(tenant.id, _selectedRange);
    if (mounted) {
      setState(() {
        _reportData = report ?? [];
        _analyticsData = analytics;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadIndividualStats(int userId) async {
    setState(() {
      _isLoadingIndividual = true;
      _individualStats = null;
    });
    final month = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
    final data = await ApiService.fetchEmployeeStats(userId, month);
    if (mounted) {
      setState(() {
        _individualStats = data;
        _isLoadingIndividual = false;
      });
    }
  }

  Future<void> _handleAttendanceClick(int userId, String status, String name) async {
    final tenant = TenantService().currentTenant.value;
    if (tenant == null) return;
    setState(() {
      _pendingSaves[userId] = status;
    });
    _undoTimers[userId] = Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final success = await ApiService.markSingleAttendance({
        'tenant_id': tenant.id,
        'user_id': userId,
        'date': today,
        'status': status,
      });
      if (success && mounted) {
        setState(() {
          _pendingSaves.remove(userId);
          _successSaves.add(userId);
          _attendanceMap[userId] = status;
          _completedToday.add(userId);
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) setState(() => _successSaves.remove(userId));
      } else if (mounted) {
        setState(() => _pendingSaves.remove(userId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save. Try again."), backgroundColor: Colors.red));
      }
      _undoTimers.remove(userId);
    });
  }

  void _cancelAttendance(int userId) {
    _undoTimers[userId]?.cancel();
    setState(() {
      _undoTimers.remove(userId);
      _pendingSaves.remove(userId);
    });
  }

  Future<void> _updateStaffStatus(int userId, String newStatus) async {
    final tenant = TenantService().currentTenant.value;
    
    // Find local index
    final index = _staffList.indexWhere((s) => int.parse(s['id'].toString()) == userId);
    if (index == -1) return;

    final oldStatus = _staffList[index]['status'];
    
    // Optimistic UI Update
    setState(() {
      _staffList[index]['status'] = newStatus;
    });

    bool success = false;
    if (tenant != null) {
      success = await ApiService.updateStaff({
        'user_id': userId,
        'status': newStatus,
      });
    } else {
      // In offline/demo mode, we assume success
      success = true;
    }

    if (!success && mounted) {
      // Rollback on failure
      setState(() {
        _staffList[index]['status'] = oldStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update status. Check connection."), backgroundColor: Colors.red));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account ${newStatus == 'Active' ? 'Activated' : 'Deactivated'} Successfully"), backgroundColor: newStatus == 'Active' ? Colors.green : Colors.orange));
    }
  }

  Future<void> _submitStaff() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required!")));
      return;
    }
    setState(() => _isSubmitting = true);
    String? uploadedUrl = _currentProfileUrl;
    if (_imageBytes != null && _imageFile != null) {
      uploadedUrl = await ApiService.uploadProfilePicture(_imageBytes!, _imageFile!.name);
    }
    bool success;
    if (_isEditing && _selectedStaff != null) {
      success = await ApiService.updateStaff({
        'user_id': _selectedStaff!['id'],
        'name': _nameController.text.trim(),
        'role': _selectedRole,
        'status': _currentStatus,
        'pin': _pinController.text.trim(),
        'salary_amount': _salaryController.text.trim(),
        'payment_cycle_days': _cycleController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'current_address': _currentAddrController.text.trim(),
        'permanent_address': _permanentAddrController.text.trim(),
        'citizenship_number': _citizenshipController.text.trim(),
        'document_url': _documentController.text.trim(),
        'profile_pic_url': uploadedUrl,
      });
    } else {
      final tenant = TenantService().currentTenant.value;
      success = await ApiService.addStaff({
        'tenant_id': tenant?.id,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'status': _currentStatus,
        'pin': _pinController.text.trim(),
        'salary_amount': _salaryController.text.trim(),
        'payment_cycle_days': _cycleController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'current_address': _currentAddrController.text.trim(),
        'permanent_address': _permanentAddrController.text.trim(),
        'citizenship_number': _citizenshipController.text.trim(),
        'document_url': _documentController.text.trim(),
        'profile_pic_url': uploadedUrl,
      });
    }
    setState(() => _isSubmitting = false);
    if (success && mounted) {
      _clearForm();
      setState(() {
        _isEditing = false;
        _isAdding = false;
        _selectedStaff = null;
      });
      _loadStaff();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? "Updated successfully!" : "Staff member registered!"), backgroundColor: Colors.green));
    } else if (mounted) {
      // Offline/Demo logic: Add to local list if API failed or tenant is null
      if (TenantService().currentTenant.value == null || !success) {
        final newStaff = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'pin': _pinController.text.trim(),
          'salary_amount': _salaryController.text.trim(),
          'payment_cycle_days': _cycleController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'current_address': _currentAddrController.text.trim(),
          'permanent_address': _permanentAddrController.text.trim(),
          'citizenship_number': _citizenshipController.text.trim(),
          'document_url': _documentController.text.trim(),
          'status': _currentStatus,
          'profile_pic_url': uploadedUrl,
        };
        setState(() {
          _staffList.add(newStaff);
          _isAdding = false;
          _isEditing = false;
          _clearForm();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to local directory (Offline Mode)"), backgroundColor: Colors.orange));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action failed. Check database or unique email."), backgroundColor: Colors.red));
      }
    }
  }

  List<Map<String, dynamic>> _getDemoData() {
    return [
      {'id': 1, 'name': 'Arbind Patel', 'email': 'arbind@restropro.com', 'role': 'Admin', 'phone_number': '+977-9801234567', 'salary_amount': 95000, 'status': 'Active', 'login_pin': '2024', 'current_address': 'Kathmandu, NP', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=1'},
      {'id': 2, 'name': 'Ram Bahadur', 'email': 'ram.chef@restropro.com', 'role': 'Head Chef', 'phone_number': '+977-9841000111', 'salary_amount': 55000, 'status': 'Active', 'login_pin': '1111', 'current_address': 'Lalitpur', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=2'},
      {'id': 3, 'name': 'Sita Thapa', 'email': 'sita.waiter@restropro.com', 'role': 'Waiter', 'phone_number': '+977-9851000222', 'salary_amount': 28000, 'status': 'Active', 'login_pin': '2222', 'current_address': 'Bhaktapur', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=3'},
      {'id': 4, 'name': 'Gita Kumari', 'email': 'gita.admin@restropro.com', 'role': 'Manager', 'phone_number': '+977-9861000333', 'salary_amount': 65000, 'status': 'Active', 'login_pin': '3333', 'current_address': 'Kathmandu', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=4'},
      {'id': 5, 'name': 'Santosh BK', 'email': 'santosh@restropro.com', 'role': 'Security', 'phone_number': '+977-9811000444', 'salary_amount': 24000, 'status': 'Active', 'login_pin': '4444', 'current_address': 'Pokhara', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=5'},
      {'id': 6, 'name': 'Nabina Rai', 'email': 'nabina.pastry@restropro.com', 'role': 'Kitchen', 'phone_number': '+977-9821000555', 'salary_amount': 38000, 'status': 'Active', 'login_pin': '5555', 'current_address': 'Dharan', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=6'},
      {'id': 7, 'name': 'Hari Kumar', 'email': 'hari.cashier@restropro.com', 'role': 'Cashier', 'phone_number': '+977-9831000666', 'salary_amount': 32000, 'status': 'Active', 'login_pin': '6666', 'current_address': 'Butwal', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=7'},
      {'id': 8, 'name': 'Maya Devi', 'email': 'maya.house@restropro.com', 'role': 'Cleaner', 'phone_number': '+977-9801000777', 'salary_amount': 22000, 'status': 'Inactive', 'login_pin': '7777', 'current_address': 'Hetauda', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=8'},
      {'id': 9, 'name': 'Kiran Magar', 'email': 'kiran.delivery@restropro.com', 'role': 'Waiter', 'phone_number': '+977-9811000888', 'salary_amount': 26000, 'status': 'Active', 'login_pin': '8888', 'current_address': 'Itahari', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=9'},
      {'id': 10, 'name': 'Pukar Shrestha', 'email': 'pukar.accounts@restropro.com', 'role': 'Admin', 'phone_number': '+977-9821000999', 'salary_amount': 55000, 'status': 'Active', 'login_pin': '9999', 'current_address': 'Biratnagar', 'payment_cycle_days': 30, 'profile_pic_url': 'https://i.pravatar.cc/150?u=10'},
    ];
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _pinController.clear();
    _phoneController.clear();
    _salaryController.text = "0.00";
    _cycleController.text = "30";
    _currentAddrController.clear();
    _permanentAddrController.clear();
    _citizenshipController.clear();
    _documentController.clear();
    _selectedRole = 'Waiter';
    _currentStatus = 'Active';
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _currentProfileUrl = null;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _deleteStaff(dynamic userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Remove Staff?"),
        content: Text("Are you sure you want to remove $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("REMOVE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final int uId = int.parse(userId.toString());
      final index = _staffList.indexWhere((s) => int.parse(s['id'].toString()) == uId);
      
      if (index != -1) {
        final removedStaff = _staffList[index];
        setState(() {
          _deletedStaffList.add({...removedStaff, 'deleted_at': DateTime.now().toIso8601String()});
          _staffList.removeAt(index);
        });
        
        // In real backend, you'd call soft delete API here
        await ApiService.deleteStaff(uId); 
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$name moved to Archive"),
              action: SnackBarAction(label: "UNDO", onPressed: () => _restoreStaff(uId)),
            )
          );
        }
      }
    }
  }

  Future<void> _restoreStaff(int userId) async {
    final index = _deletedStaffList.indexWhere((s) => int.parse(s['id'].toString()) == userId);
    if (index != -1) {
      final staff = _deletedStaffList[index];
      setState(() {
        _staffList.add(staff);
        _deletedStaffList.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Staff restored successfully"), backgroundColor: Colors.green));
    }
  }

  Future<void> _permanentlyDeleteStaff(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Permanent Delete?"),
        content: const Text("This action cannot be undone. All records will be wiped."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("DELETE FOREVER", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _deletedStaffList.removeWhere((s) => int.parse(s['id'].toString()) == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data wiped permanently")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(onPressed: () => setState(() => _isAdding = false), icon: const Icon(Icons.arrow_back)),
            _buildAddEmployeeForm(),
          ],
        ),
      );
    }
    if (_selectedStaff != null) {
      return _isEditing ? _buildEditForm() : _buildStaffDetails();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mode == "Add Employee") _buildAddEmployeeForm()
          else if (widget.mode == "Manage Employee") _buildManageEmployeeView()
          else if (widget.mode == "User Management") _buildUserManagementView()
          else if (widget.mode == "Attendance Form") _buildAttendanceForm()
          else if (widget.mode == "Attendance Report") _buildAttendanceReport()
          else if (widget.mode.contains("Salary")) _buildPayrollView()
          else _buildGenericEmployeeView(),
        ],
      ),
    );
  }

  Widget _buildUserManagementView() {
    final filteredList = _staffList.where((s) {
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        matchesSearch = (s['name']?.toString().toLowerCase().contains(q) ?? false) ||
               (s['role']?.toString().toLowerCase().contains(q) ?? false) ||
               (s['email']?.toString().toLowerCase().contains(q) ?? false);
      }

      bool matchesRole = true;
      if (_selectedFilterRole != null) {
        if (_selectedFilterRole == 'Total Users') {
          matchesRole = true;
        } else if (_selectedFilterRole == 'Active') {
          matchesRole = s['status'] == 'Active';
        } else if (_selectedFilterRole == 'Inactive') {
          matchesRole = s['status'] == 'Inactive';
        } else if (_selectedFilterRole == 'Admins') {
          matchesRole = s['role'] == 'Admin';
        } else if (_selectedFilterRole == 'Kitchen') {
          matchesRole = ['Kitchen', 'Chef', 'Head Chef'].contains(s['role']);
        }
      }

      return matchesSearch && matchesRole;
    }).toList();

    // Apply Display Limit
    final visibleList = _displayCount == -1 ? filteredList : filteredList.take(_displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User Management Control", 
                    style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                  Text("Manage credentials, roles and system access for ${_staffList.length} members", 
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _selectedFilterRole = null);
                      _loadStaff();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: isMobile ? const Text("R") : const Text("REFRESH"),
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _clearForm();
                      setState(() => _isAdding = true);
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: isMobile ? const Text("ADD") : const Text("ADD NEW"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5C00)),
                  ),
                ],
              ),
            ],
          );
        }),
        const SizedBox(height: 32),
        LayoutBuilder(builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 3 : 2);
          double aspectRatio = constraints.maxWidth > 800 ? 2.2 : 2.5;
          return GridView.count(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount, 
            crossAxisSpacing: 12, 
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
            children: [
              _buildSimpleStatCard("Total Users", (_staffList.length + _deletedStaffList.length).toString(), Icons.people_rounded, Colors.blue),
              _buildSimpleStatCard("Active", _staffList.where((e) => e['status'] == 'Active').length.toString(), Icons.check_circle_rounded, Colors.green),
              _buildSimpleStatCard("Inactive", _staffList.where((e) => e['status'] == 'Inactive').length.toString(), Icons.pause_circle_rounded, Colors.red),
              _buildSimpleStatCard("Admins", _staffList.where((e) => e['role'] == 'Admin').length.toString(), Icons.admin_panel_settings_rounded, Colors.orange),
              _buildSimpleStatCard("Kitchen", _staffList.where((e) => ['Kitchen', 'Chef', 'Head Chef'].contains(e['role'])).length.toString(), Icons.restaurant_rounded, Colors.purple),
              _buildSimpleStatCard("Archive", _deletedStaffList.length.toString(), Icons.delete_sweep_outlined, Colors.blueGrey),
            ],
          );
        }),
        if (_selectedFilterRole != null) Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Text("Showing: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              Chip(
                label: Text(_selectedFilterRole!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: AdminTheme.royalBlue,
                deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white),
                onDeleted: () => setState(() => _selectedFilterRole = null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: "Search users by name, role or email...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AdminTheme.royalBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow),
              child: DropdownButton<int>(
                value: _displayCount,
                underline: const SizedBox(),
                items: [5, 10, 20, 50, -1].map((int val) {
                  return DropdownMenuItem<int>(
                    value: val,
                    child: Text(val == -1 ? "Show All" : "Display $val", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _displayCount = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_isLoading) const Center(child: CircularProgressIndicator())
        else if (visibleList.isEmpty) const Center(child: Text("No users found matching your criteria."))
        else _buildResponsiveUserList(visibleList),
        
        if (_displayCount != -1 && filteredList.length > _displayCount) 
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() => _displayCount = -1),
                child: Text("VIEW ALL ${filteredList.length} MEMBERS", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        
        if (_deletedStaffList.isNotEmpty) ...[
          const SizedBox(height: 64),
          _buildDeletedListSection(),
        ],
      ],
    );
  }

  Widget _buildDeletedListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.archive_outlined, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            const Text("Archived Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _showDeleted = !_showDeleted),
              child: Text(_showDeleted ? "HIDE ARCHIVE" : "VIEW ARCHIVED (${_deletedStaffList.length})"),
            ),
          ],
        ),
        const Divider(),
        if (_showDeleted) ...[
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[200]!)),
                child: DataTable(
                  horizontalMargin: 0,
                  columns: const [
                    DataColumn(label: Text("NAME", style: TextStyle(color: Colors.grey))),
                    DataColumn(label: Text("PREVIOUS ROLE", style: TextStyle(color: Colors.grey))),
                    DataColumn(label: Text("ARCHIVED DATE", style: TextStyle(color: Colors.grey))),
                    DataColumn(label: Text("RESTORE / DELETE", style: TextStyle(color: Colors.grey))),
                  ],
                  rows: _deletedStaffList.map((s) => DataRow(cells: [
                    DataCell(Text(s['name'], style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough))),
                    DataCell(Text(s['role'], style: const TextStyle(color: Colors.grey))),
                    DataCell(Text(DateFormat('dd MMM yyyy').format(DateTime.parse(s['deleted_at'] ?? DateTime.now().toIso8601String())), style: const TextStyle(color: Colors.grey, fontSize: 11))),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.restore_from_trash_rounded, color: Colors.green), onPressed: () => _restoreStaff(int.parse(s['id'].toString())), tooltip: "Restore Staff"),
                        IconButton(icon: const Icon(Icons.delete_forever_rounded, color: Colors.red), onPressed: () => _permanentlyDeleteStaff(int.parse(s['id'].toString())), tooltip: "Delete Permanently"),
                      ],
                    )),
                  ])).toList(),
                ),
              );
            } else {
              return ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: _deletedStaffList.length,
                itemBuilder: (context, i) {
                  final s = _deletedStaffList[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(s['name'], style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                      subtitle: Text("Role: ${s['role']} • Removed recently", style: const TextStyle(fontSize: 10)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => _restoreStaff(int.parse(s['id'].toString()))),
                          IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _permanentlyDeleteStaff(int.parse(s['id'].toString()))),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          }),
        ],
      ],
    );
  }

  Widget _buildSimpleStatCard(String label, String val, IconData icon, Color color) {
    bool isSelected = _selectedFilterRole == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterRole = isSelected ? null : label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.05) : Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 2)] : AdminTheme.softShadow,
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.black)),
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveUserList(List<Map<String, dynamic>> users) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 900) {
        return Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 0, columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("EMPLOYEE", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("ROLE", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("EMAIL", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("PHONE", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("SALARY (NPR)", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: users.map((u) => DataRow(cells: [
                DataCell(Row(children: [CircleAvatar(radius: 16, backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), backgroundImage: (u['profile_pic_url'] != null && u['profile_pic_url'].isNotEmpty) ? NetworkImage(u['profile_pic_url']) : null, child: (u['profile_pic_url'] == null || u['profile_pic_url'].isEmpty) ? Text(u['name'][0]) : null), const SizedBox(width: 12), Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold))])),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Text(u['role'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Text(u['email'], style: const TextStyle(fontSize: 12))),
                DataCell(Text(u['phone_number'] ?? 'N/A', style: const TextStyle(fontSize: 12))),
                DataCell(Text(u['salary_amount']?.toString() ?? '0.00')),
                DataCell(_buildStatusBadge(u['status'] ?? "Active", userId: int.parse(u['id'].toString()))),
                DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), onPressed: () => setState(() => _selectedStaff = u)), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red), onPressed: () => _deleteStaff(u['id'], u['name']))])),
              ])).toList(),
            ),
          ),
        );
      } else {
        return ListView.separated(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final u = users[i];
            return Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AdminTheme.softShadow),
              child: Column(
                children: [
                  Row(children: [CircleAvatar(backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), child: Text(u['name'][0])), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(u['role'], style: const TextStyle(fontSize: 11, color: Colors.grey))])), _buildStatusBadge(u['status'] ?? "Active", userId: int.parse(u['id'].toString()))]),
                  const Divider(height: 24),
                  _buildMiniInfoRow(Icons.email_outlined, u['email']),
                  _buildMiniInfoRow(Icons.phone_android_outlined, u['phone_number'] ?? "N/A"),
                  _buildMiniInfoRow(Icons.payments_outlined, "Salary: NPR ${u['salary_amount']}"),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(onPressed: () => setState(() => _selectedStaff = u), icon: const Icon(Icons.visibility_outlined, size: 16), label: const Text("DETAILS")), const SizedBox(width: 8), OutlinedButton.icon(onPressed: () => _deleteStaff(u['id'], u['name']), icon: const Icon(Icons.delete_outline, size: 16), label: const Text("REMOVE"), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)))]),
                ],
              ),
            );
          },
        );
      }
    });
  }

  Widget _buildMiniInfoRow(IconData icon, String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87))]));
  }

  Widget _buildStaffDetails() {
    final s = _selectedStaff!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [IconButton(onPressed: () => setState(() => _selectedStaff = null), icon: const Icon(Icons.arrow_back)), const SizedBox(width: 16), const Text("Employee Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 32),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: AdminTheme.softShadow),
            child: Column(
              children: [
                CircleAvatar(radius: 50, backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), child: Text(s['name'][0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AdminTheme.royalBlue))),
                const SizedBox(height: 24),
                Text(s['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(s['role'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.email_outlined, "Login Email", s['email']),
                _buildDetailRow(Icons.lock_outline, "Security PIN", _isPinVisible ? (s['login_pin']?.toString() ?? 'N/A') : "****", trailing: IconButton(icon: Icon(_isPinVisible ? Icons.visibility_off : Icons.visibility, size: 18, color: AdminTheme.royalBlue), onPressed: () => setState(() => _isPinVisible = !_isPinVisible))),
                _buildDetailRow(Icons.phone_android_outlined, "Phone Number", s['phone_number'] ?? "N/A"),
                const Divider(),
                const SizedBox(height: 24),
                Row(children: [Expanded(child: _buildDetailRow(Icons.payments_outlined, "Monthly Salary", "NPR ${s['salary_amount'] ?? '0.00'}")), Expanded(child: _buildDetailRow(Icons.calendar_month_outlined, "Payment Cycle", "${s['payment_cycle_days'] ?? '30'} Days"))]),
                _buildDetailRow(Icons.badge_outlined, "Citizenship No.", s['citizenship_number'] ?? "N/A"),
                _buildDetailRow(Icons.location_on_outlined, "Current Address", s['current_address'] ?? "N/A"),
                _buildDetailRow(Icons.home_outlined, "Permanent Address", s['permanent_address'] ?? "N/A"),
                _buildDetailRow(Icons.description_outlined, "Document URL / Ref", s['document_url'] ?? "No documents linked"),
                _buildDetailRow(Icons.info_outline, "Account Status", s['status'] ?? "Active"),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () { setState(() { _nameController.text = s['name'] ?? ''; _emailController.text = s['email'] ?? ''; _pinController.text = s['login_pin']?.toString() ?? ''; _phoneController.text = s['phone_number'] ?? ''; _salaryController.text = s['salary_amount']?.toString() ?? '0.00'; _cycleController.text = s['payment_cycle_days']?.toString() ?? '30'; _currentAddrController.text = s['current_address'] ?? ''; _permanentAddrController.text = s['permanent_address'] ?? ''; _citizenshipController.text = s['citizenship_number'] ?? ''; _documentController.text = s['document_url'] ?? ''; _selectedRole = s['role']; _currentStatus = s['status'] ?? 'Active'; _currentProfileUrl = s['profile_pic_url']; _isEditing = true; }); }, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text("EDIT PROFILE"))),
                    const SizedBox(width: 16),
                    Expanded(child: ElevatedButton.icon(onPressed: () => _deleteStaff(s['id'], s['name']), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), icon: const Icon(Icons.delete_outline, size: 18), label: const Text("REMOVE STAFF"))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String val, {Widget? trailing}) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))])), if (trailing != null) trailing]));
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [IconButton(onPressed: () => setState(() => _isEditing = false), icon: const Icon(Icons.close)), const SizedBox(width: 16), const Text("Edit Team Member", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]), const SizedBox(height: 32), _buildAddEmployeeForm()]));
  }

  Widget _buildAddEmployeeForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800), padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEditing ? "Update Profile Details" : "Add New Team Member", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(_isEditing ? "Changes will take effect instantly." : "Create a detailed digital file for your employee.", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 32),
          Center(child: Stack(children: [CircleAvatar(radius: 50, backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : (_currentProfileUrl != null ? NetworkImage(_currentProfileUrl!) : null), child: (_imageBytes == null && _currentProfileUrl == null) ? const Icon(Icons.person_outline, size: 40, color: AdminTheme.royalBlue) : null), Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickImage, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AdminTheme.royalBlue, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white))))])),
          const SizedBox(height: 32),
          _buildFormHeader("1. Authentication & Role"),
          _buildTextField("Full Name", _nameController, hint: "e.g. Kiran Magar"),
          const SizedBox(height: 16),
          if (!_isEditing) _buildTextField("Email Address (Login ID)", _emailController, hint: "kiran@yourcafe.com") else Padding(padding: const EdgeInsets.only(bottom: 16), child: Text("Email: ${_emailController.text}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("System Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: _selectedRole, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: ['Waiter', 'Kitchen', 'Cashier', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => _selectedRole = v!))])), 
              const SizedBox(width: 16), 
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Account Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: _currentStatus, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _currentStatus = v!))])),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField("Login PIN (Numeric)", _pinController, hint: "4-6 digits"),
          const SizedBox(height: 40),
          _buildFormHeader("2. Financial Details"),
          Row(children: [Expanded(child: _buildTextField("Monthly Salary (NPR)", _salaryController, hint: "e.g. 25000")), const SizedBox(width: 16), Expanded(child: _buildTextField("Payment Cycle (Days)", _cycleController, hint: "e.g. 30"))]),
          const SizedBox(height: 40),
          _buildFormHeader("3. Personal Information"),
          _buildTextField("Contact Phone Number", _phoneController, hint: "98XXXXXXXX"),
          const SizedBox(height: 16),
          _buildTextField("Citizenship / ID Number", _citizenshipController, hint: "Reg. No / Passport No"),
          const SizedBox(height: 16),
          _buildTextField("Current Residence Address", _currentAddrController, hint: "Street, City"),
          const SizedBox(height: 16),
          _buildTextField("Permanent / Home Address", _permanentAddrController, hint: "District, Region"),
          const SizedBox(height: 16),
          _buildTextField("Document / File Link", _documentController, hint: "Google Drive / Dropbox Link"),
          const SizedBox(height: 48),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSubmitting ? null : _submitStaff, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5C00), padding: const EdgeInsets.symmetric(vertical: 18)), child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isEditing ? "SAVE PROFILE CHANGES" : "REGISTER STAFF MEMBER"))),
        ],
      ),
    );
  }

  Widget _buildFormHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminTheme.royalBlue, letterSpacing: 1)), const Divider()]));
  }

  Widget _buildManageEmployeeView() {
    final filteredList = _staffList.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (s['name']?.toString().toLowerCase().contains(q) ?? false) || (s['role']?.toString().toLowerCase().contains(q) ?? false) || (s['email']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Team Directory", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("Total Team: ${_staffList.length} Members • ID: ${TenantService().currentTenant.value?.id}", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 0.5))]), IconButton(onPressed: _loadStaff, icon: const Icon(Icons.refresh, color: AdminTheme.royalBlue))]),
        const SizedBox(height: 24),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: "Search by Name, Role or Email...", hintStyle: const TextStyle(fontSize: 13, color: Colors.grey), prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.royalBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16)))),
        const SizedBox(height: 32),
        if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) else if (_staffList.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No staff members found in database."))) else if (filteredList.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No members match your search."))) else ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredList.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) { final s = filteredList[index]; return _buildEmployeeRow(s); }),
      ],
    );
  }

  Widget _buildEmployeeRow(Map<String, dynamic> s) {
    return Material(color: Colors.transparent, child: InkWell(onTap: () { setState(() { _selectedStaff = s; _isEditing = false; }); }, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AdminTheme.softShadow, border: Border.all(color: Colors.grey[100]!)), child: Row(children: [CircleAvatar(backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), backgroundImage: (s['profile_pic_url'] != null && s['profile_pic_url'].isNotEmpty) ? NetworkImage(s['profile_pic_url']) : null, child: (s['profile_pic_url'] == null || s['profile_pic_url'].isEmpty) ? Text((s['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AdminTheme.royalBlue, fontWeight: FontWeight.bold)) : null), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text("${s['role']} • ${s['email']}", style: const TextStyle(color: Colors.grey, fontSize: 11))])), const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey)]))));
  }

  Widget _buildGenericEmployeeView() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_outline, size: 48, color: Colors.grey), SizedBox(height: 16), Text("Select 'Manage Employee' to see real data.", style: TextStyle(color: Colors.grey))]));
  }

  Widget _buildAttendanceForm() {
    final now = DateTime.now();
    // Only show ACTIVE staff for attendance
    final activeStaff = _staffList.where((s) => s['status'] == 'Active').toList();
    
    final remainingStaff = activeStaff.where((s) => !_completedToday.contains(int.parse(s['id'].toString())) || _pendingSaves.containsKey(int.parse(s['id'].toString())) || _successSaves.contains(int.parse(s['id'].toString()))).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Daily Attendance", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("Today: ${now.day} ${_months[now.month-1]} ${now.year} • ${activeStaff.length - _completedToday.length} Pending", style: const TextStyle(fontSize: 11, color: AdminTheme.royalBlue, fontWeight: FontWeight.bold))]), IconButton(onPressed: _loadStaff, icon: const Icon(Icons.refresh, color: AdminTheme.royalBlue))]),
        const SizedBox(height: 32),
        if (_isLoading) const Center(child: CircularProgressIndicator()) else if (activeStaff.isEmpty) const Center(child: Text("No active employees found for attendance.")) else if (activeStaff.length == _completedToday.length && _successSaves.isEmpty && _pendingSaves.isEmpty) Center(child: Column(children: [const Icon(Icons.check_circle_outline, color: Colors.green, size: 64), const SizedBox(height: 16), const Text("Excellent! All active staff marked for today.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 16), OutlinedButton(onPressed: _loadStaff, child: const Text("FORCE REFRESH"))])) else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: remainingStaff.length, itemBuilder: (context, index) { final s = remainingStaff[index]; final int userId = int.parse(s['id'].toString()); if (_successSaves.contains(userId)) return _buildSuccessCard(s['name']); if (_pendingSaves.containsKey(userId)) return _buildSavingCard(userId, s['name'], _pendingSaves[userId]!); return _buildNormalAttendanceCard(s, userId); }),
      ],
    );
  }

  Widget _buildNormalAttendanceCard(Map<String, dynamic> s, int userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
      child: Column(children: [Row(children: [CircleAvatar(radius: 20, backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), backgroundImage: (s['profile_pic_url'] != null && s['profile_pic_url'].isNotEmpty) ? NetworkImage(s['profile_pic_url']) : null, child: (s['profile_pic_url'] == null || s['profile_pic_url'].isEmpty) ? Text(s['name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.royalBlue, fontSize: 12)) : null), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(s['role'] ?? 'Role', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))]))]), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStatusBtn(userId, "P", "Present", s['name']), _buildStatusBtn(userId, "A", "Absent", s['name']), _buildStatusBtn(userId, "HL", "Half", s['name']), _buildStatusBtn(userId, "NIA", "Un-Inf", s['name']), _buildStatusBtn(userId, "UA", "Use-Ab", s['name'])])]),
    );
  }

  Widget _buildSavingCard(int userId, String name, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: AdminTheme.royalBlue.withValues(alpha: 0.2))),
      child: Row(children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.royalBlue)), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Saving $name as $status...", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.royalBlue)), const Text("Writing to database in 4 seconds", style: TextStyle(fontSize: 10, color: Colors.grey))])), TextButton(onPressed: () => _cancelAttendance(userId), child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)))]),
    );
  }

  Widget _buildSuccessCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.green.withValues(alpha: 0.2))),
      child: Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 24), const SizedBox(width: 20), Expanded(child: Text("Attendance Marked for $name Successfully!", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)))]),
    );
  }

  Widget _buildStatusBtn(int userId, String code, String label, String name) {
    bool isSelected = _attendanceMap[userId] == code;
    Color color = _getStatusColor(code);
    bool isProcessing = _pendingSaves.containsKey(userId);
    return InkWell(
      onTap: isProcessing ? null : () => _handleAttendanceClick(userId, code, name),
      borderRadius: BorderRadius.circular(12),
      child: Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isSelected ? color : Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? color : Colors.grey[200]!)), child: Column(children: [Text(code, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 2), Text(label, style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 8, fontWeight: FontWeight.bold))])),
    );
  }

  Color _getStatusColor(String code) {
    switch (code) {
      case "P": return Colors.green;
      case "A": return Colors.red;
      case "HL": return Colors.orange;
      case "NIA": return Colors.deepPurple;
      case "UA": return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  Widget _buildAttendanceReport() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_individualStats != null || _isLoadingIndividual) return _buildIndividualDashboard();
    final stats = _analyticsData?['stats'];
    final filteredReport = _reportData.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (r['name']?.toString().toLowerCase().contains(q) ?? false) || (r['date']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 24),
          Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: "Search staff or date...", hintStyle: const TextStyle(fontSize: 13, color: Colors.grey), prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.royalBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16)))),
          const SizedBox(height: 32),
          Row(children: [Expanded(child: _buildStatCard("Total Staff", "${stats?['total_staff'] ?? '0'}", Icons.people_outline, Colors.blue)), const SizedBox(width: 12), Expanded(child: _buildStatCard("Present Today", "${stats?['present_today'] ?? '0'}", Icons.check_circle_outline, Colors.green))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _buildStatCard("Absent Today", "${stats?['absent_today'] ?? '0'}", Icons.cancel_outlined, Colors.red)), const SizedBox(width: 12), Expanded(child: _buildStatCard("Peak Visitors", "0", Icons.analytics_outlined, Colors.purple))]),
          const SizedBox(height: 32),
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Staff Attendance Trends", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 24), SizedBox(height: 200, child: BarChart(BarChartData(barGroups: _getBarGroups(), borderData: FlBorderData(show: false), titlesData: const FlTitlesData(show: false), gridData: const FlGridData(show: false), alignment: BarChartAlignment.spaceAround, maxY: (_staffList.isEmpty ? 10 : _staffList.length * 1.2).toDouble()))), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegendItem("Presents", AdminTheme.royalBlue), const SizedBox(width: 20), _buildLegendItem("Absents", Colors.redAccent)])])),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Attendance Logs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text("${filteredReport.length} Records", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          if (filteredReport.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No data found."))) else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredReport.length, itemBuilder: (context, index) { final r = filteredReport[index]; return _buildAttendanceListItem(r); }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))]);
  }

  List<BarChartGroupData> _getBarGroups() {
    if (_analyticsData == null || _analyticsData!['chart_data'] == null || (_analyticsData!['chart_data'] as List).isEmpty) {
      return List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: 0, color: AdminTheme.royalBlue, width: 8)]));
    }
    final List data = _analyticsData!['chart_data'];
    Map<String, List<int>> daily = {};
    for (var row in data) {
      if (row == null || row['date'] == null) continue;
      String date = row['date'];
      if (!daily.containsKey(date)) daily[date] = [0, 0];
      int count = int.tryParse(row['count']?.toString() ?? '0') ?? 0;
      if (['P', 'HL'].contains(row['status'])) { daily[date]![0] += count; } else { daily[date]![1] += count; }
    }
    int i = 0;
    return daily.entries.take(7).map((e) => BarChartGroupData(x: i++, barRods: [BarChartRodData(toY: e.value[0].toDouble(), color: AdminTheme.royalBlue, width: 8, borderRadius: BorderRadius.circular(2)), BarChartRodData(toY: e.value[1].toDouble(), color: Colors.redAccent, width: 8, borderRadius: BorderRadius.circular(2))])).toList();
  }

  Widget _buildDashboardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Analytics Dashboard", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("Data-driven staff discipline tracking", style: TextStyle(color: Colors.grey, fontSize: 11))]),
        Row(children: [IconButton(onPressed: _loadReport, icon: const Icon(Icons.refresh, color: AdminTheme.royalBlue, size: 20)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), child: DropdownButton<String>(value: _selectedRange, underline: const SizedBox(), items: ['Day', 'Week', 'Month', 'Year'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { setState(() => _selectedRange = v!); _loadReport(); }))]),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AdminTheme.softShadow), child: Row(children: [CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))])]));
  }

  Widget _buildAttendanceListItem(Map<String, dynamic> r) {
    final status = r['status'] ?? '?';
    final color = _getStatusColor(status);
    return InkWell(
      onTap: () => _loadIndividualStats(int.parse(r['user_id'].toString())),
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow), child: Row(children: [CircleAvatar(radius: 18, backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), child: Text(r['name'][0])), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(r['date'], style: const TextStyle(fontSize: 10, color: Colors.grey))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)))])),
    );
  }

  Widget _buildIndividualDashboard() {
    if (_isLoadingIndividual) return const Center(child: CircularProgressIndicator());
    final d = _individualStats;
    
    // Fallback for Demo Mode / Offline
    final user = (d != null && d['user'] != null) ? d['user'] : (_selectedStaff ?? {});
    final stats = (d != null && d['stats'] != null) ? d['stats'] : {
      'present': 24,
      'absent': 2,
      'hl_raw': 1,
      'nia': 1,
      'leave': 2
    };

    final double baseSalary = double.tryParse(user['salary_amount']?.toString() ?? '0') ?? 0;
    final int cycleDays = int.tryParse(user['payment_cycle_days']?.toString() ?? '30') ?? 30;
    final double dailyRate = cycleDays > 0 ? baseSalary / cycleDays : 0;
    double presentCount = double.tryParse(stats['present']?.toString() ?? '0') ?? 0;
    final double earnedSalary = presentCount * dailyRate;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() { _individualStats = null; _selectedStaff = null; }), icon: const Icon(Icons.arrow_back)),
              const Text("Employee Full Analytics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, 
            padding: const EdgeInsets.all(32), 
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AdminTheme.royalBlue, AdminTheme.darkNavy]), 
              borderRadius: BorderRadius.circular(32)
            ), 
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36, 
                      backgroundColor: Colors.white.withValues(alpha: 0.2), 
                      backgroundImage: (user['profile_pic_url'] != null && user['profile_pic_url'].isNotEmpty) ? NetworkImage(user['profile_pic_url']) : null, 
                      child: (user['profile_pic_url'] == null || user['profile_pic_url'].isEmpty) ? Text(user['name'] != null ? user['name'][0].toUpperCase() : 'U', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)) : null
                    ), 
                    const SizedBox(width: 20), 
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text(user['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), 
                          Text(user['role']?.toString().toUpperCase() ?? 'STAFF', style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold))
                        ]
                      )
                    ), 
                    _buildIndiBadge(user['status'] ?? "ACTIVE", user['status'] == "Active" ? Colors.green : Colors.red)
                  ]
                ), 
                const SizedBox(height: 32), 
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _buildIndiStat("PRESENT", "${stats['present'] ?? 0}"), 
                    _buildIndiStat("ABSENT", "${stats['absent'] ?? 0}"), 
                    _buildIndiStat("LEAVES", "${stats['leave'] ?? 0}"),
                    _buildIndiStat("HALF DAY", "${stats['hl_raw'] ?? 0}"), 
                    _buildIndiStat("UN-INFORMED", "${stats['nia'] ?? 0}")
                  ]
                )
              ]
            )
          ),
          const SizedBox(height: 32),
          LayoutBuilder(builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return isDesktop 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFinancialSummary(baseSalary, cycleDays, presentCount, earnedSalary)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildAttendanceHistory(d)),
                  ],
                )
              : Column(
                  children: [
                    _buildFinancialSummary(baseSalary, cycleDays, presentCount, earnedSalary),
                    const SizedBox(height: 24),
                    _buildAttendanceHistory(d),
                  ],
                );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(double baseSalary, int cycleDays, double presentCount, double earnedSalary) {
    return Container(
      padding: const EdgeInsets.all(24), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("Monthly Settlement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
              const Icon(Icons.account_balance_wallet_outlined, color: AdminTheme.royalBlue, size: 20)
            ]
          ), 
          const SizedBox(height: 24), 
          _buildSalaryRow("Base Monthly Salary", "NPR ${baseSalary.toStringAsFixed(0)}"), 
          _buildSalaryRow("Cycle Days", "$cycleDays Days"), 
          _buildSalaryRow("Days Attended (Net)", "$presentCount"), 
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("TOTAL EARNED", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 10, letterSpacing: 1)), 
              Text("NPR ${earnedSalary.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AdminTheme.emeraldGreen))
            ]
          ), 
          const SizedBox(height: 24), 
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AdminTheme.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("RELEASE PAYMENT", style: TextStyle(fontWeight: FontWeight.bold)))
        ]
      )
    );
  }

  Widget _buildAttendanceHistory(Map<String, dynamic>? d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Attendance History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AdminTheme.darkNavy)),
        const SizedBox(height: 16),
        if (d == null || d['history'] == null || (d['history'] as List).isEmpty) 
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No detailed logs found for this month."))) 
        else ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(), 
          itemCount: (d['history'] as List).length, 
          itemBuilder: (context, index) { 
            final h = d['history'][index]; 
            final color = _getStatusColor(h['status'] ?? '?'); 
            return Container(
              margin: const EdgeInsets.only(bottom: 12), 
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow), 
              child: ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.calendar_today, color: color, size: 14)), 
                title: Text(h['date'] ?? 'Unknown Date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(h['status'] ?? '?', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)))
              )
            ); 
          }
        ),
      ],
    );
  }

  Widget _buildIndiBadge(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)));
  }

  Widget _buildIndiStat(String label, String val) {
    return Column(children: [Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold))]);
  }

  Widget _buildSalaryRow(String label, String val) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]));
  }

  Widget _buildPayrollView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Payroll & Salary Hub", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("Live cycle tracking and payment estimations.", style: TextStyle(color: Colors.grey, fontSize: 11))]), IconButton(onPressed: _loadStaff, icon: const Icon(Icons.refresh, color: AdminTheme.royalBlue))]),
        const SizedBox(height: 32),
        if (_staffList.isEmpty) const Center(child: Text("No staff data found.")) else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _staffList.length, itemBuilder: (context, index) { final s = _staffList[index]; final double salary = double.tryParse(s['salary_amount']?.toString() ?? '0') ?? 0; final int cycle = int.tryParse(s['payment_cycle_days']?.toString() ?? '30') ?? 30; DateTime joinDate = DateTime.tryParse(s['created_at']?.toString() ?? '') ?? DateTime.now(); final now = DateTime.now(); final daysSinceJoining = now.difference(joinDate).inDays; final daysPassed = daysSinceJoining % cycle; final daysRemaining = cycle - daysPassed; final double progress = daysPassed / cycle; return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow, border: Border.all(color: Colors.grey[100]!)), child: Column(children: [Row(children: [CircleAvatar(radius: 24, backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), backgroundImage: (s['profile_pic_url'] != null && s['profile_pic_url'].isNotEmpty) ? NetworkImage(s['profile_pic_url']) : null, child: (s['profile_pic_url'] == null || s['profile_pic_url'].isEmpty) ? Text(s['name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)) : null), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(s['role'] ?? 'Employee', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text("P", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)))]), const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPayrollStat("DATE", "${now.day} ${_months[now.month-1]} ${now.year}"), _buildPayrollStat("STATUS", "Active Cycle", isStatus: true), _buildPayrollStat("SALARY", "NPR ${salary.toStringAsFixed(0)}")]), const SizedBox(height: 24), Row(children: [Stack(alignment: Alignment.center, children: [SizedBox(height: 60, width: 60, child: CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: Colors.grey[100], color: AdminTheme.royalBlue)), Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Day $daysPassed of $cycle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text("$daysRemaining days until next payment", style: const TextStyle(color: Colors.grey, fontSize: 11))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("EST. PAYOUT", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)), Text("NPR ${salary.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue, fontSize: 18))])])])); }),
      ],
    );
  }

  Widget _buildPayrollStat(String label, String val, {bool isStatus = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)), const SizedBox(height: 4), Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isStatus ? Colors.green : Colors.black))]);
  }

  Widget _buildStatusBadge(String status, {int? userId}) {
    Color color = status == "Active" ? AdminTheme.emeraldGreen : Colors.redAccent;
    return MouseRegion(
      cursor: userId != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: userId != null ? () => _updateStaffStatus(userId, status == "Active" ? "Inactive" : "Active") : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))), 
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)), const SizedBox(height: 8), TextField(controller: controller, decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))]);
  }
}
