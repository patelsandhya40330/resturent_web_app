import 'package:flutter/material.dart';
import '../admin_theme.dart';

class KitchenManagementScreen extends StatefulWidget {
  final String mode; // "Kitchen List", "Kitchen Assign", "Kitchen Dashboard Setting"
  const KitchenManagementScreen({super.key, required this.mode});

  @override
  State<KitchenManagementScreen> createState() => _KitchenManagementScreenState();
}

class _KitchenManagementScreenState extends State<KitchenManagementScreen> {
  // --- DEMO DATA ---
  final List<Map<String, dynamic>> _kitchens = [
    {
      'id': 'KTN-001', 
      'name': 'Main Production Kitchen', 
      'code': 'MPK-01',
      'category': 'Main Stations',
      'type': 'Production',
      'status': 'Online', 
      'orders_today': 145,
      'staff': ['Arbind Patel', 'Sandhya Sharma', 'Ram Kumar', 'Sita Thapa', 'Rajesh Hamal', 'Gita Rai', 'Hari Kc', 'Maya Devi', 'Suraj Limbu', 'Puja Shah', 'Binod Chaudhary', 'Rita Gurung'],
      'icon': Icons.soup_kitchen
    },
    {
      'id': 'KTN-002', 
      'name': 'Chinese & Wok Station', 
      'code': 'CW-02',
      'category': 'Main Stations',
      'type': 'Specialty',
      'status': 'Online', 
      'orders_today': 82,
      'staff': ['Krishna Pd', 'Anjali Bista', 'Madan Rai', 'Saru Magar', 'Dipesh Shah'],
      'icon': Icons.outdoor_grill
    },
    {
      'id': 'KTN-003', 
      'name': 'Bakery & Pastry Unit', 
      'code': 'BP-03',
      'category': 'Sub Stations',
      'type': 'Bakery',
      'status': 'Online', 
      'orders_today': 45,
      'staff': ['Kabita Giri', 'Sunil Das', 'Rekha Kc', 'Om Pd'],
      'icon': Icons.bakery_dining
    },
    {
      'id': 'KTN-004', 
      'name': 'Main Bar & Beverages', 
      'code': 'BAR-01',
      'category': 'Bar & Beverage',
      'type': 'Beverages',
      'status': 'Online', 
      'orders_today': 210,
      'staff': ['Sameer Rai', 'Nisha Lama', 'Prakash Poudel'],
      'icon': Icons.local_bar
    },
    {
      'id': 'KTN-005', 
      'name': 'Outdoor BBQ Station', 
      'code': 'BBQ-05',
      'category': 'Sub Stations',
      'type': 'Grill',
      'status': 'Offline', 
      'orders_today': 0,
      'staff': [],
      'icon': Icons.fire_hydrant_alt
    },
  ];

  final List<Map<String, dynamic>> _assignments = [
    {'id': 'AS-001', 'category': 'Momo', 'item': 'Chicken Momo', 'kitchen': 'Main Production Kitchen', 'priority': 'High', 'status': 'Active'},
    {'id': 'AS-002', 'category': 'Pizza', 'item': 'Chicken Pizza', 'kitchen': 'Pizza Kitchen', 'priority': 'Medium', 'status': 'Active'},
    {'id': 'AS-003', 'category': 'Chowmein', 'item': 'Veg Chowmein', 'kitchen': 'Chinese & Wok Station', 'priority': 'Medium', 'status': 'Active'},
    {'id': 'AS-004', 'category': 'Cake', 'item': 'Chocolate Cake', 'kitchen': 'Bakery & Pastry Unit', 'priority': 'Low', 'status': 'Active'},
    {'id': 'AS-005', 'category': 'Coffee', 'item': 'Cappuccino', 'kitchen': 'Main Bar & Beverages', 'priority': 'Medium', 'status': 'Active'},
  ];

  // UI State
  String? _activeDetailView;
  String _searchQuery = "";
  String _stationFilter = "ALL";
  
