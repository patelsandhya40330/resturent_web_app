import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/tenant_service.dart';
import '../admin_theme.dart';

class TableConfigurationScreen extends StatefulWidget {
  final String mode;
  final String? filterType; // "Table" or "Room"
  const TableConfigurationScreen({super.key, required this.mode, this.filterType});

  @override
  State<TableConfigurationScreen> createState() => _TableConfigurationScreenState();
}

class _TableConfigurationScreenState extends State<TableConfigurationScreen> {
  // Main Data Source for Demo
  final List<Map<String, dynamic>> _tables = [
    {'id': '1', 'table_number': '01', 'type': 'Table', 'capacity': 2, 'status': 'Available', 'area': 'Main Hall', 'last_cleaned': '5m ago', 'is_visible': true, 'is_reservable': true, 'is_near_window': false},
    {'id': '2', 'table_number': '02', 'type': 'Table', 'capacity': 4, 'status': 'Occupied', 'area': 'Main Hall', 'last_cleaned': '1h ago', 'is_visible': true, 'is_reservable': true, 'is_near_window': true},
    {'id': '3', 'table_number': '101', 'type': 'Room', 'capacity': 8, 'status': 'Available', 'area': 'VIP Wing', 'last_cleaned': '15m ago', 'is_visible': true, 'is_reservable': true, 'is_near_window': false},
    {'id': '4', 'table_number': '05', 'type': 'Table', 'capacity': 3, 'status': 'Cleaning', 'area': 'Terrace', 'last_cleaned': '2h ago', 'is_visible': false, 'is_reservable': false, 'is_near_window': true},
    {'id': '5', 'table_number': '10', 'type': 'Table', 'capacity': 4, 'status': 'Available', 'area': 'Terrace', 'last_cleaned': '10m ago', 'is_visible': true, 'is_reservable': true, 'is_near_window': true},
    {'id': '6', 'table_number': '201', 'type': 'Room', 'capacity': 6, 'status': 'Occupied', 'area': 'VIP Wing', 'last_cleaned': '45m ago', 'is_visible': true, 'is_reservable': true, 'is_near_window': false},
    {'id': '7', 'table_number': 'VIP-2', 'type': 'Room', 'capacity': 4, 'status': 'Cleaning', 'area': 'VIP Wing', 'last_cleaned': 'Yesterday', 'is_visible': false, 'is_reservable': false, 'is_near_window': false},
  ];

  final List<Map<String, dynamic>> _areas = [
    {'name': 'Main Hall', 'type': 'Default', 'surcharge': '0', 'isActive': true, 'icon': Icons.storefront},
    {'name': 'VIP Wing', 'type': 'Premium', 'surcharge': '10', 'isActive': true, 'icon': Icons.stars},
    {'name': 'Terrace', 'type': 'Outdoor', 'surcharge': '5', 'isActive': true, 'icon': Icons.wb_sunny_outlined},
  ];

