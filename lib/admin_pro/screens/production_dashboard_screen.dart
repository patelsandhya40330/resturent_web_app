import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../admin_theme.dart';

class ProductionDashboardScreen extends StatelessWidget {
  final String title;
  const ProductionDashboardScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryBar(),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildLiveStationsSection()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildOperationalInsights()),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildInventoryAlertSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Row(
      children: [
        _buildMiniStatCard("Active Orders", "24", AdminTheme.royalBlue, "+12%"),
        const SizedBox(width: 12),
        _buildMiniStatCard("Avg. Prep Time", "12m", Colors.orange, "-2m"),
        const SizedBox(width: 12),
        _buildMiniStatCard("SLA Breaches", "02", Colors.red, "High"),
        const SizedBox(width: 12),
        _buildMiniStatCard("Staff Active", "08", AdminTheme.emeraldGreen, "Full"),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color, String trend) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(trend, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Station Load Balancing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
            TextButton(onPressed: () {}, child: const Text("MANAGE FLOW", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStationCard("Main Hot Kitchen", "08 Orders", "Overloaded", Colors.red, 0.85),
            _buildStationCard("Beverage Bar", "04 Orders", "Optimal", AdminTheme.emeraldGreen, 0.40),
            _buildStationCard("Bakery & Pastry", "02 Orders", "Light", Colors.blue, 0.20),
            _buildStationCard("Cold Station", "03 Orders", "Optimal", AdminTheme.emeraldGreen, 0.35),
          ],
        ),
      ],
    );
  }

  Widget _buildStationCard(String name, String load, String status, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.flash_on, color: color, size: 14),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(load, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[100],
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Kitchen Efficiency", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AdminTheme.darkNavy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text("Today's Output", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("142 Meals", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              SizedBox(
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(color: AdminTheme.emeraldGreen, value: 70, radius: 12, showTitle: false),
                      PieChartSectionData(color: Colors.orange, value: 20, radius: 10, showTitle: false),
                      PieChartSectionData(color: Colors.red, value: 10, radius: 8, showTitle: false),
                    ],
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildEfficiencyLegend("On Time", "70%", AdminTheme.emeraldGreen),
              _buildEfficiencyLegend("Slight Delay", "20%", Colors.orange),
              _buildEfficiencyLegend("Delayed", "10%", Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyLegend(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInventoryAlertSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Critical Stock Alerts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red.withValues(alpha: 0.1))),
          child: Column(
            children: [
              _buildStockAlertItem("Whole Milk (Full Cream)", "05 Liters", "20L Required", true),
              const Divider(height: 24),
              _buildStockAlertItem("CTC Tea Leaves", "2.5 kg", "10kg Required", false),
              const Divider(height: 24),
              _buildStockAlertItem("Chicken Breast (Boneless)", "1.2 kg", "15kg Required", true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockAlertItem(String item, String current, String target, bool isUrgent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (isUrgent ? Colors.red : Colors.orange).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.warning_amber_rounded, color: isUrgent ? Colors.red : Colors.orange, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("Current: $current • Target: $target", style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.darkNavy, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size.zero),
          child: const Text("ORDER NOW", style: TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
