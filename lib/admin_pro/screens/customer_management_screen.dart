import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin_theme.dart';

class CustomerManagementScreen extends StatefulWidget {
  final String mode; // "Customer List", "Type List", "Third Party", "Card Terminal"
  const CustomerManagementScreen({super.key, required this.mode});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  // --- DATA SOURCES ---
  final List<Map<String, dynamic>> _customers = [
    {'id': '1', 'name': 'Arbind Patel', 'phone': '9800000000', 'email': 'arbind@mail.com', 'type': 'VIP', 'points': 1250, 'total_spent': 15400, 'last_visit': '2 days ago'},
    {'id': '2', 'name': 'Sandhya Sharma', 'phone': '9811111111', 'email': 'sandhya@mail.com', 'type': 'Regular', 'points': 450, 'total_spent': 5200, 'last_visit': 'Today'},
    {'id': '3', 'name': 'Tech Solutions', 'phone': '01-4444444', 'email': 'info@tech.com', 'type': 'Corporate', 'points': 0, 'total_spent': 85000, 'last_visit': '1 week ago'},
    {'id': '4', 'name': 'Ram Kumar', 'phone': '9844444444', 'email': 'ram@mail.com', 'type': 'Regular', 'points': 120, 'total_spent': 1200, 'last_visit': '5 days ago'},
  ];

  final List<Map<String, dynamic>> _customerTypes = [
    {'name': 'Regular Customer', 'discount': 5, 'icon': Icons.person},
    {'name': 'QR Customer', 'discount': 0, 'icon': Icons.qr_code},
    {'name': 'Take Way', 'discount': 5, 'icon': Icons.shopping_bag},
    {'name': 'Third Party', 'discount': 0, 'icon': Icons.language},
    {'name': 'Walk In Customer', 'discount': 0, 'icon': Icons.directions_walk},
    {'name': 'Monthly Other', 'discount': 10, 'icon': Icons.calendar_month},
  ];

  final List<Map<String, dynamic>> _thirdPartyPlatforms = [
    {'name': 'Foodmandu', 'contact': 'Rajesh Hamal', 'phone': '9851000000', 'commission': 20.00, 'comm_type': '%', 'status': true, 'address': 'Kathmandu'},
    {'name': 'Pathao Food', 'contact': 'Sita Thapa', 'phone': '9841000000', 'commission': 50.00, 'comm_type': 'Rs', 'status': true, 'address': 'Lalitpur'},
    {'name': 'Bhoj Deals', 'contact': 'Ram Sah', 'phone': '9801000000', 'commission': 18.00, 'comm_type': '%', 'status': true, 'address': 'Dhaka'},
    {'name': 'Facebook/Meta', 'contact': 'Direct', 'phone': 'N/A', 'commission': 0.00, 'comm_type': '%', 'status': true, 'address': 'Online'},
  ];

  final List<Map<String, dynamic>> _terminals = [
    {
      'id': 'QR-101', 
      'name': 'Fonepay QR', 
      'category': 'QR Merchant',
      'model': 'Dynamic/Static QR', 
      'status': 'Online', 
      'today_total': 8450.00,
      'customer_count': 12,
      'last_settle': 'Today 11:30 AM',
      'icon': Icons.qr_code_scanner
    },
    {
      'id': 'ES-502', 
      'name': 'e-Sewa Wallet', 
      'category': 'Digital Wallet',
      'model': 'Merchant API', 
      'status': 'Online', 
      'today_total': 3200.00,
      'customer_count': 5,
      'last_settle': 'Today 10:00 AM',
      'icon': Icons.account_balance_wallet_outlined
    },
    {
      'id': 'T-1001', 
      'name': 'Nabil Bank POS', 
      'category': 'Card Terminal',
      'model': 'Pax A920 (Android)', 
      'status': 'Online', 
      'today_total': 12450.00,
      'customer_count': 8,
      'last_settle': 'Yesterday 10:30 PM',
      'icon': Icons.credit_card
    },
    {
      'id': 'KH-201', 
      'name': 'Khalti Payment', 
      'category': 'Digital Wallet',
      'model': 'SDK Integration', 
      'status': 'Online', 
      'today_total': 1500.00,
      'customer_count': 3,
      'last_settle': 'Today 09:00 AM',
      'icon': Icons.wallet_membership_outlined
    },
    {
      'id': 'CASH-01', 
      'name': 'Main Counter Cash', 
      'category': 'Cash Account',
      'model': 'Physical Drawer', 
      'status': 'Online', 
      'today_total': 25600.00,
      'customer_count': 45,
      'last_settle': 'Today 08:30 AM',
      'icon': Icons.payments_outlined
    },
  ];