  String _searchQuery = "";
  int _rowsPerPage = 10;
  String _statusFilter = "All";
  String _areaFilter = "All Areas";
  bool? _reservableFilter;
  bool? _nearWindowFilter;
  bool? _mergableFilter;
  late DateTime _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _lastSyncTime = DateTime.now();
  }

  void _refreshData() {
    setState(() {
      _lastSyncTime = DateTime.now();
    });
    _showToast("Data synchronized with server.");
  }

  List<Map<String, dynamic>> get _filteredByRole => widget.filterType == null 
      ? _tables 
      : _tables.where((t) => t['type'] == widget.filterType).toList();

  List<Map<String, dynamic>> get _finalFilteredList {
    var list = _filteredByRole;
    
    // 1. Status Filter
    if (_statusFilter != "All") {
      list = list.where((t) {
        String itemStatus = (t['status'] ?? "Available").toString().toUpperCase();
        return itemStatus == _statusFilter.toUpperCase();
      }).toList();
    }
    
    // 2. Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((t) => t['table_number'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // 3. Advanced Filter: Area
    if (_areaFilter != "All Areas") {
      list = list.where((t) => (t['area'] ?? "").toString().toLowerCase().contains(_areaFilter.toLowerCase())).toList();
    }

    // 5. Advanced Filter: Reservable
    if (_reservableFilter != null) {
      list = list.where((t) => t['is_reservable'] == _reservableFilter).toList();
    }

    // 6. Advanced Filter: Near Window
    if (_nearWindowFilter != null) {
      list = list.where((t) => t['is_near_window'] == _nearWindowFilter).toList();
    }

    // 7. Advanced Filter: Mergable
    if (_mergableFilter != null) {
      list = list.where((t) => t['is_mergable'] == _mergableFilter).toList();
    }

    return list;
  }

  void _toggleAvailability(Map<String, dynamic> item) {
    setState(() {
      if (item['status'] == 'Available') {
        item['status'] = 'Cleaning';
        item['is_visible'] = false;
      } else {
        item['status'] = 'Available';
        item['is_visible'] = true;
      }
    });
    _showToast("${item['table_number']} status updated to ${item['status']}");
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: isError ? Colors.redAccent : AdminTheme.royalBlue, 
        duration: const Duration(seconds: 2)
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Occupied': return Colors.red;
      case 'Cleaning': return Colors.orange;
      case 'Hidden': return Colors.grey;
      default: return Colors.blue;
    }
  }

  // --- FULLY WORKABLE ACTIONS ---

  Future<void> _addItem({Map<String, dynamic>? existingItem}) async {
    final nameController = TextEditingController(text: existingItem?['table_number']?.toString());
    final capacityController = TextEditingController(text: existingItem?['capacity']?.toString() ?? "2");
    final statusController = TextEditingController(text: existingItem?['status'] ?? "Available");
    
    // Auto-detect type based on filter context
    String type = existingItem?['type'] ?? (widget.filterType ?? "Table");
    
    String area = existingItem?['area'] ?? "Main Hall";
    bool isVisible = existingItem?['is_visible'] ?? true;
    bool isEditing = existingItem != null;
    
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(isEditing ? "Update Detail" : "Add New $type", style: const TextStyle(fontWeight: FontWeight.w900)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Unit Selection Toggle - Only show if not filtered
                    if (widget.filterType == null)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text("TABLE")),
                                selected: type == "Table",
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      type = "Table";
                                      nameController.clear();
                                    });
                                  }
                                },
                                selectedColor: AdminTheme.royalBlue.withValues(alpha: 0.2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text("ROOM")),
                                selected: type == "Room",
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      type = "Room";
                                      nameController.clear();
                                    });
                                  }
                                },
                                selectedColor: Colors.orange.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (widget.filterType == null) const SizedBox(height: 24),
                    
                    // Manual Input Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Identifier ($type No.)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "Type or select from list...",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.edit_note, size: 18),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    _buildPopupInput("Capacity", "e.g. 4", capacityController, Icons.groups_outlined, isNumber: true),

                    const SizedBox(height: 16),
                    // Unified Visibility & Status Logic
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Custom App Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: statusController,
                          decoration: InputDecoration(
                            hintText: "Enter status name (Available, Occupied...)",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            suffixIcon: PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                              onSelected: (val) {
                                setModalState(() {
                                  statusController.text = val;
                                  if (val == "Hidden") {
                                    isVisible = false;
                                  } else {
                                    isVisible = true;
                                  }
                                });
                              },
                              itemBuilder: (context) => ["Available", "Occupied", "Cleaning", "Hidden", "Maintenance", "Reserved"]
                                .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                            ),
                          ),
                          onChanged: (val) {
                            if (val == "Hidden") {
                              isVisible = false;
                            } else {
                              isVisible = true;
                            }
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) {
                      _showToast("Please provide an identifier", isError: true);
                      return;
                    }
                    
                    setState(() {
                      if (isEditing) {
                        int index = _tables.indexWhere((e) => e['id'] == existingItem['id']);
                        if (index != -1) {
                          _tables[index] = {
                            ..._tables[index],
                            'table_number': nameController.text,
                            'type': type,
                            'area': area,
                            'status': statusController.text,
                            'is_visible': isVisible,
                            'capacity': int.tryParse(capacityController.text) ?? 2,
                          };
                        }
                      } else {
                        _tables.add({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'table_number': nameController.text,
                          'type': type,
                          'area': area,
                          'is_visible': isVisible,
                          'status': statusController.text,
                          'capacity': int.tryParse(capacityController.text) ?? 2,
                          'last_cleaned': 'Just now',
                        });
                      }
                    });
                    Navigator.pop(ctx);
                    String msg = isEditing ? "Updated successfully" : "Added successfully";
                    _showToast(msg);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.royalBlue, 
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isEditing ? "UPDATE" : "SAVE ITEM", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    );
  }

  void _showQRCodeDialog(Map<String, dynamic> item) {
    final tenant = TenantService().currentTenant.value;
    if (tenant == null) {
      _showToast("Tenant data not loaded. Cannot generate QR.", isError: true);
      return;
    }

    String domain = tenant.domain.isNotEmpty ? tenant.domain : "startupsgo.tech";
    String tableNum = item['table_number'].toString();
    String qrData = "https://$domain/?table=$tableNum";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: 420,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 10),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stylized Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: widget.filterType == "Room" ? Colors.orange.shade800 : AdminTheme.royalBlue,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        widget.filterType == "Room" ? Icons.cabin_rounded : Icons.table_restaurant_rounded, 
                        color: Colors.white, 
                        size: 48
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${item['type']} $tableNum".toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "AREA: ${item['area'] ?? 'General'}",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // QR Code Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
                          ],
                          border: Border.all(color: Colors.grey.shade100, width: 2),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 220.0,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square, 
                            color: widget.filterType == "Room" ? Colors.orange.shade900 : AdminTheme.darkNavy
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square, 
                            color: widget.filterType == "Room" ? Colors.orange.shade700 : AdminTheme.royalBlue
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text(
                        "SCAN TO ORDER",
                        style: TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy, letterSpacing: 2, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Point your camera at this QR code to access the $domain digital menu for ${item['type']} $tableNum.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                      ),
                      
                      const SizedBox(height: 32),
                      // Action Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: qrData));
                                _showToast("Link copied to clipboard!");
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text("COPY LINK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showToast("Downloading QR Image..."),
                              icon: const Icon(Icons.file_download_outlined, size: 16),
                              label: const Text("DOWNLOAD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.filterType == "Room" ? Colors.orange.shade800 : AdminTheme.royalBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("DISMISS", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
                
                // Footer Branding
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome, 
                          size: 12, 
                          color: widget.filterType == "Room" ? Colors.orange : AdminTheme.royalBlue
                        ),
                        const SizedBox(width: 8),
                        Text("POWERED BY CHIYABREAK SAAS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Confirmation", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove '${item['table_number']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() => _tables.removeWhere((e) => e['id'] == item['id']));
              Navigator.pop(ctx);
              _showToast("Item removed successfully", isError: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(),
          const SizedBox(height: 24),
          _buildFilterBar(),
          const SizedBox(height: 32),
          if (widget.mode == "Table List" || widget.mode == "Room List") 
            _buildProfessionalTableListView()
          else 
            _buildGenericConfigView(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final contextItems = _filteredByRole;
    
    // Calculate counts for each unique status dynamically
    Map<String, int> counts = {"ALL": contextItems.length};
    for (var t in contextItems) {
      String s = (t['status'] ?? "Available").toUpperCase();
      counts[s] = (counts[s] ?? 0) + 1;
    }

    // Define standard order and then add any other custom ones
    List<String> order = ["ALL", "AVAILABLE", "OCCUPIED", "CLEANING", "HIDDEN"];
    for (var k in counts.keys) {
      if (!order.contains(k)) order.add(k);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...order.map((status) {
            int count = counts[status] ?? 0;
            // The value stored in state is CamelCase, but we display UPPERCASE (COUNT)
            String filterValue = status == "ALL" ? "All" : 
                                status[0] + status.substring(1).toLowerCase();
            
            // Adjust for manual typing mismatch if any
            if (status == "AVAILABLE") filterValue = "Available";
            if (status == "OCCUPIED") filterValue = "Occupied";
            if (status == "CLEANING") filterValue = "Cleaning";
            if (status == "HIDDEN") filterValue = "Hidden";

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildFilterChip(filterValue, label: "$status ($count)"),
            );
          }),
          IconButton(
            onPressed: _refreshData, 
            icon: const Icon(Icons.sync_rounded, size: 22, color: AdminTheme.royalBlue)
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, {String? label}) {
    bool isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text((label ?? value).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
      selected: isSelected,
      onSelected: (v) => setState(() => _statusFilter = value),
      selectedColor: AdminTheme.royalBlue,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AdminTheme.royalBlue : Colors.grey.shade200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      showCheckmark: false,
    );
  }

  Widget _buildSummaryHeader() {
    final contextItems = _filteredByRole;
    
    // Dynamically calculate counts for ALL unique statuses
    Map<String, int> counts = {};
    for (var t in contextItems) {
      String s = t['status'] ?? "Available";
      counts[s] = (counts[s] ?? 0) + 1;
    }

    // Sort order: Available, Occupied, Cleaning, then others
    List<String> priority = ["Available", "Occupied", "Cleaning", "Hidden"];
    List<String> sortedStatuses = [];
    
    for (var p in priority) {
      if (counts.containsKey(p)) sortedStatuses.add(p);
    }
    for (var k in counts.keys) {
      if (!priority.contains(k)) sortedStatuses.add(k);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard("TOTAL ${widget.filterType?.toUpperCase() ?? 'ITEMS'}", contextItems.length.toString(), Icons.inventory_2_outlined, AdminTheme.royalBlue),
          ...sortedStatuses.map((status) {
            return Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _buildStatCard(
                status.toUpperCase(), 
                counts[status].toString(), 
                _getStatusIcon(status), 
                _getStatusColor(status)
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Available': return Icons.check_circle_outline;
      case 'Occupied': return Icons.person_outline;
      case 'Cleaning': return Icons.cleaning_services_outlined;
      case 'Hidden': return Icons.visibility_off_outlined;
      default: return Icons.stars_outlined;
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminTheme.softShadow,
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTableListView() {
    final filteredItems = _finalFilteredList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Breadcrumb Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AdminTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (widget.filterType == "Room" ? Colors.orange : Colors.green).withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(
                  widget.filterType == "Room" ? Icons.door_front_door_outlined : Icons.table_bar_outlined, 
                  color: widget.filterType == "Room" ? Colors.orange : Colors.green, 
                  size: 28
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.filterType == "Room" ? "Room Layout" : "Restaurant Layout", 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)
                  ),
                  Text(
                    widget.filterType == "Room" ? "Manage Private Rooms and Cabins" : "Manage Tables and Main Dining Area", 
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Data Management Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AdminTheme.softShadow,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildExportButton("Export CSV", Icons.file_download_outlined),
                      const SizedBox(width: 16),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.only(left: 14, right: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50], 
                          borderRadius: BorderRadius.circular(10), 
                          border: Border.all(color: Colors.grey.shade200)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("DISPLAY: ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                            IntrinsicWidth(
                              child: TextField(
                                controller: TextEditingController(text: _rowsPerPage.toString())..selection = TextSelection.collapsed(offset: _rowsPerPage.toString().length),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AdminTheme.darkNavy, fontWeight: FontWeight.w900),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                                  constraints: BoxConstraints(minWidth: 30),
                                ),
                                onSubmitted: (val) {
                                  int? newRows = int.tryParse(val);
                                  if (newRows != null && newRows > 0) {
                                    setState(() => _rowsPerPage = newRows);
                                  }
                                },
                              ),
                            ),
                            PopupMenuButton<int>(
                              icon: const Icon(Icons.arrow_drop_down, size: 22, color: AdminTheme.royalBlue),
                              padding: EdgeInsets.zero,
                              onSelected: (int value) {
                                setState(() {
                                  _rowsPerPage = value;
                                });
                              },
                              itemBuilder: (context) => [5, 10, 15, 20, 50, 100]
                                .map((v) => PopupMenuItem(value: v, child: Text("$v Items"))).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 250,
                    height: 45,
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                        hintText: "Search identifiers...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Data Table
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  headingRowHeight: 50,
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 70,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columns: [
                    const DataColumn(label: Text("S.N.", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
                    DataColumn(label: Text(widget.filterType == "Room" ? "ROOM NAME" : "TABLE NAME", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
                    const DataColumn(label: Text("CAPACITY", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
                    const DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
                    const DataColumn(label: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
                  ],
                  rows: List.generate(
                    filteredItems.length > _rowsPerPage ? _rowsPerPage : filteredItems.length, 
                    (index) {
                      final t = filteredItems[index];
                      final isRoom = t['type'] == "Room";
                      final status = t['status'] ?? "Available";
                      
                      return DataRow(
                        cells: [
                          DataCell(Text("${index + 1}", style: const TextStyle(color: Colors.grey))),
                          DataCell(Text(
                            isRoom ? "Room No: ${t['table_number']}" : "Table No: ${t['table_number']}", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                          )),
                          DataCell(Row(
                            children: [
                              const Icon(Icons.chair_alt, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text("${t['capacity']} Persons"),
                            ],
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.1), 
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(status.toUpperCase(), style: TextStyle(
                              color: _getStatusColor(status), 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold
                            )),
                          )),
                          DataCell(Row(
                            children: [
                              _buildActionBtn(Icons.qr_code_2_rounded, AdminTheme.royalBlue, () => _showQRCodeDialog(t)),
                              const SizedBox(width: 8),
                              _buildActionBtn(Icons.edit_note, Colors.cyan, () => _addItem(existingItem: t)),
                              const SizedBox(width: 8),
                              _buildActionBtn(Icons.delete_sweep_outlined, Colors.redAccent, () => _deleteItem(t)),
                            ],
                          )),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPopupInput(String label, String hint, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18),
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: () => _showToast("$text feature selected"),
        icon: Icon(icon, size: 14),
        label: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildGenericConfigView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Structural Configuration Header
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AdminTheme.darkNavy, Color(0xFF001A33)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AdminTheme.softShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_suggest_outlined, color: Colors.cyanAccent, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "${widget.filterType ?? 'Restaurant'} Infrastructure Setting", 
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Define floor plans, area-wise service charges, and structural rules for your units.", 
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addItem(),
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text("MANUAL ADD"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade700, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // 2. Area Rules & Surcharges Section
        Row(
          children: [
            const Icon(Icons.map_outlined, color: AdminTheme.royalBlue, size: 20),
            const SizedBox(width: 12),
            Text(
              "AREA-WISE SERVICE RULES", 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy.withValues(alpha: 0.8), letterSpacing: 1.2)
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Row(
          children: _areas.map((area) => Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _buildAreaRuleCard(area),
          )).toList(),
        ),

        const SizedBox(height: 48),
        
        // 3. Table Property Master
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.layers_outlined, color: AdminTheme.royalBlue, size: 20),
                const SizedBox(width: 12),
                Text(
                  "UNIT STRUCTURAL CONFIGURATION", 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy.withValues(alpha: 0.8), letterSpacing: 1.2)
                ),
              ],
            ),
            _buildViewAction(Icons.filter_list, "ADVANCED FILTERS", _areaFilter != "All Areas" || _reservableFilter != null || _nearWindowFilter != null || _mergableFilter != null, onTap: _showAdvancedFilters),
          ],
        ),
        const SizedBox(height: 20),
        _buildTableGrid(_finalFilteredList),
        
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildAreaRuleCard(Map<String, dynamic> area) {
    return Container(
      width: 280, // Fixed width for scrollable row items
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: area['isActive'] ? AdminTheme.royalBlue.withValues(alpha: 0.2) : Colors.grey.shade100, width: 2),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                child: Icon(area['icon'], color: AdminTheme.royalBlue, size: 20),
              ),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: area['isActive'], 
                  onChanged: (v) {
                    setState(() {
                      area['isActive'] = v;
                    });
                    _showToast("${area['name']} is now ${v ? 'Active' : 'Inactive'}");
                  }, 
                  activeColor: Colors.green
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(area['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          Text("Type: ${area['type']}", style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Surcharge:", style: TextStyle(color: Colors.grey, fontSize: 11)),
              InkWell(
                onTap: () => _editAreaSurcharge(area),
                child: Row(
                  children: [
                    Text("${area['surcharge']}%", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editAreaSurcharge(Map<String, dynamic> area) {
    final controller = TextEditingController(text: area['surcharge']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Set Surcharge - ${area['name']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Surcharge Percentage (%)",
            suffixText: "%",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Surcharge percentage cannot be empty"),
                  backgroundColor: Colors.redAccent,
                ));
                return;
              }
              setState(() {
                area['surcharge'] = controller.text.trim();
              });
              Navigator.pop(ctx);
              _showToast("Surcharge updated for ${area['name']}");
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
            child: const Text("UPDATE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableGrid(List<Map<String, dynamic>> tables, {bool isOffline = false}) {
    if (tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text("No items in this section.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final t = tables[index];
        final status = t['status'] ?? "Available";

        Color cardColor = _getStatusColor(status);
        if (isOffline) cardColor = Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: AdminTheme.softShadow,
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Icon(t['type'] == "Room" ? Icons.meeting_room_outlined : Icons.grid_3x3_outlined, color: AdminTheme.royalBlue, size: 20),
            ),
            title: Text("${t['type']} ${t['table_number']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            subtitle: Text("Area: ${t['area']} | Capacity: ${t['capacity']} Persons", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.tune_outlined, color: AdminTheme.royalBlue, size: 20),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 24, 24),
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStructuralToggle("Reservable", t['is_reservable'] ?? false, (v) {
                          setState(() => t['is_reservable'] = v);
                        }),
                        const SizedBox(width: 32),
                        _buildStructuralToggle("Mergable", t['is_mergable'] ?? false, (v) {
                          setState(() => t['is_mergable'] = v);
                        }),
                        const SizedBox(width: 32),
                        _buildStructuralToggle("Near Window", t['is_near_window'] ?? false, (v) {
                          setState(() => t['is_near_window'] = v);
                        }),
                        const Spacer(),
                        _buildActionBtn(Icons.edit_outlined, Colors.cyan, () => _addItem(existingItem: t)),
                        const SizedBox(width: 8),
                        _buildActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteItem(t)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStructuralToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 8),
        SizedBox(
          height: 20,
          width: 35,
          child: Transform.scale(
            scale: 0.6,
            child: Switch(
              value: value, 
              onChanged: onChanged, 
              activeColor: AdminTheme.royalBlue,
            ),
          ),
        ),
      ],
    );
  }

  void _showAdvancedFilters() {
    final areaController = TextEditingController(text: _areaFilter == "All Areas" ? "" : _areaFilter);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setFilterState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: AdminTheme.royalBlue),
                SizedBox(width: 12),
                Text("Advanced Filters", style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Area Selection (Text Input + Dropdown)
                const Text("Area / Zone", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: areaController,
                  decoration: InputDecoration(
                    hintText: "Enter or select area...",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down, color: AdminTheme.royalBlue),
                      onSelected: (val) {
                        setFilterState(() {
                          areaController.text = val;
                          _areaFilter = val;
                        });
                      },
                      itemBuilder: (context) => ["All Areas", "Main Hall", "VIP Wing", "Terrace"]
                        .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ),
                  onChanged: (val) {
                    _areaFilter = val.isEmpty ? "All Areas" : val;
                  },
                ),
                const SizedBox(height: 24),

                // Toggles
                _buildAdvancedToggle("Reservable Only", _reservableFilter, (v) => setFilterState(() => _reservableFilter = v)),
                _buildAdvancedToggle("Mergable Only", _mergableFilter, (v) => setFilterState(() => _mergableFilter = v)),
                _buildAdvancedToggle("Near Window Only", _nearWindowFilter, (v) => setFilterState(() => _nearWindowFilter = v)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _areaFilter = "All Areas";
                    _reservableFilter = null;
                    _nearWindowFilter = null;
                    _mergableFilter = null;
                  });
                  Navigator.pop(ctx);
                }, 
                child: const Text("RESET ALL", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {}); // Trigger refresh
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.royalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("APPLY FILTERS", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildAdvancedToggle(String label, bool? value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Checkbox(
            value: value ?? false, 
            tristate: true,
            onChanged: (v) => onChanged(v),
            activeColor: AdminTheme.royalBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
      ],
    );
  }

  void _showTableControlSheet(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String status = item['status'] ?? "Available";
            
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 500, // Fixed width for a centered look
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Manage ${item['type']} ${item['table_number']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            Text("Area: ${item['area']} | Status: $status", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(height: 40),
                    
                    const Text("QUICK STATUS CONTROLS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatusAction("AVAILABLE", Icons.check_circle_outline, Colors.green, "Available", item),
                        _buildStatusAction("OCCUPIED", Icons.person_outline, Colors.red, "Occupied", item),
                        _buildStatusAction("CLEANING", Icons.cleaning_services_outlined, Colors.orange, "Cleaning", item),
                        _buildStatusAction("HIDDEN", Icons.visibility_off_outlined, Colors.grey, "Hidden", item),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    const Text("WORK MANAGEMENT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.cleaning_services, color: AdminTheme.royalBlue),
                      title: const Text("Mark as Cleaned", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("Update hygiene timestamp for this table"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        setState(() => item['last_cleaned'] = "Just now");
                        Navigator.pop(context);
                        _showToast("Cleaning record updated for ${item['table_number']}");
                      },
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildStatusAction(String label, IconData icon, Color color, String targetStatus, Map<String, dynamic> item) {
    bool isCurrent = item['status'] == targetStatus;
    return InkWell(
      onTap: () {
        setState(() {
          item['status'] = targetStatus;
          item['is_visible'] = (targetStatus != "Hidden");
        });
        Navigator.pop(context);
        _showToast("${item['table_number']} is now $targetStatus.");
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isCurrent ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isCurrent ? Colors.white : color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isCurrent ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAction(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AdminTheme.royalBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: AdminTheme.royalBlue.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? AdminTheme.royalBlue : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AdminTheme.royalBlue : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
