import 'package:flutter/material.dart';
import '../../services/tenant_service.dart';
import '../../services/api_service.dart';
import '../../cart_manager.dart';
import '../admin_theme.dart';

import '../../services/language_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().currentLanguageCode,
      builder: (context, _, __) {
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 900;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoHeader(),
                    const SizedBox(height: 32),
                    
                    if (isWide) 
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildPremiumStatsGrid()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildSubscriptionSummaryCard()),
                        ],
                      )
                    else ...[
                      _buildSubscriptionSummaryCard(),
                      const SizedBox(height: 24),
                      _buildPremiumStatsGrid(),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildSalesPerformanceChart()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildPopularItemsSection()),
                        ],
                      )
                    else ...[
                      _buildSalesPerformanceChart(),
                      const SizedBox(height: 32),
                      _buildPopularItemsSection(),
                    ],

                    const SizedBox(height: 32),
                    
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildLiveTableStatus()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildRecentTransactions()),
                        ],
                      )
                    else ...[
                      _buildLiveTableStatus(),
                      const SizedBox(height: 32),
                      _buildRecentTransactions(),
                    ],
                    
                    const SizedBox(height: 32),
                    _buildKitchenAlertsWidget(),
                  ],
                );
              }
            ),
          ),
        );
      }
    );
  }

  Widget _buildUserInfoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hi, Admin",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy),
            ),
            Row(
              children: const [
                Icon(Icons.phone, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text("REST-CHY-001", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const CircleAvatar(
          radius: 22,
          backgroundColor: AdminTheme.royalBlue,
          child: Icon(Icons.person, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSummaryCard() {
    return ValueListenableBuilder<Tenant?>(
      valueListenable: TenantService().currentTenant,
      builder: (context, tenant, child) {
        if (tenant == null) return const SizedBox.shrink();

        final now = DateTime.now();
        DateTime expiryDate = now.add(const Duration(days: 10)); // Fallback
        try {
          if (tenant.expiry != null) expiryDate = DateTime.parse(tenant.expiry!);
        } catch (_) {}
        
        final daysLeft = expiryDate.difference(now).inDays.clamp(0, 365);
        final bool isWarning = daysLeft < 7;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isWarning ? Colors.red[50] : AdminTheme.emeraldGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isWarning ? Colors.red : AdminTheme.emeraldGreen).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isWarning ? Colors.red : AdminTheme.emeraldGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Plan: ${tenant.plan}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isWarning ? Colors.red[900] : AdminTheme.darkNavy,
                      ),
                    ),
                    Text(
                      "$daysLeft days remaining in your subscription.",
                      style: TextStyle(
                        fontSize: 10,
                        color: isWarning ? Colors.red[700] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // This is a bit tricky since we are in a sub-screen. 
                  // In a real app, we'd use a provider or callback.
                  // For now, it just shows info.
                },
                child: Text(
                  "DETAILS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isWarning ? Colors.red : AdminTheme.emeraldGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumStatsGrid() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ShopManager.instance.allHistoricalBills,
      builder: (context, bills, child) {
        double totalRevenue = 0;
        int completedOrders = 0;
        for (var bill in bills) {
          totalRevenue += double.tryParse(bill['total'].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          if (bill['status'] == 'Paid' || bill['status'] == 'Complete') completedOrders++;
        }
        double avgOrder = bills.isEmpty ? 0 : totalRevenue / bills.length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _buildStatMetricCard("Total Revenue", "NPR ${totalRevenue.toStringAsFixed(0)}", "+12.5%", Icons.payments_rounded, AdminTheme.royalBlue),
            _buildStatMetricCard("Total Orders", bills.length.toString(), "+8.2%", Icons.shopping_bag_rounded, AdminTheme.emeraldGreen),
            _buildStatMetricCard("Avg. Check", "NPR ${avgOrder.toStringAsFixed(0)}", "-2.4%", Icons.analytics_rounded, Colors.orange),
            _buildStatMetricCard("Active Customers", "42", "+18%", Icons.people_rounded, Colors.purple),
          ],
        );
      }
    );
  }

  Widget _buildStatMetricCard(String title, String value, String growth, IconData icon, Color color) {
    bool isPositive = growth.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              growth,
              style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sales Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              DropdownButton<String>(
                value: "Weekly",
                underline: const SizedBox(),
                items: ["Daily", "Weekly", "Monthly"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final double val = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4][i];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: 160 * val,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AdminTheme.royalBlue, AdminTheme.royalBlue.withValues(alpha: 0.3)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(["M", "T", "W", "T", "F", "S", "S"][i], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItemsSection() {
    final items = [
      {'name': 'Chicken MoMo', 'orders': '124', 'revenue': 'NPR 18,600', 'img': Icons.restaurant},
      {'name': 'Cold Coffee', 'orders': '85', 'revenue': 'NPR 12,750', 'img': Icons.local_cafe},
      {'name': 'Veg Burger', 'orders': '62', 'revenue': 'NPR 9,300', 'img': Icons.lunch_dining},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Popular Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
          const SizedBox(height: 24),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Icon(item['img'] as IconData, color: AdminTheme.royalBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("${item['orders']} orders today", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                Text(item['revenue'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AdminTheme.emeraldGreen)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildLiveTableStatus() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Live Table Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildTableMiniStat("8", "Occupied", Colors.red),
              const SizedBox(width: 16),
              _buildTableMiniStat("12", "Available", Colors.green),
              const SizedBox(width: 16),
              _buildTableMiniStat("4", "Reserved", Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (i) => Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (i < 4 ? Colors.red : (i < 9 ? Colors.green : Colors.orange)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (i < 4 ? Colors.red : (i < 9 ? Colors.green : Colors.orange)).withValues(alpha: 0.3)),
              ),
              child: Center(child: Text("T${i+1}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: i < 4 ? Colors.red : (i < 9 ? Colors.green : Colors.orange)))),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTableMiniStat(String count, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ShopManager.instance.allHistoricalBills,
      builder: (context, bills, child) {
        final recent = bills.reversed.take(5).toList();
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AdminTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              const SizedBox(height: 24),
              if (recent.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No transactions yet", style: TextStyle(color: Colors.grey))))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 24),
                  itemBuilder: (ctx, i) {
                    final b = recent[i];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1),
                          child: const Icon(Icons.receipt_long_rounded, color: AdminTheme.royalBlue, size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['customer'] ?? 'Walk-in Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(b['id'] ?? '#INV-000', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(b['total'] ?? '0.00', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            Text(b['status'] ?? 'Paid', style: TextStyle(color: (b['status'] == 'Paid' || b['status'] == 'Complete') ? Colors.green : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      }
    );
  }


  Widget _buildKitchenAlertsWidget() {
    final tenant = TenantService().currentTenant.value;
    if (tenant == null) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: ApiService.fetchStockReports(tenant.id),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Kitchen Alerts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(10)),
                  child: Text("${alerts.length} NEW", style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
              child: Column(
                children: alerts.take(3).map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: (a['urgency'] == 'Critical' ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                        child: Icon(Icons.warning_amber_rounded, size: 14, color: a['urgency'] == 'Critical' ? Colors.red : Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['item_name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(a['notes'] ?? 'Out of stock', style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Text(a['urgency'] ?? 'Medium', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: a['urgency'] == 'Critical' ? Colors.red : Colors.orange)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        );
      }
    );
  }
}