  String _searchQuery = "";
  int _rowsPerPage = 10;
  String _selectedTier = "All Tiers";

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
          const SizedBox(height: 32),
          _buildContextualView(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AdminTheme.softShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerContent = [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(_getModeIcon(), color: AdminTheme.royalBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.mode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy), overflow: TextOverflow.ellipsis),
                  Text(_getModeSubtitle(), style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ];
          final addButton = ElevatedButton.icon(
            onPressed: () => _handleAddNew(),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text("ADD ${_getModeBtnLabel()}", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.royalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: headerContent),
                const SizedBox(height: 16),
                addButton,
              ],
            );
          }

          return Row(children: [...headerContent, const SizedBox(width: 16), addButton]);
        },
      ),
    );
  }

  Widget _buildSummaryStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _getModeStats(),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualView() {
    switch (widget.mode) {
      case "Customer List": return _buildCustomerList();
      case "Customer Type List": return _buildTypeList();
      case "Third-Party Customers": return _buildThirdPartyList();
      case "Terminal Management": return _buildTerminalList();
      default: return const Center(child: Text("Feature under development..."));
    }
  }

  // --- 1. CUSTOMER LIST VIEW ---
  Widget _buildCustomerList() {
    final filteredList = _customers.where((c) {
      final matchesSearch = c['name'].toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           c['phone'].contains(_searchQuery);
      final matchesTier = _selectedTier == "All Tiers" || c['type'].toString().toUpperCase() == _selectedTier.toUpperCase();
      return matchesSearch && matchesTier;
    }).toList();

    // Dynamically collect tiers
    Set<String> tiers = {"All Tiers", "Regular", "VIP", "Corporate"};
    for (var c in _customers) {
      tiers.add(c['type']);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tiers.map((t) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildTierChip(t),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              columns: const [
                DataColumn(label: Text("CUSTOMER NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("CONTACT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("TIER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("POINTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("TOTAL SPENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: filteredList.take(_rowsPerPage).map((c) => DataRow(
                cells: [
                  DataCell(Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['phone'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(c['email'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  )),
                  DataCell(_buildStatusTag(c['type'], _getTierColor(c['type']))),
                  DataCell(Text(c['points'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.royalBlue))),
                  DataCell(Text("Rs. ${c['total_spent']}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Row(
                    children: [
                      _buildActionBtn(Icons.history, Colors.cyan, () {}),
                      const SizedBox(width: 8),
                      _buildActionBtn(Icons.edit_outlined, AdminTheme.royalBlue, () => _openCustomerDialog(existingCustomer: c)),
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

  // --- 2. CUSTOMER TYPE LIST VIEW ---
  Widget _buildTypeList() {
    final filteredTypes = _customerTypes.where((t) {
      return t['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AdminTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Top Controls: Display, Exports, Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display Selector
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50], 
                  borderRadius: BorderRadius.circular(10), 
                  border: Border.all(color: Colors.grey.shade200)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Display ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: const TextStyle(fontSize: 12, color: AdminTheme.darkNavy, fontWeight: FontWeight.bold),
                      items: [5, 10, 15, 20, 25, 50, 100].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text("$value"),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) setState(() => _rowsPerPage = newValue);
                      },
                    ),
                    const Text(" records per page", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              
              // Export Buttons
              Row(
                children: [
                  _buildMiniExportBtn("CSV"),
                  _buildMiniExportBtn("Pdf"),
                  _buildMiniExportBtn("Print"),
                ],
              ),

              // Search Field
              Container(
                width: 250,
                height: 40,
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey, size: 18),
                    hintText: "Search type name...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table
          SizedBox(
            width: double.infinity,
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 24,
              headingRowHeight: 45,
              dataRowMinHeight: 55,
              dataRowMaxHeight: 55,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: const [
                DataColumn(label: Text("SN", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11))),
                DataColumn(label: Text("Third Party Name", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11))),
                DataColumn(label: Text("Discount (%)", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11))),
                DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11))),
              ],
              rows: List.generate(
                filteredTypes.length > _rowsPerPage ? _rowsPerPage : filteredTypes.length, 
                (index) {
                  final type = filteredTypes[index];
                  return DataRow(
                    cells: [
                      DataCell(Text("${index + 1}", style: const TextStyle(color: Colors.grey, fontSize: 13))),
                      DataCell(Text(type['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      DataCell(Text("${type['discount']}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                      DataCell(Row(
                        children: [
                          _buildActionBtn(Icons.edit_outlined, Colors.cyan, () => _openCustomerTypeDialog(existingType: type)),
                          const SizedBox(width: 8),
                          _buildActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteCustomerType(type)),
                        ],
                      )),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Pagination Placeholder
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildPaginationBtn("Previous", false),
              _buildPaginationBtn("1", true),
              _buildPaginationBtn("Next", false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniExportBtn(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: OutlinedButton(
        onPressed: () => _showToast("$label exported"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          foregroundColor: Colors.grey[700],
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPaginationBtn(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AdminTheme.royalBlue : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.grey[700],
          elevation: 0,
          side: isActive ? null : BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- 3. THIRD PARTY LIST VIEW ---
  Widget _buildThirdPartyList() {
    final filteredPlatforms = _thirdPartyPlatforms.where((p) {
      return p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (p['address'] ?? "").toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // 2. Main Table Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(8), 
            boxShadow: AdminTheme.softShadow,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // Control Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Display Selector
                  Row(
                    children: [
                      const Text("Display ", style: TextStyle(fontSize: 11, color: Colors.black87)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: DropdownButton<int>(
                          value: _rowsPerPage,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          items: [10, 25, 50, 100].map((v) => DropdownMenuItem(value: v, child: Text("$v", style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: (v) => setState(() => _rowsPerPage = v!),
                        ),
                      ),
                      const Text(" records per page", style: TextStyle(fontSize: 11, color: Colors.black87)),
                    ],
                  ),
                  
                  // Export Buttons
                  Row(
                    children: [
                      _buildMiniExportBtn("CSV"),
                      _buildMiniExportBtn("Pdf"),
                      _buildMiniExportBtn("Print"),
                    ],
                  ),

                  // Search
                  Row(
                    children: [
                      const Text("Search ", style: TextStyle(fontSize: 11, color: Colors.black87)),
                      const SizedBox(width: 8),
                      Container(
                        width: 180,
                        height: 35,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Data Table
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  horizontalMargin: 12,
                  columnSpacing: 20,
                  headingRowHeight: 45,
                  dataRowMinHeight: 50,
                  dataRowMaxHeight: 50,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
                  columns: const [
                    DataColumn(label: Text("SN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text("Third Party Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text("Commission", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text("Contact Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                  rows: List.generate(
                    filteredPlatforms.length > _rowsPerPage ? _rowsPerPage : filteredPlatforms.length,
                    (index) {
                      final p = filteredPlatforms[index];
                      return DataRow(
                        cells: [
                          DataCell(Text("${index + 1}", style: const TextStyle(fontSize: 12))),
                          DataCell(Text(p['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                          DataCell(Text("${p['commission']} ${p['comm_type']}", style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold))),
                          DataCell(Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['contact'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(p['phone'] ?? "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          )),
                          DataCell(Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: p['status'], 
                              onChanged: (v) => setState(() => p['status'] = v),
                              activeColor: Colors.green,
                            ),
                          )),
                          DataCell(Row(
                            children: [
                              _buildMiniActionBtn(Icons.edit, Colors.cyan, () => _openThirdPartyDialog(existingPlatform: p)),
                              const SizedBox(width: 6),
                              _buildMiniActionBtn(Icons.delete, Colors.redAccent, () => _deleteThirdParty(p)),
                            ],
                          )),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Footer Pagination
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildPaginationBtn("Previous", false),
                  _buildPaginationBtn("1", true),
                  _buildPaginationBtn("Next", false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  // --- 4. PAYMENT HUB (TOPIC WISE + ENGAGEMENT) ---
  String _paymentCategoryFilter = "ALL";

  Widget _buildTerminalList() {
    final filteredTerminals = _terminals.where((t) {
      final matchesSearch = t['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           t['id'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _paymentCategoryFilter == "ALL" || t['category'].toUpperCase().contains(_paymentCategoryFilter);
      return matchesSearch && matchesCat;
    }).toList();

    // Grouping terminals by Category
    Map<String, List<Map<String, dynamic>>> grouped = {};
    Map<String, int> engagementStats = {};
    
    for (var t in _terminals) {
      String cat = t['category'] ?? "Other";
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(t);
      engagementStats[cat] = (engagementStats[cat] ?? 0) + (t['customer_count'] as int? ?? 0);
    }

    return Column(
      children: [
        // TOPIC 1: USER ENGAGEMENT OVERVIEW
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
                  const Text("USER ENGAGEMENT OVERVIEW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2, color: AdminTheme.darkNavy)),
                  const Spacer(),
                  // Display Selector (Internal)
                  Container(
                    height: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        const Text("DISPLAY: ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          underline: const SizedBox(),
                          items: [5, 10, 20, 50].map((v) => DropdownMenuItem(value: v, child: Text("$v"))).toList(),
                          onChanged: (v) => setState(() => _rowsPerPage = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSearchField(),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildEngagementCard("ALL", _terminals.fold(0, (sum, t) => sum + (t['customer_count'] as int? ?? 0)), Icons.groups_outlined, Colors.grey),
                  ...engagementStats.keys.map((cat) {
                    IconData icon = Icons.payment;
                    Color col = AdminTheme.royalBlue;
                    if (cat == "Cash Account") { icon = Icons.payments; col = Colors.orange; }
                    if (cat == "QR Merchant") { icon = Icons.qr_code_scanner; col = Colors.green; }
                    if (cat == "Digital Wallet") { icon = Icons.account_balance_wallet; col = Colors.purple; }
                    
                    return _buildEngagementCard(cat.split(' ')[0].toUpperCase(), engagementStats[cat]!, icon, col, filterKey: cat.toUpperCase());
                  }),
                ],
              ),
            ],
          ),
        ),

        // TOPIC 2: DETAILED ACCOUNTS (FILTERED BY ENGAGEMENT CLICK)
        ...grouped.keys.where((k) => _paymentCategoryFilter == "ALL" || k.toUpperCase().contains(_paymentCategoryFilter)).map((category) {
          final items = grouped[category]!.where((t) => t['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
                    Text("${items.length} SOURCES ACTIVE", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                ...items.take(_rowsPerPage).map((t) {
                  bool isOnline = t['status'] == 'Online';
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
                        Icon(t['icon'] ?? Icons.payment, color: isOnline ? AdminTheme.royalBlue : Colors.grey, size: 24),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(t['model'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Rs. ${t['today_total']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AdminTheme.emeraldGreen)),
                              Text("${t['customer_count']} Customers", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        _buildStatusTag(t['status'], isOnline ? Colors.green : Colors.red),
                        const SizedBox(width: 16),
                        _buildModernCircleBtn(Icons.tune_rounded, "Config", AdminTheme.royalBlue, () => _openTerminalDialog(existingTerminal: t)),
                        const SizedBox(width: 8),
                        _buildModernCircleBtn(Icons.delete_outline_rounded, "Remove", Colors.redAccent, () => _deleteTerminal(t)),
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

  Widget _buildEngagementCard(String label, int count, IconData icon, Color color, {String filterKey = "ALL"}) {
    bool isSelected = _paymentCategoryFilter == filterKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentCategoryFilter = filterKey),
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
              Text("$count USERS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(IconData icon, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
      ],
    );
  }

  Widget _buildPulseStatus(bool isOnline) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        boxShadow: isOnline ? [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
      ),
    );
  }

  Widget _buildHardwareMetric(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
      ],
    );
  }

  Widget _buildMiniIndicator(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
      ],
    );
  }

  Widget _buildModernCircleBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  // --- HELPERS & LOGIC ---

  IconData _getModeIcon() {
    switch (widget.mode) {
      case "Customer List": return Icons.people_alt_outlined;
      case "Customer Type List": return Icons.category_outlined;
      case "Third-Party Customers": return Icons.language_outlined;
      case "Terminal Management": return Icons.credit_card_outlined;
      default: return Icons.settings;
    }
  }

  String _getModeSubtitle() {
    switch (widget.mode) {
      case "Customer List": return "Manage relationships and loyalty programs";
      case "Customer Type List": return "Define pricing tiers and order categories";
      case "Third-Party Customers": return "External platform delivery integrations";
      case "Terminal Management": return "POS machine hardware management";
      default: return "Settings and configuration";
    }
  }

  String _getModeBtnLabel() {
    switch (widget.mode) {
      case "Customer List": return "CUSTOMER";
      case "Customer Type List": return "CATEGORY";
      case "Third-Party Customers": return "NEW THIRD PARTY";
      case "Terminal Management": return "TERMINAL";
      default: return "NEW";
    }
  }

  List<Widget> _getModeStats() {
    switch (widget.mode) {
      case "Customer List":
        Map<String, int> counts = {};
        for (var c in _customers) {
          String t = c['type'] ?? "Regular";
          counts[t] = (counts[t] ?? 0) + 1;
        }
        
        List<String> priority = ["Regular", "VIP", "Corporate"];
        List<String> sorted = [];
        for (var p in priority) if (counts.containsKey(p)) sorted.add(p);
        for (var k in counts.keys) if (!priority.contains(k)) sorted.add(k);

        return [
          _buildStatCard("TOTAL CUSTOMERS", _customers.length.toString(), Icons.group, AdminTheme.royalBlue),
          ...sorted.map((t) => _buildStatCard(
            "${t.toUpperCase()} MEMBERS", 
            counts[t].toString(), 
            t == 'VIP' ? Icons.stars : (t == 'Corporate' ? Icons.business : Icons.person), 
            _getTierColor(t)
          )),
        ];
      case "Customer Type List":
        return [
          _buildStatCard("TOTAL TYPES", _customerTypes.length.toString(), Icons.category, AdminTheme.royalBlue),
          _buildStatCard("MAX DISCOUNT", "15%", Icons.percent, Colors.redAccent),
        ];
      case "Third-Party Customers":
        return [
          _buildStatCard("CONTRACTED PARTNERS", _thirdPartyPlatforms.length.toString(), Icons.handshake_outlined, AdminTheme.royalBlue),
          _buildStatCard("ACTIVE SOURCES", _thirdPartyPlatforms.where((p) => p['status']).length.toString(), Icons.cloud_done_outlined, Colors.green),
        ];
      default:
        Map<String, int> engagement = {};
        for (var t in _terminals) {
          String cat = t['category'] ?? "Other";
          engagement[cat] = (engagement[cat] ?? 0) + (t['customer_count'] as int? ?? 0);
        }

        return [
          _buildStatCard("CASH ENGAGED", (engagement['Cash Account'] ?? 0).toString(), Icons.payments, Colors.orange),
          _buildStatCard("QR ENGAGED", (engagement['QR Merchant'] ?? 0).toString(), Icons.qr_code_scanner, Colors.green),
          _buildStatCard("WALLET ENGAGED", (engagement['Digital Wallet'] ?? 0).toString(), Icons.account_balance_wallet, Colors.purple),
          _buildStatCard("CARD ENGAGED", (engagement['Card Terminal'] ?? 0).toString(), Icons.credit_card, AdminTheme.royalBlue),
        ];
    }
  }

  void _handleAddNew() {
    if (widget.mode == "Customer List") {
      _openCustomerDialog();
    } else if (widget.mode == "Terminal Management") {
      _openTerminalDialog();
    } else if (widget.mode == "Customer Type List") {
      _openCustomerTypeDialog();
    } else if (widget.mode == "Third-Party Customers") {
      _openThirdPartyDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add functionality for ${widget.mode} coming soon")));
    }
  }

  void _openThirdPartyDialog({Map<String, dynamic>? existingPlatform}) {
    bool isEditing = existingPlatform != null;
    final nameCtrl = TextEditingController(text: existingPlatform?['name']);
    final commissionCtrl = TextEditingController(text: existingPlatform?['commission']?.toString() ?? "0.00");
    final contactCtrl = TextEditingController(text: existingPlatform?['contact']);
    final phoneCtrl = TextEditingController(text: existingPlatform?['phone']);
    String commType = existingPlatform?['comm_type'] ?? "%";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(isEditing ? "Edit Third Party" : "Add New Third Party", style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField("Third Party Name", Icons.business_outlined, controller: nameCtrl),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildDialogField("Commission", Icons.payments_outlined, controller: commissionCtrl, isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: commType,
                          items: ["%", "Rs"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setModalState(() => commType = v!),
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildDialogField("Contact Person", Icons.person_outline, controller: contactCtrl),
                  _buildDialogField("Phone Number", Icons.phone_android_outlined, controller: phoneCtrl, isNumber: true),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) {
                    _showToast("Company Name is required", isError: true);
                    return;
                  }
                  setState(() {
                    if (isEditing) {
                      int idx = _thirdPartyPlatforms.indexWhere((p) => p['name'] == existingPlatform['name']);
                      if (idx != -1) {
                        _thirdPartyPlatforms[idx] = {
                          ..._thirdPartyPlatforms[idx],
                          'name': nameCtrl.text,
                          'commission': double.tryParse(commissionCtrl.text) ?? 0.00,
                          'comm_type': commType,
                          'contact': contactCtrl.text,
                          'phone': phoneCtrl.text,
                        };
                      }
                    } else {
                      _thirdPartyPlatforms.add({
                        'name': nameCtrl.text,
                        'commission': double.tryParse(commissionCtrl.text) ?? 0.00,
                        'comm_type': commType,
                        'contact': contactCtrl.text,
                        'phone': phoneCtrl.text,
                        'status': true,
                      });
                    }
                  });
                  Navigator.pop(ctx);
                  _showToast(isEditing ? "Third Party updated!" : "Third Party added!");
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF337AB7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                child: Text(isEditing ? "UPDATE" : "SAVE", style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deleteThirdParty(Map<String, dynamic> platform) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete third party '${platform['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() => _thirdPartyPlatforms.removeWhere((p) => p['name'] == platform['name']));
              Navigator.pop(ctx);
              _showToast("Third Party removed", isError: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openCustomerTypeDialog({Map<String, dynamic>? existingType}) {
    bool isEditing = existingType != null;
    final nameCtrl = TextEditingController(text: existingType?['name']);
    final discountCtrl = TextEditingController(text: existingType?['discount']?.toString() ?? "0");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? "Edit Customer Type" : "Add Customer Type", style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField("Type Name", Icons.category_outlined, controller: nameCtrl),
            _buildDialogField("Default Discount (%)", Icons.percent_rounded, controller: discountCtrl, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) {
                _showToast("Type Name is required", isError: true);
                return;
              }
              setState(() {
                if (isEditing) {
                  int idx = _customerTypes.indexWhere((t) => t['name'] == existingType['name']);
                  if (idx != -1) {
                    _customerTypes[idx] = {
                      ..._customerTypes[idx],
                      'name': nameCtrl.text,
                      'discount': int.tryParse(discountCtrl.text) ?? 0,
                    };
                  }
                } else {
                  _customerTypes.add({
                    'name': nameCtrl.text,
                    'discount': int.tryParse(discountCtrl.text) ?? 0,
                    'sc_apply': true, // Defaulting internally
                    'icon': Icons.stars,
                  });
                }
              });
              Navigator.pop(ctx);
              _showToast(isEditing ? "Type updated!" : "Type added!");
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(isEditing ? "UPDATE" : "SAVE", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteCustomerType(Map<String, dynamic> type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete customer type '${type['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() => _customerTypes.removeWhere((t) => t['name'] == type['name']));
              Navigator.pop(ctx);
              _showToast("Type removed", isError: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteTerminal(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to remove '${t['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _terminals.removeWhere((item) => item['id'] == t['id']);
              });
              Navigator.pop(ctx);
              _showToast("Payment source removed", isError: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openTerminalDialog({Map<String, dynamic>? existingTerminal}) {
    bool isEditing = existingTerminal != null;
    final nameCtrl = TextEditingController(text: existingTerminal?['name']);
    final categoryCtrl = TextEditingController(text: existingTerminal?['category'] ?? "Digital Wallet");
    final modelCtrl = TextEditingController(text: existingTerminal?['model'] ?? "Standard Integration");
    String status = existingTerminal?['status'] ?? "Online";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(isEditing ? "Edit Payment Source" : "Add Payment Source", style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField("Source Name (e.g. Fonepay QR)", Icons.badge_outlined, controller: nameCtrl),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryCtrl,
                    decoration: InputDecoration(
                      labelText: "Payment Category (Grouping)",
                      hintText: "Type or select category...",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                        onSelected: (v) => categoryCtrl.text = v,
                        itemBuilder: (context) => ["QR Merchant", "Digital Wallet", "Card Terminal", "Cash Account"]
                          .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogField("Integration Mode / Details", Icons.code, controller: modelCtrl),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: "Status",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ["Online", "Offline"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => status = v!,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty || categoryCtrl.text.isEmpty) {
                    _showToast("Name and Category are required", isError: true);
                    return;
                  }
                  setState(() {
                    String cat = categoryCtrl.text;
                    IconData icon = Icons.payment;
                    if (cat.contains("QR")) icon = Icons.qr_code_scanner;
                    if (cat.contains("Wallet") || cat.contains("e-Sewa") || cat.contains("Khalti")) icon = Icons.account_balance_wallet;
                    if (cat.contains("Card") || cat.contains("Terminal")) icon = Icons.credit_card;
                    if (cat.contains("Cash")) icon = Icons.payments;

                    if (isEditing) {
                      int idx = _terminals.indexWhere((t) => t['id'] == existingTerminal['id']);
                      if (idx != -1) {
                        _terminals[idx] = {
                          ..._terminals[idx], 
                          'name': nameCtrl.text, 
                          'category': cat,
                          'model': modelCtrl.text, 
                          'status': status,
                          'icon': icon
                        };
                      }
                    } else {
                      _terminals.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameCtrl.text, 
                        'category': cat,
                        'model': modelCtrl.text, 
                        'status': status,
                        'today_total': 0.0,
                        'customer_count': 0,
                        'last_settle': 'Never',
                        'icon': icon
                      });
                    }
                  });
                  Navigator.pop(ctx);
                  _showToast(isEditing ? "Source updated!" : "New payment source added!");
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

  void _testTerminalConnection(Map<String, dynamic> t) {
    _showToast("Testing connection to ${t['bank']} server...");
    Future.delayed(const Duration(seconds: 2), () {
      _showToast("Connection Successful! Terminal ${t['id']} is active.", isError: false);
    });
  }

  void _settleTerminal(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Daily Settlement"),
        content: Text("Do you want to close the current batch and settle transactions for ${t['bank']} (${t['id']})?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast("Batch Closed. Settlement receipt printing...");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("SETTLE NOW", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openCustomerDialog({Map<String, dynamic>? existingCustomer}) {
    bool isEditing = existingCustomer != null;
    final nameCtrl = TextEditingController(text: existingCustomer?['name']);
    final phoneCtrl = TextEditingController(text: existingCustomer?['phone']);
    final emailCtrl = TextEditingController(text: existingCustomer?['email']);
    final tierCtrl = TextEditingController(text: existingCustomer?['type'] ?? "Regular");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? "Edit Customer Details" : "Register New Customer", style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField("Full Name", Icons.person_outline, controller: nameCtrl),
            _buildDialogField("Phone Number", Icons.phone_android_outlined, isNumber: true, controller: phoneCtrl),
            _buildDialogField("Email Address", Icons.email_outlined, controller: emailCtrl),
            const SizedBox(height: 12),
            TextField(
              controller: tierCtrl,
              decoration: InputDecoration(
                labelText: "Customer Tier",
                hintText: "Type or select...",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AdminTheme.royalBlue),
                  onSelected: (v) => tierCtrl.text = v,
                  itemBuilder: (context) => ["Regular", "VIP", "Corporate"]
                    .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Phone are required")));
                return;
              }
              setState(() {
                if (isEditing) {
                  int idx = _customers.indexWhere((c) => c['id'] == existingCustomer['id']);
                  if (idx != -1) {
                    _customers[idx] = {
                      ..._customers[idx],
                      'name': nameCtrl.text,
                      'phone': phoneCtrl.text,
                      'email': emailCtrl.text,
                      'type': tierCtrl.text,
                    };
                  }
                } else {
                  _customers.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                    'email': emailCtrl.text,
                    'type': tierCtrl.text,
                    'points': 0,
                    'total_spent': 0,
                    'last_visit': 'Just registered',
                  });
                }
              });
              Navigator.pop(ctx);
              _showToast(isEditing ? "Customer updated successfully!" : "Customer registered successfully!");
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(isEditing ? "UPDATE" : "REGISTER", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, IconData icon, {bool isNumber = false, TextEditingController? controller}) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? Colors.redAccent : AdminTheme.royalBlue
      )
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 300,
      height: 45,
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
          hintText: "Quick search...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTierChip(String tier) {
    bool isSelected = _selectedTier == tier;
    return FilterChip(
      label: Text(tier.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
      selected: isSelected,
      onSelected: (v) => setState(() => _selectedTier = tier),
      selectedColor: AdminTheme.royalBlue,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: isSelected ? AdminTheme.royalBlue : Colors.grey.shade200)),
    );
  }

  Color _getTierColor(String type) {
    switch (type) {
      case 'VIP': return Colors.orange;
      case 'Corporate': return Colors.purple;
      default: return Colors.blue;
    }
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
