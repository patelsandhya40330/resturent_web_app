import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/tenant_service.dart';
import '../admin_theme.dart';

class OrderManagementScreen extends StatefulWidget {
  final String initialStatus;
  const OrderManagementScreen({super.key, this.initialStatus = "All"});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  late String _currentFilter;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialStatus;
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final tenant = TenantService().currentTenant.value;
    if (tenant == null) return;

    setState(() => _isLoading = true);
    final data = await ApiService.fetchAllOrders(tenant.id);
    if (mounted) {
      if (data != null) setState(() => _orders = data);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _currentFilter == "All" 
        ? _orders 
        : _orders.where((o) => o['status'] == _currentFilter).toList();

    return Column(
      children: [
        _buildFilterToolbar(),
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildOrderTicketCard(filtered[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterToolbar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
            child: TextField(
              onChanged: (v) {},
              decoration: const InputDecoration(hintText: "Search Order ID, Table...", prefixIcon: Icon(Icons.search), border: InputBorder.none),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["All", "Pending", "Approved", "Preparing", "Ready", "Completed", "Cancel"].map((f) {
                bool isSel = _currentFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    selected: isSel,
                    onSelected: (v) => setState(() => _currentFilter = f),
                    selectedColor: AdminTheme.royalBlue,
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTicketCard(Map<String, dynamic> order) {
    String id = "ORD-${order['id']}";
    String status = order['status'] ?? 'Pending';
    Color statusColor = _getStatusColor(status);
    String customer = order['customer_name'] ?? "Guest";
    String location = order['table_number']?.toString() ?? "N/A";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1),
                child: const Icon(Icons.receipt_long, color: AdminTheme.royalBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(customer, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _buildStatusBadge(status, statusColor),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _buildInfoItem(Icons.table_restaurant, "Location", "Table $location"),
              _buildInfoItem(Icons.access_time, "Time", order['created_at'] ?? "Just now"),
              _buildInfoItem(Icons.payments_outlined, "Payment", order['payment_status'] ?? "Unpaid"),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ...(order['items'] as List<dynamic>? ?? []).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue, fontSize: 12)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['name'] ?? 'Item', style: const TextStyle(fontSize: 12))),
                      Text("NPR ${item['price']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL BILL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    Text("NPR ${order['total_amount']}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _showOrderDetails(order), child: const Text("VIEW DETAILS"))),
              const SizedBox(width: 12),
              IconButton(onPressed: () => _deleteOrder(order['id'].toString()), icon: const Icon(Icons.delete_outline, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10))]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No orders found matching criteria."));
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(context: context, builder: (ctx) => Container(padding: const EdgeInsets.all(24), child: Column(children: [Text("Order #ORD-${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const Divider(), Expanded(child: ListView(children: [ListTile(title: const Text("Customer"), trailing: Text(order['customer_name'] ?? "Guest")), ListTile(title: const Text("Table"), trailing: Text(order['table_number'].toString())), ListTile(title: const Text("Status"), trailing: Text(order['status'] ?? "Pending"))]))])));
  }

  Future<void> _deleteOrder(String id) async {
    final tenant = TenantService().currentTenant.value;
    if (tenant == null) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text("Delete Order?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("DELETE", style: TextStyle(color: Colors.red)))]));
    if (confirm == true) {
      await ApiService.deleteOrder(tenant.id, id);
      _loadOrders();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Approved': return Colors.blue;
      case 'Preparing': return Colors.purple;
      case 'Ready': return Colors.cyan;
      case 'Completed': return AdminTheme.emeraldGreen;
      case 'Cancel': return Colors.red;
      default: return Colors.grey;
    }
  }
}
