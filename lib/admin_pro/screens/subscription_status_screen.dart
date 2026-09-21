import 'package:flutter/material.dart';
import '../../services/tenant_service.dart';
import '../admin_theme.dart';

class SubscriptionStatusScreen extends StatefulWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  State<SubscriptionStatusScreen> createState() => _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Tenant?>(
      valueListenable: TenantService().currentTenant,
      builder: (context, tenant, child) {
        // --- DEMO DATA FOR OFFLINE WEB APP ---
        final bool isDemo = tenant == null;
        
        // Define demo tenant if actual one is missing
        final String plan = isDemo ? "ENTERPRISE ELITE" : tenant.plan;
        final String domain = isDemo ? "chiyalaa.startupsgo.tech" : tenant.domain;
        final String storage = isDemo ? "2.4 GB / 10 GB" : (tenant.storage ?? "0.0 GB");
        final bool isActive = isDemo ? true : tenant.isActive;
        
        final now = DateTime.now();
        DateTime startDate = isDemo ? now.subtract(const Duration(days: 24)) : (tenant.startDate != null ? DateTime.parse(tenant.startDate!) : now.subtract(const Duration(days: 15)));
        DateTime expiryDate = isDemo ? now.add(const Duration(days: 13)) : (tenant.expiry != null ? DateTime.parse(tenant.expiry!) : now.add(const Duration(days: 13)));

        final int totalDays = expiryDate.difference(startDate).inDays;
        final int daysPassed = now.difference(startDate).inDays.clamp(0, totalDays);
        final int daysLeft = expiryDate.difference(now).inDays.clamp(0, totalDays);
        final double progress = totalDays > 0 ? (daysPassed / totalDays).clamp(0.0, 1.0) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Subscription Status",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy),
              ),
              const Text(
                "Monitor your SaaS plan details and renewal timeline.",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              
              _buildPlanCard(plan, daysLeft),
              const SizedBox(height: 24),
              
              _buildLifecycleCard(daysPassed, daysLeft, progress, startDate, expiryDate),
              const SizedBox(height: 24),
              
              _buildDetailsGrid(domain, storage, isActive),
              const SizedBox(height: 32),
              
              _buildFeatureSection(plan),
              const SizedBox(height: 32),
              
              _buildBillingHistory(),
              const SizedBox(height: 32),
              
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureSection(String currentPlan) {
    final List<String> features = [
      "Unlimited Table QR Codes",
      "Kitchen Display System (KDS)",
      "Multi-user Staff Access",
      "Advanced Inventory Tracking",
      "Real-time Sales Analytics",
      "Custom Brand Themes",
      "24/7 Priority Support",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Included in Your Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AdminTheme.emeraldGreen, size: 18),
                const SizedBox(width: 12),
                Text(f, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildBillingHistory() {
    final history = [
      {"date": "27 Aug 2026", "id": "INV-8821", "amount": "NPR 12,500", "status": "Paid"},
      {"date": "27 July 2026", "id": "INV-7710", "amount": "NPR 12,500", "status": "Paid"},
      {"date": "27 June 2026", "id": "INV-6605", "amount": "NPR 12,500", "status": "Paid"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Billing History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AdminTheme.softShadow,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                title: Text(item['amount']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${item['date']} • ${item['id']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AdminTheme.emeraldGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(item['status']!, style: const TextStyle(color: AdminTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(String planName, int daysLeft) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.royalBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CURRENT PLAN", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  planName.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    "$daysLeft Days Remaining",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleCard(int passed, int left, double progress, DateTime start, DateTime end) {
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
              _buildStatItem("Days Elapsed", "$passed Days", AdminTheme.royalBlue),
              _buildStatItem("Days Remaining", "$left Days", AdminTheme.emeraldGreen),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[100],
              color: AdminTheme.royalBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateInfo("Start Date", "${start.day}/${start.month}/${start.year}"),
              _buildDateInfo("Expiry Date", "${end.day}/${end.month}/${end.year}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
      ],
    );
  }

  Widget _buildDetailsGrid(String domain, String storage, bool isActive) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
      double childAspectRatio = constraints.maxWidth > 600 ? 1.8 : 2.5;
      
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
        children: [
          _buildDetailCard("Storage Usage", storage, Icons.storage_rounded),
          _buildDetailCard("Active Domain", domain, Icons.language_rounded),
          _buildDetailCard("Status", isActive ? "Active" : "Suspended", Icons.check_circle_rounded, isStatus: true),
          _buildDetailCard("Support tier", "Priority 24/7", Icons.headset_mic_rounded),
        ],
      );
    });
  }

  Widget _buildDetailCard(String title, String value, IconData icon, {bool isStatus = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AdminTheme.royalBlue.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isStatus ? (value == "Active" ? AdminTheme.emeraldGreen : Colors.red) : AdminTheme.darkNavy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to payment gateway...")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.royalBlue,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text("RENEW PLAN", style: TextStyle(letterSpacing: 1)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showUpgradeDialog(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: AdminTheme.royalBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("UPGRADE", style: TextStyle(color: AdminTheme.royalBlue, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choose Your Plan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUpgradeOption("Basic", "NPR 4,500/mo", "Perfect for small cafes"),
            const SizedBox(height: 12),
            _buildUpgradeOption("Pro", "NPR 8,000/mo", "Best for busy restaurants"),
            const SizedBox(height: 12),
            _buildUpgradeOption("Enterprise", "NPR 12,500/mo", "Full scale management"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
        ],
      ),
    );
  }

  Widget _buildUpgradeOption(String title, String price, String sub) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Switched to $title Plan! (Demo)")));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue)),
          ],
        ),
      ),
    );
  }
}
