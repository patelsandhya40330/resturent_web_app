import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/tenant_service.dart';
import '../../cart_manager.dart';
import '../admin_theme.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class ReportManagementScreen extends StatefulWidget {
  final String mode;
  const ReportManagementScreen({super.key, required this.mode});

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _searchQuery = "";
  late String _lastUpdatedTime;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTimestamp();
    _loadData();
  }

  void _updateTimestamp() {
    _lastUpdatedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }

  Future<void> _loadData() async {
    final tenant = TenantService().currentTenant.value;
    
    setState(() => _isLoading = true);

    if (tenant == null) {
      // In offline/demo mode, we just wait a bit and show demo data
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _orders = []; // Will trigger demo data logic in views
          _updateTimestamp();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final orderData = await ApiService.fetchAllOrders(tenant.id);
      await ShopManager.instance.syncProcurementData(tenant.id);
      if (mounted) {
        setState(() {
          _orders = orderData ?? [];
          _updateTimestamp();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListenableBuilder(
      listenable: Listenable.merge([ShopManager.instance.allPurchases, TenantService().products, ShopManager.instance.staffDirectory]),
      builder: (context, _) {
        final purchases = ShopManager.instance.allPurchases.value;
        final products = TenantService().products.value;
        final staff = ShopManager.instance.staffDirectory.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 900;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 32),
                  _buildAdvancedFilterBar(isMobile),
                  const SizedBox(height: 32),
                  if (widget.mode == "Sales Report") _buildFullSalesReportView(isMobile)
                  else if (widget.mode == "Items Sales Report") _buildItemsSalesReportView(purchases, isMobile)
                  else if (widget.mode == "Service Charge Report") _buildServiceChargeReportView(isMobile)
                  else if (widget.mode == "Waiters Sales Report") _buildWaitersPerformanceView(isMobile)
                  else if (widget.mode == "Order Source Report") _buildOrderSourceAnalysisView(isMobile)
                  else if (widget.mode == "Kitchen Sales Report") _buildKitchenEfficiencyView(isMobile)
                  else if (widget.mode == "Delivery Type Sales Report") _buildDeliveryTypeReportView(isMobile)
                  else if (widget.mode == "Sale Report Cashier") _buildCashierSalesReportView(isMobile)
                  else if (widget.mode == "Cash Register Report") _buildCashRegisterReportView(isMobile)
                  else if (widget.mode == "Stock Report (Kitchen)") _buildKitchenStockView(purchases, isMobile)
                  else if (widget.mode == "Stock Report (Food Items)") _buildFoodItemStockView(products, isMobile)
                  else if (widget.mode == "Purchase Report") _buildPurchaseReportView(isMobile)
                  else if (widget.mode == "Sale By Table") _buildSaleByTableView(isMobile)
                  else if (widget.mode == "Sale Report Filtering") _buildSaleFilteringView(isMobile)
                  else if (widget.mode == "Sale By Date") _buildSaleByDateView(isMobile)
                  else if (widget.mode == "Commission") _buildCommissionReportView(isMobile)
                  else _buildGenericReportList(),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // --- NAVIGATION HEADER ---
  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${widget.mode.replaceAll("Report", "").trim()} Analysis", 
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.sync, size: 12, color: AdminTheme.royalBlue),
                  const SizedBox(width: 6),
                  Text("Live Synced: $_lastUpdatedTime", style: const TextStyle(fontSize: 11, color: AdminTheme.royalBlue, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        _buildExportButton(),
      ],
    );
  }

  // --- 1. FULL SALES REPORT ---
  Widget _buildFullSalesReportView(bool isMobile) {
    bool useDemo = _orders.isEmpty;
    double totalRevenue = useDemo ? 325400.0 : _orders.fold(0.0, (sum, o) => sum + (double.tryParse(o['total_amount'].toString()) ?? 0.0));
    int totalOrders = useDemo ? 1120 : _orders.length;
    
    double employeeCost = totalRevenue * 0.28; 
    final purchaseList = ShopManager.instance.allPurchases.value;
    double purchaseCost = useDemo 
        ? 71500.0 
        : (purchaseList.isEmpty 
            ? totalRevenue * 0.22 
            : purchaseList.fold(0.0, (sum, p) => sum + (double.tryParse(p['total_price'].toString()) ?? 0.0)));
    double netProfit = totalRevenue - employeeCost - purchaseCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, box) {
          int gridCount = box.maxWidth < 600 ? 2 : (box.maxWidth < 1100 ? 3 : (box.maxWidth < 1500 ? 4 : 8));
          return GridView.count(
            crossAxisCount: gridCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: box.maxWidth < 600 ? 1.3 : 1.6,
            children: [
              _buildImage3MetricCard("Total Revenue", "NPR ${NumberFormat('#,###').format(totalRevenue)}", "+12%", true, Colors.blue),
              _buildImage3MetricCard("Employee Cost", "NPR ${NumberFormat('#,###').format(employeeCost)}", "-5%", false, Colors.redAccent),
              _buildImage3MetricCard("Purchase Cost", "NPR ${NumberFormat('#,###').format(purchaseCost)}", "+8%", true, Colors.orangeAccent),
              _buildImage3MetricCard("Net Profit", "NPR ${NumberFormat('#,###').format(netProfit)}", "+18%", true, AdminTheme.emeraldGreen),
              _buildImage3MetricCard("Purchase Items", "${purchaseList.length}", "Total", true, Colors.cyan),
              _buildImage3MetricCard("Total Employees", "${ShopManager.instance.staffDirectory.value.length}", "Active", true, Colors.purple),
              _buildImage3MetricCard("Sales Growth", "15.4%", "↑", true, Colors.orange),
              _buildImage3MetricCard("Satisfaction", "4.8", "★★★★", true, Colors.amber),
            ],
          );
        }),
        const SizedBox(height: 32),
        LayoutBuilder(builder: (context, box) {
          if (box.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildSalesOverviewChart(totalRevenue, totalOrders)),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildFinancialBreakdownCard(totalRevenue, employeeCost, purchaseCost, netProfit)),
              ],
            );
          } else {
            return Column(
              children: [
                _buildSalesOverviewChart(totalRevenue, totalOrders),
                const SizedBox(height: 24),
                _buildFinancialBreakdownCard(totalRevenue, employeeCost, purchaseCost, netProfit),
              ],
            );
          }
        }),
        const SizedBox(height: 32),
        _buildPeakHoursChart(),
      ],
    );
  }

  // --- 2. ITEMS SALES REPORT ---
  Widget _buildItemsSalesReportView(List<Map<String, dynamic>> purchases, bool isMobile) {
    List<Map<String, dynamic>> effectiveOrders = List.from(_orders);
    
    if (effectiveOrders.isEmpty) {
      effectiveOrders = [
        {
          'id': '101', 'customer_name': 'Aayushma Singh', 'waiter_name': 'Rahul Sharma', 'table_number': '05', 
          'created_at': '2026-09-14 10:15:00',
          'cart_data': json.encode([
            {'name': 'Chicken Momo', 'quantity': 12, 'price': 125},
            {'name': 'Iced Tea', 'quantity': 8, 'price': 150},
          ])
        },
        {
          'id': '102', 'customer_name': 'Binod Thapa', 'waiter_name': 'Sita Gupta', 'table_number': '12', 
          'created_at': '2026-09-14 11:30:00',
          'cart_data': json.encode([
            {'name': 'Paneer Butter Masala', 'quantity': 5, 'price': 350},
            {'name': 'French Fries', 'quantity': 10, 'price': 150},
          ])
        },
        {
          'id': '103', 'customer_name': 'Pooja Rai', 'waiter_name': 'Amit Nepali', 'table_number': '02', 
          'created_at': '2026-09-14 12:45:00',
          'cart_data': json.encode([
            {'name': 'Special Thali', 'quantity': 15, 'price': 350},
            {'name': 'Chicken Momo', 'quantity': 20, 'price': 125},
          ])
        },
      ];
    }

    Map<String, int> itemQuantities = {};
    Map<String, double> itemRevenues = {};
    Map<String, double> itemPrices = {};
    Map<String, double> staffRevenues = {};
    List<Map<String, dynamic>> itemDetailedLogs = [];

    for (var order in effectiveOrders) {
      final String waiterName = order['waiter_name'] ?? order['cashier_name'] ?? 'System';
      final String orderDate = order['created_at'] ?? order['order_date'] ?? 'N/A';
      final String customerName = order['customer_name'] ?? 'Guest';
      final String tableNo = order['table_number']?.toString() ?? 'N/A';
      
      try {
        final dynamic cartDataRaw = order['cart_data'];
        final List<dynamic> items = cartDataRaw is String ? json.decode(cartDataRaw) : (cartDataRaw as List<dynamic>);
        
        for (var item in items) {
          final String itemName = item['product']?['name'] ?? item['name'] ?? 'Unknown Item';
          final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          final double price = double.tryParse(item['product']?['price']?.toString() ?? item['price']?.toString() ?? '0') ?? 0.0;
          final double totalItemPrice = price * qty;

          itemQuantities[itemName] = (itemQuantities[itemName] ?? 0) + qty;
          itemRevenues[itemName] = (itemRevenues[itemName] ?? 0.0) + totalItemPrice;
          itemPrices[itemName] = price;
          staffRevenues[waiterName] = (staffRevenues[waiterName] ?? 0.0) + totalItemPrice;

          itemDetailedLogs.add({
            'date': orderDate,
            'item': itemName,
            'qty': qty,
            'price': price,
            'total': totalItemPrice,
            'sold_by': waiterName,
            'customer': customerName,
            'table': tableNo,
          });
        }
      } catch (e) {}
    }

    var sortedItems = itemRevenues.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var topStaff = staffRevenues.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var filteredDishAnalysis = sortedItems.where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    double totalItemRev = itemRevenues.values.fold(0, (s, v) => s + v);
    int totalItemQty = itemQuantities.values.fold(0, (s, v) => s + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopHorizontalVisualizer(sortedItems),
        const SizedBox(height: 32),

        _buildSummaryGrid([
          _buildMetricCard("TOTAL QUANTITY", "$totalItemQty Units", "Daily", true, AdminTheme.royalBlue),
          _buildMetricCard("TOTAL ITEM SALES", "NPR ${NumberFormat('#,###').format(totalItemRev)}", "Revenue", true, AdminTheme.emeraldGreen),
        ], isMobile),
        const SizedBox(height: 32),

        _buildItemsTrendGraph(totalItemRev, isMobile),
        const SizedBox(height: 32),

        _buildReportSearchBar("Filter menu items..."),
        const SizedBox(height: 48),

        _buildDishSalesAnalysisTable(filteredDishAnalysis, itemPrices, itemQuantities),
        const SizedBox(height: 48),

        _buildStaffRankingCard(topStaff),
        const SizedBox(height: 48),

        _buildDetailedItemAuditLedger(itemDetailedLogs, isMobile),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTopHorizontalVisualizer(List<MapEntry<String, double>> topItems) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: topItems.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final item = topItems[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  item.key, 
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold), 
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: AdminTheme.royalBlue, 
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.white70, size: 24),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportSearchBar(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AdminTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, size: 20, color: Colors.grey),
          hintText: hint,
          border: InputBorder.none,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildDishSalesAnalysisTable(List<MapEntry<String, double>> items, Map<String, double> prices, Map<String, int> quantities) {
    double grandTotalRevenue = items.fold(0.0, (sum, e) => sum + e.value);
    int grandTotalVolume = items.fold(0, (sum, e) => sum + (quantities[e.key] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text("DISH SALES ANALYSIS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    _buildTableHeader("DISH NAME", 3),
                    _buildTableHeader("PRICE", 2, align: TextAlign.center),
                    _buildTableHeader("VOLUME", 2, align: TextAlign.center),
                    _buildTableHeader("REVENUE", 2, align: TextAlign.right),
                  ],
                ),
              ),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: Text("No items match your filter.", style: TextStyle(color: Colors.grey))))
              else ...[
                ...items.map((e) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.darkNavy))),
                      Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(prices[e.key] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text("${quantities[e.key] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminTheme.royalBlue), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(e.value)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.emeraldGreen), textAlign: TextAlign.right)),
                    ],
                  ),
                )),
                
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AdminTheme.darkNavy,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text("TOTAL SUMMARY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white, letterSpacing: 1))),
                      const Expanded(flex: 2, child: SizedBox()),
                      Expanded(flex: 2, child: Text("$grandTotalVolume units", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(grandTotalRevenue)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AdminTheme.emeraldGreen), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedItemAuditLedger(List<Map<String, dynamic>> logs, bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
      child: Column(children: [
        _buildTableEnterpriseHeader("Item Performance Audit Ledger"),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(children: [
              _buildTableHeader("DATE/TIME", 2),
              _buildTableHeader("ITEM NAME", 3),
              _buildTableHeader("QTY", 1, align: TextAlign.center),
              _buildTableHeader("PRICE", 2, align: TextAlign.center),
              _buildTableHeader("TOTAL", 2, align: TextAlign.right),
              if (!isMobile) ...[
                _buildTableHeader("SOLD BY", 2, align: TextAlign.center),
                _buildTableHeader("CUSTOMER", 2, align: TextAlign.center),
                _buildTableHeader("ROOM/TABLE NO", 1, align: TextAlign.center),
              ],
            ]),
            const Divider(height: 32, thickness: 1.5),
            if (logs.isEmpty)
              const Padding(padding: EdgeInsets.all(48), child: Text("No transaction logs found for items.", style: TextStyle(color: Colors.grey)))
            else
              ...logs.reversed.take(50).map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  Expanded(flex: 2, child: Text(l['date'], style: const TextStyle(fontSize: 11, color: Colors.grey))),
                  Expanded(flex: 3, child: Text(l['item'], style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy, fontSize: 13))),
                  Expanded(flex: 1, child: Text("${l['qty']}", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(l['price'])}", textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(l['total'])}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue), textAlign: TextAlign.right)),
                  if (!isMobile) ...[
                    Expanded(flex: 2, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AdminTheme.pearlWhite, borderRadius: BorderRadius.circular(6)),
                      child: Text(l['sold_by'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                    )),
                    Expanded(flex: 2, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(l['customer'], style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    )),
                    Expanded(flex: 1, child: Text(l['table'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ]),
              )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildItemsTrendGraph(double totalRevenue, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SALES VOLUME TREND", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  Text("Hourly Performance (Live)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text("PRO VERSION", style: TextStyle(color: AdminTheme.royalBlue, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 250,
            child: CustomPaint(
              painter: _ModernChartPainter([45, 80, 55, 120, 95, 150, 110], color: AdminTheme.royalBlue),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["10am", "12pm", "2pm", "4pm", "6pm", "8pm", "10pm"].map((t) => Text(t, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))).toList(),
          ),
        ],
      ),
    );
  }

  // --- 3. SERVICE CHARGE REPORT ---
  Widget _buildServiceChargeReportView(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryGrid([
          _buildMetricCard("TOTAL COLLECTED", "NPR 12,450", "Net", true, AdminTheme.royalBlue),
        ], isMobile),
        const SizedBox(height: 48),
        _buildSectionTitle("Service Charge Ledger"),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(28), child: Row(children: [_buildTableHeader("DATE", 2), _buildTableHeader("ORDER ID", 2), _buildTableHeader("TOTAL AMOUNT", 2), _buildTableHeader("SERVICE CHARGE", 2)])),
              const Divider(height: 1),
              _buildDataRowDemo("13 Sep 2026", "#1052", "NPR 4,250", "NPR 425", AdminTheme.emeraldGreen),
              _buildDataRowDemo("13 Sep 2026", "#1053", "NPR 1,800", "NPR 180", AdminTheme.emeraldGreen),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // --- 4. WAITERS SALES REPORT ---
  Widget _buildWaitersPerformanceView(bool isMobile) {
    // 1. DATA SIMULATION LOGIC (Professional Demo Data)
    List<Map<String, dynamic>> effectiveOrders = List.from(_orders);
    
    if (effectiveOrders.isEmpty) {
      effectiveOrders = [
        {
          'id': '101', 'waiter_name': 'Rahul Sharma', 'table_number': '102', 
          'created_at': '13 Sep 2026 07:45 PM',
          'total_amount': 12500.0,
          'cart_data': json.encode([{'name': 'Chicken Momo', 'quantity': 2, 'price': 250}])
        },
        {
          'id': '102', 'waiter_name': 'Sita Gupta', 'table_number': 'T-4', 
          'created_at': '13 Sep 2026 08:30 PM',
          'total_amount': 9800.0,
          'cart_data': json.encode([{'name': 'Special Thali', 'quantity': 1, 'price': 450}])
        },
        {
          'id': '104', 'waiter_name': 'Amit Nepali', 'table_number': 'T-12', 
          'created_at': '13 Sep 2026 10:20 PM',
          'total_amount': 7400.0,
          'cart_data': json.encode([{'name': 'French Fries', 'quantity': 2, 'price': 180}])
        },
      ];
    }

    // AGGREGATE SALES BY WAITER
    Map<String, double> waiterRevenues = {};
    for (var order in effectiveOrders) {
      final String waiterName = order['waiter_name'] ?? 'System';
      final double total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
      waiterRevenues[waiterName] = (waiterRevenues[waiterName] ?? 0.0) + total;
    }

    var sortedWaiters = waiterRevenues.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    double totalServiceRev = waiterRevenues.values.fold(0, (s, v) => s + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. WAITER REVENUE CONTRIBUTION (Image 2 Top)
        _buildWaiterRevenueContributionChart(sortedWaiters, isMobile),
        const SizedBox(height: 32),

        // 3. 3-Card Layout
        _buildSummaryGrid([
          _buildMetricCard("TOTAL SERVICE REVENUE", "NPR ${NumberFormat('#,###').format(totalServiceRev)}", "Live", true, AdminTheme.royalBlue),
          _buildMetricCard("TOP PERFORMER", sortedWaiters.isNotEmpty ? sortedWaiters.first.key.split(' ').first : 'N/A', "Leader", true, AdminTheme.emeraldGreen),
          _buildMetricCard("TOTAL STAFF", "${waiterRevenues.length}", "Active", true, Colors.orange),
        ], isMobile),
        const SizedBox(height: 48),

        // 4. AGGREGATE PERFORMANCE ANALYSIS (Reference Style)
        _buildAggregateWaiterPerformanceTable(sortedWaiters),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAggregateWaiterPerformanceTable(List<MapEntry<String, double>> data) {
    double grandTotal = data.fold(0, (s, e) => s + e.value);
    final tenant = TenantService().currentTenant.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmall = constraints.maxWidth < 600;
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _buildTableEnterpriseHeader("Waiter Sales Summary"),
              Padding(
                padding: EdgeInsets.all(isSmall ? 20 : 40),
                child: Column(
                  children: [
                    if (!isSmall) ...[
                      Text(tenant?.name ?? "Bhojon Restaurant", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                      const SizedBox(height: 8),
                      Text("Print Date: $_lastUpdatedTime", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 48),
                    ],
                    
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTableHeader("WAITER NAME", 3),
                          _buildTableHeader("TOTAL SALES", 2, align: TextAlign.right),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (data.isEmpty)
                      const Padding(padding: EdgeInsets.all(48), child: Text("No waiter records found for this period.", style: TextStyle(color: Colors.grey)))
                    else
                      ...data.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3, 
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AdminTheme.royalBlue.withOpacity(0.1),
                                    child: Text(e.key[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AdminTheme.darkNavy)),
                                ],
                              )
                            ),
                            Expanded(
                              flex: 2, 
                              child: Text(
                                "NPR ${NumberFormat('#,###.00').format(e.value)}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.royalBlue), 
                                textAlign: TextAlign.right
                              )
                            ),
                          ],
                        ),
                      )),
                    
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AdminTheme.darkNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Expanded(flex: 3, child: Text("NET TOTAL REVENUE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white70, letterSpacing: 1))),
                          Expanded(
                            flex: 2, 
                            child: Text(
                              "NPR ${NumberFormat('#,###.00').format(grandTotal)}", 
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AdminTheme.emeraldGreen), 
                              textAlign: TextAlign.right
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildWaiterRevenueContributionChart(List<MapEntry<String, double>> data, bool isMobile) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    // Take top 5 for clarity
    final displayData = data.take(5).toList();
    final double maxVal = displayData.isNotEmpty ? displayData.map((e) => e.value).reduce((a, b) => a > b ? a : b) : 100;

    return Container(
      width: double.infinity,
      height: isMobile ? 320 : 400,
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("WAITER REVENUE CONTRIBUTION", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  Text("Sales Distribution by Staff", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: const Text("TOP PERFORMERS", style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${displayData[groupIndex].key}\n",
                        const TextStyle(color: AdminTheme.darkNavy, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: "NPR ${NumberFormat('#,###').format(rod.toY)}",
                            style: const TextStyle(color: AdminTheme.royalBlue, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= displayData.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            displayData[index].key.split(' ').first,
                            style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: displayData.asMap().entries.map((entry) {
                  int index = entry.key;
                  double val = entry.value.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        gradient: const LinearGradient(
                          colors: [AdminTheme.royalBlue, Color(0xFF5A9BD5)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: isMobile ? 24 : 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal * 1.2,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: [],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedWaiterSalesLog(List<Map<String, dynamic>> logs, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text("DETAILED WAITER SALES LOG", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              _buildTableHeader("DATE & TIME", 2),
              _buildTableHeader("WAITER NAME", 2),
              _buildTableHeader("SOLD ITEM (QTY x PRICE)", 3),
              _buildTableHeader("ROOM/TABLE", 2, align: TextAlign.center),
              _buildTableHeader("TOTAL AMOUNT", 2, align: TextAlign.right),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        if (logs.isEmpty)
          const Padding(padding: EdgeInsets.all(48), child: Center(child: Text("No waiter records found.", style: TextStyle(color: Colors.grey))))
        else
          ...logs.reversed.take(50).map((l) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(l['time'], style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text(l['waiter'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.darkNavy))),
                Expanded(flex: 3, child: Text(l['item_details'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                Expanded(flex: 2, child: Text(l['room_table'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.royalBlue), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(l['amount'])}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.emeraldGreen), textAlign: TextAlign.right)),
              ],
            ),
          )),
      ],
    );
  }

  // --- 5. KITCHEN SALES REPORT ---
  Widget _buildKitchenEfficiencyView(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryGrid([
          _buildMetricCard("TOTAL KOTs", "42", "Daily", true, AdminTheme.royalBlue),
          _buildMetricCard("AVG. PREP TIME", "14 min", "Target: 15m", true, AdminTheme.emeraldGreen),
        ], isMobile),
        const SizedBox(height: 48),
        _buildSectionTitle("Live Production Ledger"),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(28), child: Row(children: [_buildTableHeader("TIME", 1), _buildTableHeader("ITEM DESCRIPTION", 3), _buildTableHeader("STATUS", 2)])),
              const Divider(height: 1),
              _buildKitchenRow({"time": "07:45 PM", "item": "Chicken Momo", "status": "Served"}),
              _buildKitchenRow({"time": "07:50 PM", "item": "Special Thali", "status": "Preparing"}),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // --- 4.5 ORDER SOURCE REPORT (CUSTOMER VS WAITER) ---
  Widget _buildOrderSourceAnalysisView(bool isMobile) {
    List<Map<String, dynamic>> effectiveOrders = List.from(_orders);
    
    if (effectiveOrders.isEmpty) {
      effectiveOrders = [
        {'id': '101', 'waiter_name': 'Rahul Sharma', 'total_amount': 12500.0, 'created_at': '2026-09-14 19:45'},
        {'id': '102', 'waiter_name': 'Sita Gupta', 'total_amount': 9800.0, 'created_at': '2026-09-14 20:30'},
        {'id': '103', 'waiter_name': null, 'total_amount': 4500.0, 'created_at': '2026-09-14 20:45'}, // Self Service
        {'id': '104', 'waiter_name': 'Amit Nepali', 'total_amount': 7400.0, 'created_at': '2026-09-14 22:20'},
        {'id': '105', 'waiter_name': '', 'total_amount': 3200.0, 'created_at': '2026-09-14 22:30'}, // Self Service
      ];
    }

    Map<String, double> sourceSales = {'Employee Assisted': 0.0, 'Self Service': 0.0};
    Map<String, int> sourceCounts = {'Employee Assisted': 0, 'Self Service': 0};

    for (var order in effectiveOrders) {
      final String? waiter = order['waiter_name'];
      bool isAssisted = waiter != null && waiter.trim().isNotEmpty;
      String source = isAssisted ? 'Employee Assisted' : 'Self Service';
      
      double total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
      sourceSales[source] = (sourceSales[source] ?? 0.0) + total;
      sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
    }

    double totalRev = sourceSales.values.fold(0, (s, v) => s + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChannelDistributionCard(sourceSales.entries.toList(), totalRev, true),
        const SizedBox(height: 32),
        _buildSummaryGrid(sourceSales.entries.map((e) => _buildMetricCard(
          e.key.toUpperCase(), 
          "NPR ${NumberFormat('#,###').format(e.value)}", 
          "${sourceCounts[e.key]} Orders", 
          true, 
          _getSourceColor(e.key)
        )).toList(), isMobile),
        const SizedBox(height: 48),
        _buildOrderSourceLedger(effectiveOrders),
      ],
    );
  }

  Widget _buildOrderSourceLedger(List<Map<String, dynamic>> orders) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildTableEnterpriseHeader("Order Source Performance Ledger"),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildTableHeader("ORDER ID", 2),
                      _buildTableHeader("TIME", 2),
                      _buildTableHeader("PLACED BY", 3),
                      _buildTableHeader("TYPE", 2, align: TextAlign.center),
                      _buildTableHeader("AMOUNT", 2, align: TextAlign.right),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...orders.reversed.take(50).map((o) {
                  final String? waiter = o['waiter_name'];
                  bool isAssisted = waiter != null && waiter.trim().isNotEmpty;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text("#${o['id']}", style: const TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text(o['created_at'] ?? 'N/A', style: const TextStyle(fontSize: 11, color: Colors.grey))),
                        Expanded(flex: 3, child: Text(isAssisted ? waiter! : "Customer (Direct)", style: TextStyle(fontWeight: FontWeight.w600, color: isAssisted ? AdminTheme.darkNavy : AdminTheme.royalBlue))),
                        Expanded(
                          flex: 2, 
                          child: Container(
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getSourceColor(isAssisted ? 'Employee Assisted' : 'Self Service').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAssisted ? "ASSISTED" : "SELF",
                                style: TextStyle(color: _getSourceColor(isAssisted ? 'Employee Assisted' : 'Self Service'), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ),
                        Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(double.tryParse(o['total_amount']?.toString() ?? '0') ?? 0)}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy), textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(String source) {
    if (source == 'Employee Assisted') return AdminTheme.royalBlue;
    return AdminTheme.emeraldGreen;
  }

  // --- 6. ORDER SOURCE ANALYSIS (EMPLOYEE VS CUSTOMER) ---
  Widget _buildDeliveryTypeReportView(bool isMobile) {
    // Categorize orders based on waiter_name presence
    List<Map<String, dynamic>> effectiveOrders = List.from(_orders);
    
    if (effectiveOrders.isEmpty) {
      effectiveOrders = [
        {'id': '101', 'waiter_name': 'Rahul Sharma', 'total_amount': 125400.0, 'created_at': '2026-09-14 19:45'},
        {'id': '102', 'waiter_name': 'Sita Gupta', 'total_amount': 86500.0, 'created_at': '2026-09-14 20:30'},
        {'id': '103', 'waiter_name': null, 'total_amount': 42000.0, 'created_at': '2026-09-14 20:45'}, // Customer Order
      ];
    }

    Map<String, double> typeSales = {'Employee (Waiter Order)': 0.0, 'Customer Order': 0.0};
    Map<String, int> typeOrders = {'Employee (Waiter Order)': 0, 'Customer Order': 0};

    for (var order in effectiveOrders) {
      final String? waiter = order['waiter_name'];
      bool isAssisted = waiter != null && waiter.trim().isNotEmpty;
      String source = isAssisted ? 'Employee (Waiter Order)' : 'Customer Order';
      
      double total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
      typeSales[source] = (typeSales[source] ?? 0.0) + total;
      typeOrders[source] = (typeOrders[source] ?? 0) + 1;
    }

    double totalRev = typeSales.values.fold(0, (s, v) => s + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildChannelDistributionCard(typeSales.entries.toList(), totalRev, true)),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1, 
                    child: Column(
                      children: typeSales.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildMetricCard(
                          e.key.toUpperCase(), 
                          "NPR ${NumberFormat('#,###').format(e.value)}", 
                          "${typeOrders[e.key]} Orders", 
                          true, 
                          _getChannelColor(e.key)
                        ),
                      )).toList(),
                    )
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildChannelDistributionCard(typeSales.entries.toList(), totalRev, true),
                  const SizedBox(height: 24),
                  _buildSummaryGrid(typeSales.entries.map((e) => _buildMetricCard(e.key.toUpperCase(), "NPR ${NumberFormat('#,###').format(e.value)}", "${typeOrders[e.key]} Orders", true, _getChannelColor(e.key))).toList(), isMobile),
                ],
              );
            }
          }
        ),
        const SizedBox(height: 48),
        _buildDeliveryInsightsCard(typeSales, typeOrders),
        const SizedBox(height: 100),
      ],
    );
  }

  // --- 7. CASHIER SETTLEMENT ---
  Widget _buildCashierSalesReportView(bool isMobile) {
    final List<Map<String, dynamic>> cashiers = [
      {'sn': 1, 'name': 'Aayushma Singh', 'orders': 45, 'cash': 45000.0, 'digital': 55000.0, 'total': 100000.0},
      {'sn': 2, 'name': 'Binod Thapa', 'orders': 32, 'cash': 38000.0, 'digital': 28000.0, 'total': 66000.0},
      {'sn': 3, 'name': 'Chandra Kala', 'orders': 25, 'cash': 24000.0, 'digital': 20700.0, 'total': 44700.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryGrid([
          _buildMetricCard("TOTAL CASH SETTLED", "NPR 107,000", "Cashier Flow", true, AdminTheme.emeraldGreen),
          _buildMetricCard("TOTAL DIGITAL SETTLED", "NPR 103,700", "Digital Flow", true, AdminTheme.royalBlue),
          _buildMetricCard("SETTLEMENT ACCURACY", "100%", "Perfect Audit", true, Colors.amber),
        ], isMobile),
        const SizedBox(height: 32),
        _buildCashierSummaryVisual(isMobile),
        const SizedBox(height: 48),
        _buildSectionTitle("Cashier Settlement Ledger"),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: AdminTheme.softShadow),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(28), 
              child: Row(
                children: [
                  _buildTableHeader("SN", 1),
                  _buildTableHeader("CASHIER NAME", 3),
                  _buildTableHeader("ORDERS", 2),
                  _buildTableHeader("CASH", 2),
                  _buildTableHeader("DIGITAL", 2),
                  _buildTableHeader("TOTAL", 2),
                ],
              ),
            ),
            const Divider(height: 1),
            ...cashiers.map((c) => Column(
              children: [
                _buildCashierRow(
                  c['sn'] as int,
                  c['name'] as String,
                  c['orders'] as int,
                  c['cash'] as double,
                  c['digital'] as double,
                  c['total'] as double,
                ),
                const Divider(height: 1),
              ],
            )),
            const SizedBox(height: 20),
          ]),
        ),
      ],
    );
  }

  // --- 8.5 SALE BY TABLE REPORT ---
  Widget _buildSaleByTableView(bool isMobile) {
    List<Map<String, dynamic>> effectiveOrders = List.from(_orders);
    
    if (effectiveOrders.isEmpty) {
      effectiveOrders = [
        {'id': '101', 'table_number': 'T-01', 'total_amount': 12500.0, 'created_at': '2026-09-14 12:45'},
        {'id': '102', 'table_number': 'T-05', 'total_amount': 8400.0, 'created_at': '2026-09-14 13:20'},
        {'id': '103', 'table_number': 'T-01', 'total_amount': 7200.0, 'created_at': '2026-09-14 14:15'},
        {'id': '104', 'table_number': 'T-12', 'total_amount': 15600.0, 'created_at': '2026-09-14 15:10'},
        {'id': '105', 'table_number': 'T-05', 'total_amount': 9800.0, 'created_at': '2026-09-14 16:30'},
        {'id': '106', 'table_number': 'T-02', 'total_amount': 11000.0, 'created_at': '2026-09-14 17:45'},
      ];
    }

    Map<String, double> tableRevenue = {};
    Map<String, int> tableUsage = {};

    for (var order in effectiveOrders) {
      final String table = order['table_number']?.toString() ?? 'N/A';
      double total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
      tableRevenue[table] = (tableRevenue[table] ?? 0.0) + total;
      tableUsage[table] = (tableUsage[table] ?? 0) + 1;
    }

    var sortedTables = tableRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String topTable = sortedTables.isNotEmpty ? sortedTables.first.key : 'N/A';
    double avgTableRevenue = tableRevenue.values.isEmpty ? 0 : tableRevenue.values.fold(0.0, (s, v) => s + v) / tableRevenue.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableRevenueChart(sortedTables, isMobile),
        const SizedBox(height: 32),
        _buildSummaryGrid([
          _buildMetricCard("TOP REVENUE TABLE", topTable, "Leader", true, AdminTheme.royalBlue),
          _buildMetricCard("AVG REVENUE / TABLE", "NPR ${NumberFormat('#,###').format(avgTableRevenue)}", "Seating Value", true, AdminTheme.emeraldGreen),
          _buildMetricCard("ACTIVE TABLES", "${tableRevenue.length}", "Total", true, Colors.orange),
        ], isMobile),
        const SizedBox(height: 48),
        _buildTablePerformanceLedger(sortedTables, tableUsage),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTableRevenueChart(List<MapEntry<String, double>> data, bool isMobile) {
    if (data.isEmpty) return const SizedBox.shrink();
    final displayData = data.take(8).toList();
    final double maxVal = displayData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      height: isMobile ? 320 : 400,
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TABLE REVENUE COMPARISON", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text("Performance by Table Number", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= displayData.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(displayData[index].key, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: displayData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: AdminTheme.royalBlue,
                        width: isMobile ? 18 : 30,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxVal * 1.2, color: Colors.white.withOpacity(0.05)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablePerformanceLedger(List<MapEntry<String, double>> data, Map<String, int> usage) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildTableEnterpriseHeader("Table Performance Ledger"),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildTableHeader("TABLE NO", 2),
                      _buildTableHeader("TOTAL ORDERS", 2, align: TextAlign.center),
                      _buildTableHeader("NET REVENUE", 2, align: TextAlign.right),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...data.map((e) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            const Icon(Icons.table_restaurant_outlined, size: 16, color: AdminTheme.royalBlue),
                            const SizedBox(width: 12),
                            Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.darkNavy)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text("${usage[e.key]}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(e.value)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.emeraldGreen), textAlign: TextAlign.right)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCashRegisterReportView(bool isMobile) {
    // Note: Discrepancy = Errors in reporting vs system totals.
    final List<Map<String, dynamic>> shifts = [
      {
        'sn': '1',
        'date': '2026-09-13',
        'time': '08:00 AM - 04:00 PM',
        'cashier': 'Admin',
        'offline_cash': 80000.0,
        'online_cash': 40500.0,
        'total_sales': 120500.0,
        'discrepancy': -300.0,
      },
      {
        'sn': '2',
        'date': '2026-09-14',
        'time': '08:00 AM - 04:00 PM',
        'cashier': 'Admin',
        'offline_cash': 60000.0,
        'online_cash': 38000.0,
        'total_sales': 98000.0,
        'discrepancy': 0.0,
      },
      {
        'sn': '3',
        'date': '2026-09-15',
        'time': '08:00 AM - 04:00 PM',
        'cashier': 'Admin',
        'offline_cash': 95000.0,
        'online_cash': 50000.0,
        'total_sales': 145000.0,
        'discrepancy': 500.0,
      },
    ];

    double totalOfflineCash = shifts.fold(0, (sum, s) => sum + s['offline_cash']);
    double totalOnlineCash = shifts.fold(0, (sum, s) => sum + s['online_cash']);
    double totalNetSales = shifts.fold(0, (sum, s) => sum + s['total_sales']);
    double totalDiscrepancy = shifts.fold(0, (sum, s) => sum + s['discrepancy']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRegisterColumnChart(
          shifts.map((s) => s['offline_cash'] as double).toList(),
          shifts.map((s) => s['online_cash'] as double).toList(),
          shifts.map((s) => "Shift-${s['sn']}").toList(),
        ),
        const SizedBox(height: 32),
        _buildSummaryGrid([
          _buildMetricCard("TOTAL OFFLINE CASH", "NPR ${NumberFormat('#,###').format(totalOfflineCash)}", "Offline Flow", true, AdminTheme.royalBlue),
          _buildMetricCard("TOTAL ONLINE CASH", "NPR ${NumberFormat('#,###').format(totalOnlineCash)}", "Online Flow", true, AdminTheme.emeraldGreen),
          _buildMetricCard("NET TOTAL SALES", "NPR ${NumberFormat('#,###').format(totalNetSales)}", "Net Sales", true, AdminTheme.royalBlue),
        ], isMobile),
        const SizedBox(height: 48),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
          child: Column(children: [
            _buildTableEnterpriseHeader("Register Audit Ledger"),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              _buildRegisterTableHeader(isMobile),
              const Divider(thickness: 1.5),
              ...shifts.map((s) => _buildRegisterDataRow(s, isMobile)),
              _buildRegisterTotalRow(totalOfflineCash, totalOnlineCash, totalNetSales, totalDiscrepancy, isMobile),
            ])),
          ]),
        ),
      ],
    );
  }

  // --- 9. STOCK REPORT (KITCHEN) ---
  Widget _buildKitchenStockView(List<Map<String, dynamic>> purchases, bool isMobile) {
    final List<Map<String, dynamic>> stockData = [
      {'name': 'Rice', 'category': 'Dry Goods', 'qty': 120, 'unit': 'kg', 'price_per_unit': 150, 'min_stock': 50},
      {'name': 'Chicken', 'category': 'Non-Veg', 'qty': 15, 'unit': 'kg', 'price_per_unit': 450, 'min_stock': 20},
      {'name': 'Cooking Oil', 'category': 'Dry Goods', 'qty': 0, 'unit': 'ltr', 'price_per_unit': 220, 'min_stock': 10},
      {'name': 'Tomato', 'category': 'Vegetables', 'qty': 45, 'unit': 'kg', 'price_per_unit': 80, 'min_stock': 15},
      {'name': 'Milk', 'category': 'Dairy', 'qty': 8, 'unit': 'ltr', 'price_per_unit': 110, 'min_stock': 12},
      {'name': 'Onion', 'category': 'Vegetables', 'qty': 60, 'unit': 'kg', 'price_per_unit': 60, 'min_stock': 20},
    ];

    double totalValuation = stockData.fold(0, (sum, item) => sum + ((item['qty'] as num) * (item['price_per_unit'] as num)));
    int lowStockCount = stockData.where((item) => (item['qty'] as num) > 0 && (item['qty'] as num) < (item['min_stock'] as num)).length;
    int outOfStockCount = stockData.where((item) => (item['qty'] as num) == 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStockVisualization(stockData),
        const SizedBox(height: 32),
        _buildSummaryGrid([
          _buildMetricCard("TOTAL ITEMS", "${stockData.length}", "Catalog", true, AdminTheme.royalBlue),
          _buildMetricCard("STOCK VALUATION", "NPR ${NumberFormat('#,###').format(totalValuation)}", "Investment", true, AdminTheme.emeraldGreen),
          _buildMetricCard("LOW STOCK", "$lowStockCount Items", "Alert", false, Colors.orange),
          _buildMetricCard("OUT OF STOCK", "$outOfStockCount Items", "Critical", false, Colors.redAccent),
        ], isMobile),
        const SizedBox(height: 48),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AdminTheme.softShadow,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _buildTableEnterpriseHeader("Kitchen Material Audit Ledger"),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildStockTableHeader(),
                    const Divider(height: 32, thickness: 1.5),
                    ...stockData.asMap().entries.map((entry) => _buildStockDataRow(entry.key + 1, entry.value)),
                    const SizedBox(height: 24),
                    _buildStockTotalRow(totalValuation),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- REUSABLE PRIVATE UI HELPERS ---

  Widget _buildAdvancedFilterBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Wrap(
        spacing: 16, runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildFilterItem("From", DateFormat('dd-MM-yyyy').format(_fromDate), onTap: () => _selectDate(true)),
          _buildFilterItem("To", DateFormat('dd-MM-yyyy').format(_toDate), onTap: () => _selectDate(false)),
          ElevatedButton(
            onPressed: () => _loadData(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            child: const Text("Search", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            child: const Text("Print", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  Widget _buildFilterItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text("$label  ", style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _buildFilterDropdown(String hint) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)), const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey)]));
  }

  Widget _buildFilterInput(String hint) {
    return Container(width: 150, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)));
  }

  Widget _buildImage3MetricCard(String title, String value, String growth, bool isPositive, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)), Text(growth, style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13))]),
      ]),
    );
  }

  Widget _buildMetricCard(String label, String value, String growth, bool isPositive, Color color, {double? width}) {
    return Container(
        width: width,
        padding: const EdgeInsets.all(32), 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          border: Border.all(color: Colors.grey.shade100),
        ), 
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Container(
                  padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(14)
                  ), 
                  child: Icon(Icons.show_chart_rounded, color: color, size: 24)
                ), 
                const SizedBox(height: 24), 
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)), 
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(color: AdminTheme.darkNavy, fontSize: 28, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              ]
            ),
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AdminTheme.emeraldGreen : Colors.redAccent).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  growth.toUpperCase(), 
                  style: TextStyle(color: isPositive ? AdminTheme.emeraldGreen : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        )
    );
  }

  Widget _buildSummaryGrid(List<Widget> cards, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate width based on screen size
        int crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1100 ? 2 : 3);
        double spacing = 16.0;
        double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title) => Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.8));

  Widget _buildTableHeader(String label, int flex, {TextAlign align = TextAlign.left}) => Expanded(
    flex: flex, 
    child: Text(
      label, 
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
      textAlign: align,
    )
  );

  Widget _buildSearchBar(String hint) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 24), height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow, border: Border.all(color: Colors.grey.shade100)), child: TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(icon: const Icon(Icons.search, color: AdminTheme.royalBlue, size: 20), hintText: hint, border: InputBorder.none, hintStyle: const TextStyle(fontSize: 13, color: Colors.grey))));
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_outlined, size: 18), label: const Text("EXPORT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.darkNavy, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  Widget _buildTableEnterpriseHeader(String title) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)), const Row(children: [Icon(Icons.refresh, size: 16, color: Colors.grey), SizedBox(width: 12), Icon(Icons.fullscreen, size: 16, color: Colors.grey)])]));
  }

  // --- VISUALIZATION HELPERS ---
  Widget _buildSalesOverviewChart(double revenue, int orders) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Sales Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
        const SizedBox(height: 32),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: Column(
            children: [
              Expanded(child: CustomPaint(painter: _ModernChartPainter([400, 600, 500, 800, 700, 950, 850], color: Colors.blue), size: Size.infinite)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"].map((m) => Text(m, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildChartSubMetric("Monthly Sales", "\$${NumberFormat('#,###').format(revenue * 0.25)}"),
          _buildChartSubMetric("Orders", "${(orders / 4).round()}"),
        ]),
      ]),
    );
  }

  Widget _buildChartSubMetric(String label, String value) {
    return Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy))]);
  }

  Widget _buildFinancialBreakdownCard(double revenue, double employeeCost, double purchaseCost, double profit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Financial Breakdown (Visualized)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: CustomPaint(painter: _FinancialPiePainter(revenue, employeeCost, purchaseCost, profit), size: const Size(180, 180)),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          _buildBreakdownItem("Total Revenue", revenue, AdminTheme.royalBlue),
          _buildBreakdownItem("Employee Cost", employeeCost, Colors.redAccent),
          _buildBreakdownItem("Purchase Cost", purchaseCost, Colors.orangeAccent),
          _buildBreakdownItem("Net Profit", profit, AdminTheme.emeraldGreen, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, double value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isTotal ? AdminTheme.darkNavy : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          ]),
          Text("NPR ${NumberFormat('#,###').format(value)}", style: TextStyle(fontWeight: FontWeight.bold, color: isTotal ? color : AdminTheme.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Peak Dining Hours", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Column(
              children: [
                Expanded(child: CustomPaint(painter: _ModernChartPainter([20, 45, 15, 85, 95, 40, 10], color: Colors.orange), size: Size.infinite)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ["11am", "1pm", "3pm", "5pm", "7pm", "9pm", "11pm"].map((t) => Text(t, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStaffRankingCard(List<MapEntry<String, double>> staffSales) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AdminTheme.darkNavy, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("STAFF PERFORMANCE RANKING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1.8)),
            if (staffSales.isNotEmpty)
              const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 20),
          ],
        ),
        const SizedBox(height: 28),
        if (staffSales.isEmpty)
          const Center(child: Text("No staff data recorded", style: TextStyle(color: Colors.white54, fontSize: 12)))
        else
          ...staffSales.take(5).toList().asMap().entries.map((entry) {
            int idx = entry.key;
            var s = entry.value;
            bool isTop = idx == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(
                    children: [
                      Text(s.key, style: TextStyle(color: isTop ? Colors.amber : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      if (isTop) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("TOP", style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text("NPR ${NumberFormat('#,###').format(s.value)}", style: const TextStyle(color: AdminTheme.emeraldGreen, fontWeight: FontWeight.w900, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: staffSales.first.value > 0 ? s.value / staffSales.first.value : 0,
                    backgroundColor: Colors.white10,
                    color: isTop ? Colors.amber : AdminTheme.emeraldGreen,
                    minHeight: 4,
                  ),
                ),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _buildPurchaseTableHeader() {
    return Row(
      children: [
        _buildTableHeader("DATE", 2),
        _buildTableHeader("ITEM NAME", 3),
        _buildTableHeader("SUPPLIER", 3),
        _buildTableHeader("QTY", 1),
        _buildTableHeader("PRICE (NPR)", 2),
      ],
    );
  }

  Widget _buildPurchaseDataRow(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(p['purchase_date']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 12))),
          Expanded(flex: 3, child: Text(p['ingredient_name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy))),
          Expanded(flex: 3, child: Text(p['supplier_name']?.toString() ?? 'Direct', style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(flex: 1, child: Text("${p['quantity']} ${p['unit']}", style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text(NumberFormat('#,###').format(double.tryParse(p['total_price']?.toString() ?? '0') ?? 0), style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy))),
        ],
      ),
    );
  }

  Widget _buildPurchaseTotalRow(double total) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text("GRAND TOTAL PROCUREMENT: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          Text("NPR ${NumberFormat('#,###').format(total)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AdminTheme.royalBlue)),
        ],
      ),
    );
  }

  Widget _buildWaiterPerformanceChart(List<MapEntry<String, double>> topWaiters, bool isMobile) {
     // Replaced by _buildWaiterRevenueContributionChart for specific Waiter Report view
     return _buildWaiterRevenueContributionChart(topWaiters, isMobile);
  }

  Widget _buildStockVisualization(List<Map<String, dynamic>> items) {
    Map<String, double> categoryValuation = {};
    for (var item in items) {
      String cat = item['category'];
      double val = ((item['qty'] as num) * (item['price_per_unit'] as num)).toDouble();
      categoryValuation[cat] = (categoryValuation[cat] ?? 0) + val;
    }

    double totalVal = categoryValuation.values.fold(0, (s, v) => s + v);
    var sortedCategories = categoryValuation.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<Color> palette = [
      AdminTheme.royalBlue,
      AdminTheme.emeraldGreen,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.amber,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        
        return Container(
          width: double.infinity,
          height: isMobile ? 600 : 400,
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            color: AdminTheme.darkNavy,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AdminTheme.darkNavy.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: isMobile 
            ? Column(
                children: [
                  const Text("STOCK VALUATION BY CATEGORY", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 32),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 60,
                        startDegreeOffset: -90,
                        sections: sortedCategories.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var e = entry.value;
                          return PieChartSectionData(
                            color: palette[idx % palette.length],
                            value: e.value,
                            title: "${((e.value / (totalVal == 0 ? 1 : totalVal)) * 100).toStringAsFixed(0)}%",
                            radius: 40,
                            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: sortedCategories.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var e = entry.value;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: palette[idx % palette.length], shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text("${e.key}: NPR ${NumberFormat('#,###').format(e.value)}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 70,
                        startDegreeOffset: -90,
                        sections: sortedCategories.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var e = entry.value;
                          return PieChartSectionData(
                            color: palette[idx % palette.length],
                            value: e.value,
                            title: "${((e.value / (totalVal == 0 ? 1 : totalVal)) * 100).toStringAsFixed(0)}%",
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("VALUATION BY CATEGORY", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const SizedBox(height: 24),
                        ...sortedCategories.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var e = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: palette[idx % palette.length], shape: BoxShape.circle)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text("NPR ${NumberFormat('#,###').format(e.value)}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
        );
      }
    );
  }

  Widget _buildRegisterColumnChart(List<double> offlineCash, List<double> onlineCash, List<String> labels) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AdminTheme.darkNavy, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: AdminTheme.darkNavy.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("OFFLINE VS ONLINE SALES", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)), SizedBox(height: 8), Text("Offline Cash vs Online Cash", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
          Row(children: [
            _buildLegendDot("Offline", AdminTheme.royalBlue),
            const SizedBox(width: 16),
            _buildLegendDot("Online", AdminTheme.emeraldGreen),
          ]),
        ]),
        const SizedBox(height: 50),
        SizedBox(height: 220, child: CustomPaint(
          painter: _RegisterColumnPainter(
            offlineCash: offlineCash,
            onlineCash: onlineCash,
            labels: labels,
          ), 
          size: Size.infinite
        )),
      ]),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))]);
  }

  Widget _buildChannelDistributionCard(List<MapEntry<String, double>> data, double total, bool isDemo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 450;
        
        return Container(
          height: isNarrow ? 500 : 400,
          padding: EdgeInsets.all(isNarrow ? 20 : 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SALES BY CHANNEL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text("Revenue Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
              const Spacer(),
              Expanded(
                flex: 10,
                child: isNarrow 
                ? Column(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 50,
                            startDegreeOffset: -90,
                            sections: data.map((e) {
                              return PieChartSectionData(
                                color: _getChannelColor(e.key),
                                value: e.value,
                                title: "${((e.value / total) * 100).toStringAsFixed(0)}%",
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: data.map((e) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: _getChannelColor(e.key), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                          ],
                        )).toList(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 70,
                            startDegreeOffset: -90,
                            sections: data.map((e) {
                              return PieChartSectionData(
                                color: _getChannelColor(e.key),
                                value: e.value,
                                title: "${((e.value / total) * 100).toStringAsFixed(0)}%",
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: data.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: _getChannelColor(e.key), shape: BoxShape.circle)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                                      Text("NPR ${NumberFormat('#,###').format(e.value)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
              ),
              const Spacer(),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDeliveryInsightsCard(Map<String, double> sales, Map<String, int> counts) {
    double totalRevenue = sales.values.fold(0, (s, v) => s + v);
    int totalOrders = counts.values.fold(0, (s, v) => s + v);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildTableEnterpriseHeader("Channel Performance Ledger"),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildTableHeader("CHANNEL NAME", 3),
                      _buildTableHeader("TOTAL ORDERS", 2, align: TextAlign.center),
                      _buildTableHeader("NET SALES", 2, align: TextAlign.right),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...sales.entries.map((e) {
                  int orders = counts[e.key] ?? 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Icon(_getChannelIcon(e.key), size: 16, color: _getChannelColor(e.key)),
                              const SizedBox(width: 12),
                              Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.darkNavy)),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text("$orders", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(e.value)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.royalBlue), textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(color: AdminTheme.darkNavy, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text("TOTAL CHANNEL SUMMARY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white70, letterSpacing: 1))),
                      Expanded(flex: 2, child: Text("$totalOrders Orders", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), textAlign: TextAlign.center)),
                      const Expanded(flex: 2, child: SizedBox()),
                      Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(totalRevenue)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AdminTheme.emeraldGreen), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChannelIcon(String channel) {
    switch (channel) {
      case 'Employee (Waiter Order)': return Icons.person_pin_rounded;
      case 'Customer Order': return Icons.qr_code_scanner_rounded;
      default: return Icons.point_of_sale;
    }
  }

  Widget _buildTransactionRow(Map<String, dynamic> o) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Row(children: [
      Expanded(flex: 2, child: Text("${o['id']}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy, fontSize: 13))),
      Expanded(flex: 2, child: Text("${o['type']}", style: const TextStyle(fontSize: 12, color: Colors.grey))),
      Expanded(flex: 2, child: Text("NPR ${o['amount']}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy))),
      Expanded(flex: 2, child: Text("${o['status']}", style: const TextStyle(color: AdminTheme.emeraldGreen, fontSize: 9, fontWeight: FontWeight.w900))),
    ]));
  }

  Widget _buildRegisterTableHeader(bool isMobile) => Row(children: [
    _buildTableHeader("SN", 1),
    _buildTableHeader("DATE/TIME", 3),
    _buildTableHeader("CASHIER", 2),
    _buildTableHeader("OFFLINE CASH", 2, align: TextAlign.right),
    _buildTableHeader("ONLINE CASH", 2, align: TextAlign.right),
    _buildTableHeader("TOTAL", 2, align: TextAlign.right),
    _buildTableHeader("DISCREPANCY", 2, align: TextAlign.right),
  ]);
  
  Widget _buildRegisterDataRow(Map<String, dynamic> s, bool isMobile) {
    final double discrepancy = s['discrepancy'] ?? 0.0;
    Color discColor = Colors.orange;
    if (discrepancy == 0) discColor = AdminTheme.emeraldGreen;
    if (discrepancy < 0) discColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(s['sn'].toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['date'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(s['time'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )),
          Expanded(flex: 2, child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AdminTheme.royalBlue.withOpacity(0.1),
                child: Text(s['cashier'][0], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(s['cashier'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          )),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(s['offline_cash'])}", style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(s['online_cash'])}", style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(s['total_sales'])}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(
            "${discrepancy >= 0 ? '+' : ''}${NumberFormat('#,###').format(discrepancy)}",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: discColor),
            textAlign: TextAlign.right,
          )),
        ],
      ),
    );
  }

  Widget _buildRegisterTotalRow(double offline, double online, double total, double discrepancy, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(flex: 6, child: Text("GRAND TOTAL AUDIT", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(offline)}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(online)}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(total)}", style: const TextStyle(color: AdminTheme.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w900), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(discrepancy)}", style: TextStyle(color: discrepancy < 0 ? Colors.redAccent : AdminTheme.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w900), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildStockTableHeader() => Row(
    children: [
      _buildTableHeader("SN", 1),
      _buildTableHeader("ITEM NAME", 3),
      _buildTableHeader("CATEGORY", 2),
      _buildTableHeader("QTY/UNIT", 2, align: TextAlign.center),
      _buildTableHeader("STATUS", 2, align: TextAlign.center),
      _buildTableHeader("VALUATION", 2, align: TextAlign.right),
    ],
  );
  
  Widget _buildStockDataRow(int sn, Map<String, dynamic> s) {
    double qty = (s['qty'] as num).toDouble();
    double min = (s['min_stock'] as num).toDouble();
    double valuation = qty * (s['price_per_unit'] as num).toDouble();
    
    String status = "IN STOCK";
    Color statusColor = AdminTheme.emeraldGreen;
    
    if (qty == 0) {
      status = "OUT OF STOCK";
      statusColor = Colors.redAccent;
    } else if (qty < min) {
      status = "LOW STOCK";
      statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text("$sn", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 3, child: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy, fontSize: 13))),
          Expanded(
            flex: 2, 
            child: Row(
              children: [
                Icon(Icons.category_outlined, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(s['category'], style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            )
          ),
          Expanded(flex: 2, child: Text("${s['qty']} ${s['unit']}", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(
            flex: 2, 
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            )
          ),
          Expanded(
            flex: 2, 
            child: Text(
              "NPR ${NumberFormat('#,###').format(valuation)}", 
              style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue), 
              textAlign: TextAlign.right
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStockTotalRow(double total) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(
      color: AdminTheme.darkNavy,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Expanded(flex: 6, child: Text("GRAND TOTAL VALUATION", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))),
        Expanded(
          flex: 2, 
          child: Text(
            "NPR ${NumberFormat('#,###').format(total)}", 
            style: const TextStyle(color: AdminTheme.emeraldGreen, fontSize: 18, fontWeight: FontWeight.w900), 
            textAlign: TextAlign.right
          )
        ),
      ],
    ),
  );

  Widget _buildDataRowDemo(String d, String id, String amt, String sc, Color color) => Row(children: [Expanded(flex:2, child: Text(d)), Expanded(flex:2, child: Text(id)), Expanded(flex:2, child: Text(amt)), Expanded(flex:2, child: Text(sc))]);

  Widget _buildCashierRow(int sn, String name, int orders, double cash, double digital, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text("$sn", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminTheme.royalBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded, size: 16, color: AdminTheme.royalBlue),
                ),
                const SizedBox(width: 12),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy, fontSize: 14)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text("$orders", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.darkNavy))),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(cash)}", style: const TextStyle(fontSize: 14, color: AdminTheme.darkNavy))),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(digital)}", style: const TextStyle(fontSize: 14, color: AdminTheme.darkNavy))),
          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(total)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.emeraldGreen))),
        ],
      ),
    );
  }

  Widget _buildCashierSummaryVisual(bool isMobile) {
    final List<Map<String, dynamic>> cashiers = [
      {'sn': 1, 'name': 'Aayushma Singh', 'orders': 45, 'cash': 45000.0, 'digital': 55000.0, 'total': 100000.0},
      {'sn': 2, 'name': 'Binod Thapa', 'orders': 32, 'cash': 38000.0, 'digital': 28000.0, 'total': 66000.0},
      {'sn': 3, 'name': 'Chandra Kala', 'orders': 25, 'cash': 24000.0, 'digital': 20700.0, 'total': 44700.0},
    ];
    double maxVal = 55000.0;

    return Container(
      width: double.infinity,
      height: isMobile ? 320 : 400,
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CASHIER SETTLEMENT VISUALIZATION", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  Text("Cash vs Digital Comparison per Cashier", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem("Cash", AdminTheme.emeraldGreen),
                  const SizedBox(width: 16),
                  _buildLegendItem("Digital", AdminTheme.royalBlue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cashierName = cashiers[groupIndex]['name'] as String;
                      final type = rodIndex == 0 ? "Cash" : "Digital";
                      return BarTooltipItem(
                        "$cashierName ($type)\n",
                        const TextStyle(color: AdminTheme.darkNavy, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: "NPR ${NumberFormat('#,###').format(rod.toY)}",
                            style: TextStyle(
                              color: rodIndex == 0 ? AdminTheme.emeraldGreen : AdminTheme.royalBlue, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 14
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= cashiers.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            (cashiers[index]['name'] as String).split(' ').first,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: cashiers.asMap().entries.map((entry) {
                  int index = entry.key;
                  double cashVal = (entry.value['cash'] as num).toDouble();
                  double digitalVal = (entry.value['digital'] as num).toDouble();
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: cashVal,
                        gradient: const LinearGradient(
                          colors: [AdminTheme.emeraldGreen, Color(0xFF66BB6A)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: isMobile ? 12 : 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: digitalVal,
                        gradient: const LinearGradient(
                          colors: [AdminTheme.royalBlue, Color(0xFF5A9BD5)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: isMobile ? 12 : 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildKitchenRow(Map<String, dynamic> log) => Row(children: [Text(log['time']), Text(log['item']), Text(log['status'])]);

  Widget _buildProgressInsight(String l, double p, Color c) => LinearProgressIndicator(value: p, color: c);

  Widget _buildServiceChargeRow(Map<String, dynamic> o) => Container();

  Widget _buildProfessionalTable(bool isMobile, bool isDemo) => Container();

  // --- 11. PURCHASE (PROCUREMENT) REPORT ---
  Widget _buildPurchaseReportView(bool isMobile) {
    final List<Map<String, dynamic>> purchases = [
      {'date': '2026-09-10', 'invoice': 'INV-901', 'supplier': 'Annapurna Veggies', 'total': 12500.0, 'paid': 12500.0, 'due': 0.0, 'status': 'PAID'},
      {'date': '2026-09-12', 'invoice': 'INV-905', 'supplier': 'City Dairy Hub', 'total': 8400.0, 'paid': 4000.0, 'due': 4400.0, 'status': 'PARTIAL'},
      {'date': '2026-09-14', 'invoice': 'INV-912', 'supplier': 'Everest Meat Center', 'total': 22000.0, 'paid': 0.0, 'due': 22000.0, 'status': 'DUE'},
      {'date': '2026-09-15', 'invoice': 'INV-918', 'supplier': 'Bhojon Masala', 'total': 5600.0, 'paid': 5600.0, 'due': 0.0, 'status': 'PAID'},
    ];

    double totalProc = purchases.fold(0, (sum, p) => sum + p['total']);
    double totalPaid = purchases.fold(0, (sum, p) => sum + p['paid']);
    double totalDue = purchases.fold(0, (sum, p) => sum + p['due']);
    double totalReturns = 2450.0; // Simulated returns

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPurchaseTrendChart(isMobile),
        const SizedBox(height: 32),
        _buildSummaryGrid([
          _buildMetricCard("TOTAL PROCUREMENT", "NPR ${NumberFormat('#,###').format(totalProc)}", "Inventory Cost", true, AdminTheme.royalBlue),
          _buildMetricCard("TOTAL PAID", "NPR ${NumberFormat('#,###').format(totalPaid)}", "Settled", true, AdminTheme.emeraldGreen),
          _buildMetricCard("TOTAL DUE", "NPR ${NumberFormat('#,###').format(totalDue)}", "Payable", false, Colors.redAccent),
          _buildMetricCard("TOTAL RETURNS", "NPR ${NumberFormat('#,###').format(totalReturns)}", "Returned Valuation", true, Colors.orange),
        ], isMobile),
        const SizedBox(height: 48),
        _buildPurchaseLedger(purchases, isMobile),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPurchaseTrendChart(bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 320 : 400,
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PROCUREMENT EXPENDITURE TREND", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text("Monthly Purchase Analysis", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 50000,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"];
                        if (value < 0 || value >= months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(months[value.toInt()], style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makePurchaseGroup(0, 32000),
                  _makePurchaseGroup(1, 45000),
                  _makePurchaseGroup(2, 28000),
                  _makePurchaseGroup(3, 38500),
                  _makePurchaseGroup(4, 15000),
                  _makePurchaseGroup(5, 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makePurchaseGroup(int x, double y) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: AdminTheme.royalBlue,
        width: 30,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(show: true, toY: 50000, color: Colors.white.withOpacity(0.05)),
      )
    ]);
  }

  Widget _buildPurchaseLedger(List<Map<String, dynamic>> data, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildTableEnterpriseHeader("Procurement Audit Ledger"),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildTableHeader("DATE", 2),
                      _buildTableHeader("INVOICE #", 2),
                      _buildTableHeader("SUPPLIER", 3),
                      _buildTableHeader("TOTAL", 2, align: TextAlign.right),
                      if (!isMobile) ...[
                        _buildTableHeader("PAID", 2, align: TextAlign.right),
                        _buildTableHeader("DUE", 2, align: TextAlign.right),
                      ],
                      _buildTableHeader("STATUS", 2, align: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...data.map((p) {
                  Color statusColor = Colors.grey;
                  if (p['status'] == 'PAID') statusColor = AdminTheme.emeraldGreen;
                  if (p['status'] == 'PARTIAL') statusColor = Colors.orange;
                  if (p['status'] == 'DUE') statusColor = Colors.redAccent;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(p['date'], style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 2, child: Text(p['invoice'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(flex: 3, child: Text(p['supplier'], style: const TextStyle(fontWeight: FontWeight.w600, color: AdminTheme.darkNavy))),
                        Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(p['total'])}", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        if (!isMobile) ...[
                          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(p['paid'])}", textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(p['due'])}", style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.right)),
                        ],
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(p['status'], style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getChannelColor(String channel) {
    switch (channel) {
      case 'Employee (Waiter Order)': return AdminTheme.royalBlue;
      case 'Customer Order': return AdminTheme.emeraldGreen;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildSaleFilteringView(bool isMobile) {
    return _buildFullSalesReportView(isMobile); // Reusing logic with date filters applied
  }

  Widget _buildSaleByDateView(bool isMobile) {
    return _buildFullSalesReportView(isMobile);
  }

  Widget _buildCommissionReportView(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryGrid([
          _buildMetricCard("TOTAL COMMISSION", "NPR 8,450", "Platform Fee", true, Colors.deepPurple),
          _buildMetricCard("PENDING PAYOUT", "NPR 1,200", "Settlement", false, Colors.orange),
        ], isMobile),
        const SizedBox(height: 48),
        _buildSectionTitle("Commission Ledger"),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(28), child: Row(children: [_buildTableHeader("DATE", 2), _buildTableHeader("ORDER", 2), _buildTableHeader("COMMISSION", 2), _buildTableHeader("STATUS", 2)])),
              const Divider(height: 1),
              _buildCommissionRow("13 Sep 2026", "#1052", "NPR 125.00", "Paid"),
              _buildCommissionRow("14 Sep 2026", "#1053", "NPR 85.00", "Paid"),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionRow(String date, String order, String amt, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(order, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(amt, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue))),
          Expanded(flex: 2, child: Text(status, style: const TextStyle(color: AdminTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildGenericReportList() => const Center(child: Text("No data found."));

  IconData _getFoodCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beverage': return Icons.local_drink_outlined;
      case 'non-veg': return Icons.restaurant_menu;
      case 'veg': return Icons.eco_outlined;
      case 'bakery': return Icons.cake_outlined;
      default: return Icons.fastfood_outlined;
    }
  }

  Widget _buildFoodStockChart(List<Map<String, dynamic>> items, bool isMobile) {
    double maxVal = items.fold(0.0, (max, item) {
      double q = (item['qty'] as num).toDouble();
      double m = (item['min_stock'] as num).toDouble();
      double localMax = q > m ? q : m;
      return localMax > max ? localMax : max;
    });
    if (maxVal == 0) maxVal = 10;

    return Container(
      width: double.infinity,
      height: isMobile ? 350 : 420,
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("INVENTORY LEVELS VISUALIZATION", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  Text("Current Stock vs. Minimum Threshold", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _buildLegendDot("Stock", AdminTheme.royalBlue),
                  const SizedBox(width: 16),
                  _buildLegendDot("Min Level", Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${items[groupIndex]['name']}\n",
                        const TextStyle(color: AdminTheme.darkNavy, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(text: "${rod.toY.toStringAsFixed(0)} Units", style: TextStyle(color: rodIndex == 0 ? AdminTheme.royalBlue : Colors.grey, fontWeight: FontWeight.w900)),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= items.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(items[index]['name'], style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: items.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(toY: (entry.value['qty'] as num).toDouble(), color: AdminTheme.royalBlue, width: isMobile ? 8 : 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                      BarChartRodData(toY: (entry.value['min_stock'] as num).toDouble(), color: Colors.grey.shade600, width: isMobile ? 8 : 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemStockView(List<Map<String, dynamic>> products, bool isMobile) {
    final List<Map<String, dynamic>> foodStockData = [
      {'name': 'Coca-Cola', 'category': 'Beverage', 'qty': 120, 'min_stock': 30, 'price': 100.0},
      {'name': 'Chicken Burger', 'category': 'Non-Veg', 'qty': 15, 'min_stock': 25, 'price': 250.0},
      {'name': 'Veg MoMo', 'category': 'Veg', 'qty': 45, 'min_stock': 20, 'price': 150.0},
      {'name': 'Chocolate Cake', 'category': 'Bakery', 'qty': 0, 'min_stock': 5, 'price': 350.0},
      {'name': 'Espresso', 'category': 'Beverage', 'qty': 8, 'min_stock': 15, 'price': 120.0},
      {'name': 'Water Bottle', 'category': 'Beverage', 'qty': 200, 'min_stock': 50, 'price': 30.0},
    ];

    double totalValuation = foodStockData.fold(0.0, (sum, item) => sum + ((item['qty'] as num) * (item['price'] as num)));
    int reorderRequired = foodStockData.where((item) => (item['qty'] as num) > 0 && (item['qty'] as num) < (item['min_stock'] as num)).length;
    int criticalStatus = foodStockData.where((item) => (item['qty'] as num) == 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFoodStockChart(foodStockData, isMobile),
        const SizedBox(height: 32),
        _buildSummaryGrid([
          _buildMetricCard("TOTAL SKUs", "${foodStockData.length}", "Catalog", true, AdminTheme.royalBlue),
          _buildMetricCard("STOCK VALUATION", "NPR ${NumberFormat('#,###').format(totalValuation)}", "Asset Value", true, AdminTheme.emeraldGreen),
          _buildMetricCard("REORDER REQUIRED", "$reorderRequired Items", "Low Stock", false, Colors.orange),
          _buildMetricCard("CRITICAL STATUS", "$criticalStatus Items", "Out of Stock", false, Colors.redAccent),
        ], isMobile),
        const SizedBox(height: 48),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow, border: Border.all(color: Colors.grey.shade100)),
          child: Column(
            children: [
              _buildTableEnterpriseHeader("Ready-to-Sell Inventory Audit Ledger"),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                child: Row(
                  children: [
                    _buildTableHeader("SN", 1),
                    _buildTableHeader("ITEM NAME", 3),
                    _buildTableHeader("CATEGORY", 2),
                    _buildTableHeader("QTY", 2, align: TextAlign.center),
                    _buildTableHeader("MIN LEVEL", 2, align: TextAlign.center),
                    _buildTableHeader("STATUS", 2, align: TextAlign.center),
                    _buildTableHeader("VALUATION", 2, align: TextAlign.right),
                  ],
                ),
              ),
              ...foodStockData.asMap().entries.map((entry) {
                var item = entry.value;
                int qty = item['qty'];
                int min = item['min_stock'];
                String status = qty == 0 ? "EMPTY" : (qty < min ? "LOW" : "READY");
                Color statusColor = qty == 0 ? Colors.redAccent : (qty < min ? Colors.orange : AdminTheme.emeraldGreen);

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text("${entry.key + 1}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.darkNavy))),
                      Expanded(flex: 2, child: Row(children: [Icon(_getFoodCategoryIcon(item['category']), size: 14, color: Colors.grey), const SizedBox(width: 6), Text(item['category'], style: const TextStyle(color: Colors.grey, fontSize: 13))])),
                      Expanded(flex: 2, child: Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text("$min", style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900))))),
                      Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(qty * item['price'])}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.emeraldGreen), textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: const BoxDecoration(color: AdminTheme.darkNavy, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
                child: Row(
                  children: [
                    const Expanded(flex: 6, child: Text("GRAND TOTAL VALUATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white70))),
                    Expanded(flex: 2, child: Text("NPR ${NumberFormat('#,###').format(totalValuation)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AdminTheme.emeraldGreen), textAlign: TextAlign.right)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegisterColumnPainter extends CustomPainter {
  final List<double> offlineCash;
  final List<double> onlineCash;
  final List<String> labels;

  _RegisterColumnPainter({
    required this.offlineCash,
    required this.onlineCash,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;

    double maxVal = 0;
    for (int i = 0; i < labels.length; i++) {
      if (offlineCash[i] > maxVal) maxVal = offlineCash[i];
      if (onlineCash[i] > maxVal) maxVal = onlineCash[i];
    }
    if (maxVal == 0) maxVal = 1;

    final double groupWidth = size.width / labels.length;
    final double barWidth = groupWidth * 0.25;
    const double barSpacing = 6.0;

    final Paint offlinePaint = Paint()..color = AdminTheme.royalBlue;
    final Paint onlinePaint = Paint()..color = AdminTheme.emeraldGreen;

    for (int i = 0; i < labels.length; i++) {
      double xGroupCenter = i * groupWidth + groupWidth / 2;
      double xOffline = xGroupCenter - barWidth - barSpacing / 2;
      double xOnline = xGroupCenter + barSpacing / 2;

      // Offline Bar
      double hOffline = (offlineCash[i] / maxVal) * size.height;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(xOffline, size.height - hOffline, barWidth, hOffline), const Radius.circular(4)),
          offlinePaint);
      _drawText(canvas, _formatValue(offlineCash[i]), Offset(xOffline + barWidth / 2, size.height - hOffline - 18));

      // Online Bar
      double hOnline = (onlineCash[i] / maxVal) * size.height;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(xOnline, size.height - hOnline, barWidth, hOnline), const Radius.circular(4)),
          onlinePaint);
      _drawText(canvas, _formatValue(onlineCash[i]), Offset(xOnline + barWidth / 2, size.height - hOnline - 18));

      // Label
      _drawText(canvas, labels[i], Offset(xGroupCenter, size.height + 20), isLabel: true);
    }
  }

  String _formatValue(double value) => value >= 1000 ? "${(value / 1000).toStringAsFixed(1)}K" : value.toStringAsFixed(0);

  void _drawText(Canvas canvas, String text, Offset offset, {bool isLabel = false}) {
    final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: isLabel ? Colors.white70 : Colors.white,
                fontSize: isLabel ? 10 : 9,
                fontWeight: isLabel ? FontWeight.bold : FontWeight.w500)),
        textDirection: ui.TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ModernChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _ModernChartPainter(this.data, {this.color = AdminTheme.royalBlue});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = ui.StrokeCap.round;
    final path = Path();
    final areaPath = Path();
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;
    double stepX = size.width / (data.length - 1);
    double getY(double val) => size.height - (val / maxVal * size.height * 0.85);
    path.moveTo(0, getY(data[0]));
    areaPath.moveTo(0, size.height);
    areaPath.lineTo(0, getY(data[0]));
    for (int i = 1; i < data.length; i++) {
      double x = i * stepX;
      double y = getY(data[i]);
      path.lineTo(x, y);
      areaPath.lineTo(x, y);
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.close();
    final areaPaint = Paint()..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, size.height), [color.withValues(alpha: 0.2), color.withValues(alpha: 0.01)])..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, paint);
    final markerPaint = Paint()..color = color..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y = getY(data[i]);
      canvas.drawCircle(Offset(x, y), 5, strokePaint);
      canvas.drawCircle(Offset(x, y), 3, markerPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 22..strokeCap = ui.StrokeCap.round;
    canvas.drawCircle(center, radius, Paint()..color = Colors.grey.shade100..style = PaintingStyle.stroke..strokeWidth = 22);
    canvas.drawArc(rect, -1.5, 2.2, false, paint..color = Colors.blue);
    canvas.drawArc(rect, 0.8, 1.2, false, paint..color = Colors.green);
    canvas.drawArc(rect, 2.1, 0.8, false, paint..color = Colors.orange);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FinancialPiePainter extends CustomPainter {
  final double revenue;
  final double employeeCost;
  final double purchaseCost;
  final double profit;
  _FinancialPiePainter(this.revenue, this.employeeCost, this.purchaseCost, this.profit);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 20..strokeCap = ui.StrokeCap.round;
    
    double total = revenue;
    if (total == 0) total = 1;
    
    double startAngle = -3.1415926 / 2;
    
    // Employee Cost
    double employeeSweep = (employeeCost / total) * 2 * 3.1415926;
    paint.color = Colors.redAccent;
    canvas.drawArc(rect, startAngle, employeeSweep - 0.05, false, paint);
    
    // Purchase Cost
    double purchaseSweep = (purchaseCost / total) * 2 * 3.1415926;
    paint.color = Colors.orangeAccent;
    canvas.drawArc(rect, startAngle + employeeSweep, purchaseSweep - 0.05, false, paint);
    
    // Net Profit
    double profitSweep = (profit / total) * 2 * 3.1415926;
    paint.color = AdminTheme.emeraldGreen;
    canvas.drawArc(rect, startAngle + employeeSweep + purchaseSweep, profitSweep - 0.05, false, paint);
    
    final tp = TextPainter(text: TextSpan(text: "TOTAL\nNPR ${(revenue / 1000).toStringAsFixed(0)}K", style: const TextStyle(color: AdminTheme.darkNavy, fontSize: 13, fontWeight: FontWeight.w900, height: 1.4)), textAlign: TextAlign.center, textDirection: ui.TextDirection.ltr);
    tp.layout(); tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ItemBarChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  _ItemBarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final double maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double barWidth = size.width / (data.length * 1.5);
    final double spacing = (size.width - (barWidth * data.length)) / (data.length + 1);

    for (int i = 0; i < data.length; i++) {
      double x = spacing + i * (barWidth + spacing);
      double h = (data[i].value / (maxVal == 0 ? 1 : maxVal)) * size.height * 0.8;
      
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, size.height),
          Offset(x, size.height - h),
          [AdminTheme.royalBlue, AdminTheme.royalBlue.withValues(alpha: 0.6)],
        )
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barWidth, h), const Radius.circular(8)),
        paint,
      );

      // Value label
      final tp = TextPainter(
        text: TextSpan(
          text: "${(data[i].value / 1000).toStringAsFixed(1)}K",
          style: const TextStyle(color: AdminTheme.darkNavy, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x + (barWidth - tp.width) / 2, size.height - h - 18));

      // Name label (Vertical or truncated)
      final name = data[i].key.length > 8 ? "${data[i].key.substring(0, 7)}.." : data[i].key;
      final np = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      np.layout();
      np.paint(canvas, Offset(x + (barWidth - np.width) / 2, size.height + 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