  // Dashboard Settings State
  bool _showNew = true;
  bool _showPreparing = true;
  bool _showReady = true;
  bool _showCompleted = false;
  bool _showOrderTime = true;
  bool _showTableNo = true;
  bool _showCustomerName = false;
  bool _autoRefresh = true;
  int _refreshInterval = 15;
  bool _soundAlert = true;
  String _displayMode = "Grid";
  int _ordersPerPage = 20;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryStats(),
          _buildDetailedSummaryView(),
          const SizedBox(height: 32),
          _buildContextualView(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_getModeIcon(), color: AdminTheme.royalBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.mode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              Text(_getModeSubtitle(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          if (widget.mode != "Kitchen Dashboard Setting")
            ElevatedButton.icon(
              onPressed: () => _handleAddNew(),
              icon: const Icon(Icons.add, size: 18),
              label: Text("ADD ${_getModeBtnLabel()}", style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.royalBlue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    if (widget.mode == "Kitchen Dashboard Setting") return const SizedBox();
    
    int totalStaff = _kitchens.fold(0, (sum, k) => sum + (k['staff'] as List).length);
    int totalOrders = _kitchens.fold(0, (sum, k) => sum + (k['orders_today'] as int));
    
    // Dynamically calculate counts for ALL unique statuses
    Map<String, int> statusCounts = {};
    for (var k in _kitchens) {
      String status = k['status'] ?? "Offline";
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    // Sort priority: Online, Offline, then others
    List<String> sortedStatuses = statusCounts.keys.toList();
    sortedStatuses.sort((a, b) {
      if (a == "Online") return -1;
      if (b == "Online") return 1;
      if (a == "Offline") return -1;
      if (b == "Offline") return 1;
      return a.compareTo(b);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildClickableStatCard("STAFF ENGAGED", totalStaff.toString(), Icons.people_outline, Colors.orange, "Staff Details"),
          
          ...sortedStatuses.map((status) {
            IconData icon = Icons.bolt;
            Color color = Colors.green;
            if (status == "Offline") { icon = Icons.power_off_outlined; color = Colors.redAccent; }
            else if (status != "Online") { icon = Icons.settings_suggest_outlined; color = Colors.purple; }
            
            return _buildClickableStatCard(
              "${status.toUpperCase()} STATIONS", 
              statusCounts[status].toString(), 
              icon, 
              color, 
              "Status: $status"
            );
          }),

          _buildClickableStatCard("TOTAL ORDERS", totalOrders.toString(), Icons.list_alt, AdminTheme.royalBlue, "Order Breakdown"),
        ],
      ),
    );
  }

  Widget _buildClickableStatCard(String label, String value, IconData icon, Color color, String detailKey) {
    bool isSelected = _activeDetailView == detailKey;
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: () => setState(() => _activeDetailView = isSelected ? null : detailKey),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.1), width: 2), 
            boxShadow: AdminTheme.softShadow
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                  Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedSummaryView() {
    if (_activeDetailView == null || widget.mode == "Kitchen Dashboard Setting") return const SizedBox();

    String title = _activeDetailView!;
    if (title.startsWith("Status: ")) title = "${title.substring(8)} Stations Details";

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: AdminTheme.softShadow,
        border: Border.all(color: AdminTheme.royalBlue.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: AdminTheme.royalBlue, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AdminTheme.darkNavy)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _activeDetailView = null),
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildDetailedContent(),
        ],
      ),
    );
  }

  Widget _buildDetailedContent() {
    if (_activeDetailView == null) return const SizedBox();

    if (_activeDetailView!.startsWith("Status: ")) {
      String filterStatus = _activeDetailView!.substring(8);
      final filteredKitchens = _kitchens.where((k) => k['status'] == filterStatus).toList();
      
      return Column(
        children: filteredKitchens.map((k) {
          bool isOnline = k['status'] == 'Online';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                Icon(k['icon'], color: isOnline ? Colors.green : (k['status'] == 'Offline' ? Colors.redAccent : Colors.purple), size: 20),
                const SizedBox(width: 16),
                Text(k['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                _buildStatusTag(k['status'], isOnline ? Colors.green : (k['status'] == 'Offline' ? Colors.red : Colors.purple)),
              ],
            ),
          );
        }).toList(),
      );
    }

    switch (_activeDetailView) {
      case "Staff Details":
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: _kitchens.map((k) {
            List staff = k['staff'];
            if (staff.isEmpty) return const SizedBox();
            return Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(k['icon'], size: 16, color: AdminTheme.royalBlue),
                      const SizedBox(width: 8),
                      Text(k['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: staff.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                      child: Text(s, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                    )).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case "Order Breakdown":
        return Column(
          children: _kitchens.map((k) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Icon(k['icon'], color: AdminTheme.royalBlue, size: 20),
                  const SizedBox(width: 16),
                  Text(k['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Text("${k['orders_today']} Orders", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue, fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        );
      default: return const SizedBox();
    }
  }

  Widget _buildContextualView() {
    switch (widget.mode) {
      case "Kitchen List": return _buildKitchenListView();
      case "Kitchen Assign": return _buildKitchenAssign();
      case "Kitchen Dashboard Setting": return _buildProfessionalDashboardSettings();
      default: return const SizedBox();
    }
  }

  // --- 1. KITCHEN LIST (High Fidelity) ---
  Widget _buildKitchenListView() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    Map<String, int> engagementStats = {};
    
    for (var k in _kitchens) {
      String cat = k['category'] ?? "Other Stations";
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(k);
      engagementStats[cat] = (engagementStats[cat] ?? 0) + (k['orders_today'] as int);
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AdminTheme.royalBlue.withValues(alpha: 0.05), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.royalBlue.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AdminTheme.royalBlue, size: 20),
                  const SizedBox(width: 12),
                  const Text("STATION ENGAGEMENT OVERVIEW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2, color: AdminTheme.darkNavy)),
                  const Spacer(),
                  _buildSearchField(),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildEngagementCard("ALL", _kitchens.fold(0, (sum, k) => sum + (k['orders_today'] as int)), Icons.groups_outlined, Colors.grey, filterKey: "ALL"),
                  ...engagementStats.keys.map((cat) {
                    IconData icon = Icons.soup_kitchen;
                    Color col = AdminTheme.royalBlue;
                    if (cat == "Main Stations") { icon = Icons.restaurant; col = Colors.green; }
                    if (cat == "Sub Stations") { icon = Icons.outdoor_grill; col = Colors.purple; }
                    if (cat == "Bar & Beverage") { icon = Icons.local_bar; col = Colors.orange; }
                    
                    return _buildEngagementCard(cat.toUpperCase(), engagementStats[cat]!, icon, col, filterKey: cat.toUpperCase());
                  }),
                ],
              ),
            ],
          ),
        ),

        ...grouped.keys.where((k) => _stationFilter == "ALL" || k.toUpperCase().contains(_stationFilter)).map((category) {
          final items = grouped[category]!.where((k) => k['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          if (items.isEmpty) return const SizedBox();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              boxShadow: AdminTheme.softShadow,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 18, decoration: BoxDecoration(color: AdminTheme.royalBlue, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 12),
                    Text(category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy)),
                    const Spacer(),
                    Text("${items.length} STATIONS", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                // --- NEW TOPIC HEADERS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text("STATION NAME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
                      const SizedBox(width: 20),
                      const Expanded(flex: 2, child: Text("STATION CODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
                      const Expanded(flex: 1, child: Text("STAFF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
                      const Expanded(flex: 2, child: Text("TODAY'S ORDERS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
                      const Expanded(flex: 1, child: Text("STATUS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
                      const SizedBox(width: 40, child: Text("ACTION", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 12),
                
                ...items.map((k) {
                  bool isOnline = k['status'] == 'Online';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50]?.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(k['icon'] ?? Icons.soup_kitchen, color: isOnline ? AdminTheme.royalBlue : Colors.grey, size: 24),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: Text(k['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(k['code'], style: const TextStyle(color: AdminTheme.royalBlue, fontSize: 12, fontWeight: FontWeight.w900)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text("${(k['staff'] as List).length}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text("${k['orders_today']} Orders", style: const TextStyle(fontSize: 13, color: AdminTheme.emeraldGreen, fontWeight: FontWeight.w900)),
                        ),
                        Expanded(
                          flex: 1,
                          child: InkWell(
                            onTap: () => setState(() => k['status'] = isOnline ? 'Offline' : 'Online'),
                            child: _buildStatusTag(k['status'], isOnline ? Colors.green : Colors.red),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildActionBtn(Icons.tune_rounded, AdminTheme.royalBlue, () => _openAddKitchenDialog(existingKitchen: k)),
                        const SizedBox(width: 8),
                        _buildActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteKitchen(k)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEngagementCard(String label, int count, IconData icon, Color color, {required String filterKey}) {
    bool isSelected = _stationFilter == filterKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _stationFilter = filterKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade100, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text("$count ORDERS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. KITCHEN ASSIGN ---
  Widget _buildKitchenAssign() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Category-to-Kitchen Mapping", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const Spacer(),
              _buildSearchField(),
            ],
          ),
          const Text("Define which kitchen handles which food categories or items.", style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              columns: const [
                DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("FOOD ITEM / CATEGORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("ASSIGNED KITCHEN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("PRIORITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: _assignments.map((a) => DataRow(
                cells: [
                  DataCell(Text(a['id'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataCell(Text(a['item'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  DataCell(Chip(
                    label: Text(a['kitchen'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  )),
                  DataCell(_buildStatusTag(a['priority'], a['priority'] == 'High' ? Colors.red : (a['priority'] == 'Medium' ? Colors.orange : Colors.blue))),
                  DataCell(
                    InkWell(
                      onTap: () => setState(() => a['status'] = a['status'] == 'Active' ? 'Deactive' : 'Active'),
                      child: _buildStatusTag(a['status'], a['status'] == 'Active' ? Colors.green : Colors.red),
                    ),
                  ),
                  DataCell(Row(
                    children: [
                      _buildActionBtn(Icons.edit_outlined, Colors.cyan, () => _openAddAssignmentDialog(existingAssignment: a)),
                      const SizedBox(width: 8),
                      _buildActionBtn(Icons.delete_outline, Colors.red, () => _deleteAssignment(a)),
                    ],
                  )),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. PROFESSIONAL DASHBOARD SETTINGS ---
  Widget _buildProfessionalDashboardSettings() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.settings_input_component_outlined, color: AdminTheme.royalBlue, size: 20),
              ),
              const SizedBox(width: 16),
              const Text("Kitchen Display System (KDS) Rules", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AdminTheme.darkNavy)),
            ],
          ),
          const SizedBox(height: 32),
          
          // TOP GRID: DISPLAY RULES
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildSettingsSwitchTile("Show New Orders", "Display orders waiting for acceptance", _showNew, (v) => setState(() => _showNew = v), Icons.fiber_new_outlined),
                        _buildSettingsSwitchTile("Show Preparing Orders", "Display orders currently being cooked", _showPreparing, (v) => setState(() => _showPreparing = v), Icons.restaurant_menu),
                        _buildSettingsSwitchTile("Show Ready Orders", "Display orders marked as ready to serve", _showReady, (v) => setState(() => _showReady = v), Icons.check_circle_outline),
                        _buildSettingsSwitchTile("Show Completed Orders", "Display historical served orders", _showCompleted, (v) => setState(() => _showCompleted = v), Icons.history),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 60),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSettingsSwitchTile("Show Order Time", "Show how long order has been active", _showOrderTime, (v) => setState(() => _showOrderTime = v), Icons.timer_outlined),
                        _buildSettingsSwitchTile("Show Table Number", "Display customer table mapping", _showTableNo, (v) => setState(() => _showTableNo = v), Icons.table_restaurant_outlined),
                        _buildSettingsSwitchTile("Show Customer Name", "Display buyer identification", _showCustomerName, (v) => setState(() => _showCustomerName = v), Icons.person_outline),
                        _buildSettingsSwitchTile("Sound Alert", "Play notification chime on new order", _soundAlert, (v) => setState(() => _soundAlert = v), Icons.notifications_active_outlined),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Divider(height: 1, color: Colors.black12),
          ),
          
          // BOTTOM ROW: REFRESH & DISPLAY
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AUTO REFRESH
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Auto Refresh Settings", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy)),
                        const SizedBox(height: 24),
                        _buildSettingsSwitchTile("Enable Auto Refresh", "Synchronize data periodically", _autoRefresh, (v) => setState(() => _autoRefresh = v), Icons.sync),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Refresh Interval: $_refreshInterval seconds", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                ),
                                child: Slider(
                                  value: _refreshInterval.toDouble(), min: 5, max: 60, divisions: 11,
                                  activeColor: AdminTheme.royalBlue,
                                  onChanged: _autoRefresh ? (v) => setState(() => _refreshInterval = v.round()) : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 80),
                  // DISPLAY CONFIG
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Display Configuration", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy)),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _displayMode,
                          decoration: InputDecoration(
                            labelText: "Display Mode",
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            filled: true, fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: ["Grid", "List", "Kanban"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                          onChanged: (v) => setState(() => _displayMode = v!),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Orders Per Page: $_ordersPerPage", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                ),
                                child: Slider(
                                  value: _ordersPerPage.toDouble(), min: 5, max: 50, divisions: 9,
                                  activeColor: AdminTheme.royalBlue,
                                  onChanged: (v) => setState(() => _ordersPerPage = v.round()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),

          const SizedBox(height: 60),
          Center(
            child: ElevatedButton(
              onPressed: () => _showToast("Configuration Saved Successfully"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.darkNavy, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Text("SAVE CONFIGURATION", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: value ? AdminTheme.royalBlue.withValues(alpha: 0.02) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: value ? AdminTheme.royalBlue.withValues(alpha: 0.1) : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: value ? AdminTheme.royalBlue : Colors.grey, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: value ? AdminTheme.darkNavy : Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
        activeColor: AdminTheme.royalBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  void _showStaffDetails() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Staff Engagement Details", style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: _kitchens.map((k) {
              List staff = k['staff'];
              if (staff.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(k['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)),
                  ),
                  Wrap(
                    spacing: 8,
                    children: staff.map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  void _showActiveStationDetails() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Active Stations Status", style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _kitchens.map((k) => ListTile(
              leading: Icon(k['icon'], color: k['status'] == 'Online' ? Colors.green : Colors.grey),
              title: Text(k['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: _buildStatusTag(k['status'], k['status'] == 'Online' ? Colors.green : Colors.red),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  void _showOrderBreakdown() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Orders Breakdown by Station", style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _kitchens.map((k) => ListTile(
              title: Text(k['name']),
              trailing: Text("${k['orders_today']} Orders", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue)),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  void _handleAddNew() {
    if (widget.mode == "Kitchen List") {
      _openAddKitchenDialog();
    } else if (widget.mode == "Kitchen Assign") {
      _openAddAssignmentDialog();
    } else if (widget.mode == "Kitchen Dashboard Setting") {
      _openAddConfigPresetDialog();
    }
  }

  void _openAddConfigPresetDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Save Configuration Preset", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Save current dashboard rules as a reusable profile (e.g. Lunch Rush, Night Shift, Weekend Mode).", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildDialogField("Preset Name", Icons.label_important_outline, controller: nameCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) {
                _showToast("Please enter a preset name", isError: true);
                return;
              }
              Navigator.pop(ctx);
              _showToast("Dashboard Preset '${nameCtrl.text}' saved successfully!");
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("SAVE PRESET", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 250, height: 40,
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: "Quick search...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
      ),
    );
  }

  Widget _buildStatusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // --- CRUD OPERATIONS ---
  void _openAddKitchenDialog({Map<String, dynamic>? existingKitchen}) {
    bool isEditing = existingKitchen != null;
    final nameCtrl = TextEditingController(text: existingKitchen?['name']);
    final codeCtrl = TextEditingController(text: existingKitchen?['code']);
    final categoryCtrl = TextEditingController(text: existingKitchen?['category'] ?? "Main Stations");
    final staffCtrl = TextEditingController(text: existingKitchen?['staff']?.length.toString() ?? "0");
    final statusCtrl = TextEditingController(text: existingKitchen?['status'] ?? "Online");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(isEditing ? "Edit Kitchen Station" : "Register New Kitchen", style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField("Kitchen Name", Icons.soup_kitchen, controller: nameCtrl),
                  _buildDialogField("Station Code", Icons.qr_code, controller: codeCtrl),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryCtrl,
                    decoration: InputDecoration(
                      labelText: "Station Category",
                      hintText: "Select category...",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                        onSelected: (v) => categoryCtrl.text = v,
                        itemBuilder: (context) => ["Main Stations", "Sub Stations", "Bar & Beverage"]
                          .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogField("Staff Count", Icons.people_outline, controller: staffCtrl, isNumber: true),
                  const SizedBox(height: 12),
                  // Current Status (Editable Text + Selection)
                  TextField(
                    controller: statusCtrl,
                    decoration: InputDecoration(
                      labelText: "Current Status",
                      hintText: "Type or select...",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                        onSelected: (v) => statusCtrl.text = v,
                        itemBuilder: (context) => ["Online", "Offline", "Maintenance", "Inactive"]
                          .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) {
                    _showToast("Kitchen Name is required", isError: true);
                    return;
                  }
                  setState(() {
                    String cat = categoryCtrl.text;
                    IconData icon = Icons.soup_kitchen;
                    if (cat.contains("Main")) icon = Icons.restaurant;
                    if (cat.contains("Sub")) icon = Icons.outdoor_grill;
                    if (cat.contains("Bar")) icon = Icons.local_bar;

                    if (isEditing) {
                      int idx = _kitchens.indexWhere((k) => k['id'] == existingKitchen['id']);
                      if (idx != -1) {
                        _kitchens[idx] = {
                          ..._kitchens[idx],
                          'name': nameCtrl.text,
                          'code': codeCtrl.text,
                          'category': cat,
                          'status': statusCtrl.text,
                          'icon': icon
                        };
                      }
                    } else {
                      _kitchens.add({
                        'id': "KTN-${_kitchens.length + 101}",
                        'name': nameCtrl.text,
                        'code': codeCtrl.text,
                        'category': cat,
                        'staff': List.generate(int.tryParse(staffCtrl.text) ?? 0, (i) => "Staff $i"),
                        'status': statusCtrl.text,
                        'orders_today': 0,
                        'icon': icon
                      });
                    }
                  });
                  Navigator.pop(ctx);
                  _showToast(isEditing ? "Kitchen updated!" : "Kitchen registered!");
                },
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(isEditing ? "UPDATE" : "SAVE", style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deleteKitchen(Map<String, dynamic> kitchen) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete kitchen station '${kitchen['name']}'? This may affect order routing."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() => _kitchens.removeWhere((k) => k['id'] == kitchen['id']));
              Navigator.pop(ctx);
              _showToast("Kitchen removed", isError: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAddAssignmentDialog({Map<String, dynamic>? existingAssignment}) {
    bool isEditing = existingAssignment != null;
    final idCtrl = TextEditingController(text: existingAssignment?['id'] ?? "AS-${_assignments.length + 101}");
    final itemCtrl = TextEditingController(text: existingAssignment?['item']);
    final catCtrl = TextEditingController(text: existingAssignment?['category']);
    final kitchenCtrl = TextEditingController(text: existingAssignment?['kitchen'] ?? _kitchens.first['name']);
    final priorityCtrl = TextEditingController(text: existingAssignment?['priority'] ?? "Medium");
    final statusCtrl = TextEditingController(text: existingAssignment?['status'] ?? "Active");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(isEditing ? "Update Assignment" : "Assign Category to Kitchen", style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField("Assignment ID", Icons.fingerprint, controller: idCtrl),
                  _buildDialogField("Food Item Name", Icons.fastfood_outlined, controller: itemCtrl),
                  _buildDialogField("Food Category", Icons.category_outlined, controller: catCtrl),
                  const SizedBox(height: 8),
                  TextField(
                    controller: kitchenCtrl,
                    decoration: InputDecoration(
                      labelText: "Target Kitchen",
                      hintText: "Type or select kitchen...",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                        onSelected: (v) => kitchenCtrl.text = v,
                        itemBuilder: (context) => _kitchens.map((k) => PopupMenuItem(value: k['name'] as String, child: Text(k['name']))).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priorityCtrl,
                    decoration: InputDecoration(
                      labelText: "Routing Priority",
                      hintText: "Type or select priority...",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                        onSelected: (v) => priorityCtrl.text = v,
                        itemBuilder: (context) => ["High", "Medium", "Low"]
                          .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Typable Status Field for Assignment
                  TextField(
                    controller: statusCtrl,
                    decoration: InputDecoration(
                      labelText: "Current Status",
                      hintText: "Type status (e.g. Active, Offline)...",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                        onSelected: (v) => statusCtrl.text = v,
                        itemBuilder: (context) => ["Active", "Deactive", "Online", "Offline", "Pending"]
                          .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () {
                  if (itemCtrl.text.isEmpty || idCtrl.text.isEmpty) {
                    _showToast("ID and Item Name are required", isError: true);
                    return;
                  }
                  setState(() {
                    if (isEditing) {
                      int idx = _assignments.indexWhere((a) => a['id'] == existingAssignment['id']);
                      if (idx != -1) {
                        _assignments[idx] = {
                          ..._assignments[idx],
                          'id': idCtrl.text,
                          'item': itemCtrl.text,
                          'category': catCtrl.text,
                          'kitchen': kitchenCtrl.text,
                          'priority': priorityCtrl.text,
                          'status': statusCtrl.text,
                        };
                      }
                    } else {
                      _assignments.add({
                        'id': idCtrl.text,
                        'item': itemCtrl.text,
                        'category': catCtrl.text,
                        'kitchen': kitchenCtrl.text,
                        'priority': priorityCtrl.text,
                        'status': statusCtrl.text,
                      });
                    }
                  });
                  Navigator.pop(ctx);
                  _showToast(isEditing ? "Assignment updated!" : "Category mapped successfully!");
                },
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(isEditing ? "UPDATE" : "ASSIGN", style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deleteAssignment(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Assignment"),
        content: Text("Delete routing for '${assignment['item']}' to '${assignment['kitchen']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() => _assignments.removeWhere((a) => a['id'] == assignment['id']));
              Navigator.pop(ctx);
              _showToast("Assignment removed", isError: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, IconData icon, {TextEditingController? controller, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.redAccent : AdminTheme.royalBlue));
  }

  IconData _getModeIcon() {
    switch (widget.mode) {
      case "Kitchen List": return Icons.soup_kitchen_outlined;
      case "Kitchen Assign": return Icons.add_link;
      case "Kitchen Dashboard Setting": return Icons.settings_input_component;
      default: return Icons.settings;
    }
  }

  String _getModeSubtitle() {
    switch (widget.mode) {
      case "Kitchen List": return "Manage operational kitchen stations and hardware";
      case "Kitchen Assign": return "Map food categories to specific stations";
      case "Kitchen Dashboard Setting": return "Configure Kitchen Display System (KDS) rules";
      default: return "";
    }
  }

  String _getModeBtnLabel() {
    switch (widget.mode) {
      case "Kitchen List": return "KITCHEN";
      case "Kitchen Assign": return "ASSIGNMENT";
      default: return "NEW";
    }
  }
}
