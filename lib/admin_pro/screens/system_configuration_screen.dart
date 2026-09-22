import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/language_service.dart';
import '../admin_theme.dart';

class SystemConfigurationScreen extends StatefulWidget {
  final String mode;
  const SystemConfigurationScreen({super.key, required this.mode});

  @override
  State<SystemConfigurationScreen> createState() => _SystemConfigurationScreenState();
}

class _SystemConfigurationScreenState extends State<SystemConfigurationScreen> with SingleTickerProviderStateMixin {
  
  // --- CORE DATA STATE ---
  bool _isSyncing = false;
  bool _isLoadingSettings = true;

  // Controllers for Application Setting
  late TextEditingController _restNameController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // Controllers for SMS Hub
  late TextEditingController _smsApiKeyController;
  late TextEditingController _smsSenderIdController;

  final Map<String, dynamic> _configState = {
    'rest_name': 'Chiyalaa Global Hub',
    'rest_id': 'CHY-PRO-9901',
    'address': 'Main Road, Butwal, Nepal',
    'email': 'admin@chiyalaa.com',
    'phone': '+977-98XXXXXXXX',
    'website': 'https://chiyalaa.com',
    'currency': 'NPR (Rs.)',
    'timezone': 'Asia/Kathmandu',
    'date_format': 'DD/MM/YYYY',
    'vat': '13',
    'service_charge': '10',
    'inv_prefix': 'INV-CHY-',
    'auto_backup': true,
    'backup_freq': '24',
    'session_timeout': '60',
    'subscription': {
      'plan_name': 'ENTERPRISE ELITE PLAN',
      'status': 'Active',
      'sub_id': 'SUB-ENT-2026-000124',
      'price': 'NPR 45,000 / Year',
      'start_date': '26 Aug 2026',
      'expiry_date': '02 Oct 2026',
      'billing_cycle': 'Annually',
      'active_devices': '4',
      'device_limit': '5',
      'active_users': '12',
      'user_limit': '20',
      'active_branches': '2',
      'branch_limit': '3',
      'orders_used': 3420,
      'orders_limit': 10000,
      'products_used': 145,
      'products_limit': 500,
      'storage_limit': '10 GB',
      'storage_used': '2.4 GB',
      'payment_status': 'Paid',
      'last_payment': '26 Aug 2026',
      'transaction_id': 'TXN-992837465',
      'license_integrity': 'Verified',
      'device_binding': 'Enabled',
      'last_verification': '18 Sep 2026',
      'offline_valid_until': '25 Oct 2026',
      'auto_renew': true,
      'unauthorized_devices': 0,
      'suspicious_activity': 0,
      'active_domain': 'chiyalaa.startupsgo.tech',
      'support_manager': 'Arbind Patel',
      'license_type': 'Offline Perpetual',
    },
    'activated_devices': [
      {'name': 'POS-Main-01', 'id': 'DEV-8821-X9', 'type': 'Desktop', 'os': 'Windows 11 Pro', 'version': 'v2.6.0', 'branch': 'Main Branch', 'status': 'Authorized', 'isCurrent': true, 'activated_at': '26 Aug 2026'},
      {'name': 'Admin-Laptop', 'id': 'DEV-1002-A5', 'type': 'Laptop', 'os': 'macOS Sequoia', 'version': 'v2.6.0', 'branch': 'HQ', 'status': 'Authorized', 'isCurrent': false, 'activated_at': '15 Sep 2026'},
      {'name': 'Kitchen-Display-01', 'id': 'DEV-9011-K1', 'type': 'Tablet', 'os': 'Android 14', 'version': 'v2.5.8', 'branch': 'Butwal Hub', 'status': 'Authorized', 'isCurrent': false, 'activated_at': '01 Sep 2026'},
      {'name': 'Waiter-Pad-01', 'id': 'DEV-7721-W3', 'type': 'Tablet', 'os': 'Android 13', 'version': 'v2.6.0', 'branch': 'Main Branch', 'status': 'Authorized', 'isCurrent': false, 'activated_at': '05 Sep 2026'},
    ],
    'feature_entitlements': [
      {'name': 'Point of Sale (POS)', 'status': 'Enabled', 'icon': Icons.point_of_sale_rounded},
      {'name': 'Restaurant Orders', 'status': 'Enabled', 'icon': Icons.restaurant_menu_rounded},
      {'name': 'Inventory Control', 'status': 'Enabled', 'icon': Icons.inventory_2_rounded},
      {'name': 'Table Management', 'status': 'Enabled', 'icon': Icons.table_bar_rounded},
      {'name': 'Kitchen Display (KDS)', 'status': 'Enabled', 'icon': Icons.computer_rounded},
      {'name': 'Customer CRM', 'status': 'Enabled', 'icon': Icons.people_alt_rounded},
      {'name': 'Advance Reports', 'status': 'Enabled', 'icon': Icons.assessment_rounded},
      {'name': 'Digital Invoices', 'status': 'Enabled', 'icon': Icons.receipt_long_rounded},
      {'name': 'Multi-Branch Sync', 'status': 'Enabled', 'icon': Icons.sync_rounded},
      {'name': 'AI Analytics', 'status': 'Locked', 'icon': Icons.auto_graph_rounded},
    ],
    'license_audit_logs': [
      {'date': '18 Sep 2026', 'time': '10:45 AM', 'action': 'License verified', 'target': 'Device: POS-01', 'status': 'Success'},
      {'date': '17 Sep 2026', 'time': '02:30 PM', 'action': 'Device activated', 'target': 'Device: Kitchen-01', 'status': 'Success'},
      {'date': '15 Sep 2026', 'time': '09:00 AM', 'action': 'User limit updated', 'target': 'User: Admin', 'status': 'Success'},
      {'date': '01 Sep 2026', 'time': '11:15 AM', 'action': 'Subscription renewed', 'target': 'Plan: Enterprise', 'status': 'Success'},
      {'date': '26 Aug 2026', 'time': '08:00 AM', 'action': 'Initial Activation', 'target': 'System Node', 'status': 'Success'},
    ],
    'currencies': [
      {'name': 'Nepalese Rupee', 'code': 'NPR', 'symbol': 'Rs.', 'status': 'Active'},
      {'name': 'US Dollar', 'code': 'USD', 'symbol': r'$', 'status': 'Active'},
    ],
    'countries': [
      {'name': 'Nepal', 'code': 'NP', 'phone': '+977', 'status': 'Active'},
      {'name': 'India', 'code': 'IN', 'phone': '+91', 'status': 'Active'},
      {'name': 'United States', 'code': 'US', 'phone': '+1', 'status': 'Inactive'},
    ],
    'states': [
      {'name': 'Lumbini', 'country': 'Nepal', 'status': 'Active'},
      {'name': 'Bagmati', 'country': 'Nepal', 'status': 'Active'},
      {'name': 'Gandaki', 'country': 'Nepal', 'status': 'Active'},
    ],
    'cities': [
      {'name': 'Butwal', 'state': 'Lumbini', 'status': 'Active'},
      {'name': 'Kathmandu', 'state': 'Bagmati', 'status': 'Active'},
      {'name': 'Pokhara', 'state': 'Gandaki', 'status': 'Active'},
      {'name': 'Bhairahawa', 'state': 'Lumbini', 'status': 'Active'},
    ],
    'payment_methods': [
      {'name': 'Cash', 'gateway': 'None', 'status': 'Active', 'icon': Icons.money_rounded},
      {'name': 'Fonepay', 'gateway': 'E-Sewa', 'status': 'Active', 'icon': Icons.qr_code_rounded},
      {'name': 'Khalti', 'gateway': 'Direct', 'status': 'Active', 'icon': Icons.account_balance_wallet_rounded},
      {'name': 'Credit Card', 'gateway': 'Himalayan Bank', 'status': 'Inactive', 'icon': Icons.credit_card_rounded},
    ],
    'shipping_methods': [
      {'name': 'Standard Delivery', 'cost': 'NPR 50', 'time': '30-45 min', 'status': 'Active'},
      {'name': 'Express Delivery', 'cost': 'NPR 150', 'time': '15-20 min', 'status': 'Active'},
      {'name': 'Self Pickup', 'cost': 'NPR 0', 'time': '10 min', 'status': 'Active'},
    ],
    'commissions': [
      {'name': 'Pathao Delivery', 'type': 'Percentage', 'value': '15', 'category': 'Partner', 'status': 'Active'},
      {'name': 'Foodmandu', 'type': 'Percentage', 'value': '18', 'category': 'Partner', 'status': 'Active'},
      {'name': 'Waiters Tip Share', 'type': 'Percentage', 'value': '5', 'category': 'Staff', 'status': 'Active'},
    ],
    'unit_measurements': [
      {'name': 'Kilogram', 'short': 'kg', 'status': 'Active'},
      {'name': 'Litre', 'short': 'ltr', 'status': 'Active'},
      {'name': 'Packet', 'short': 'pkt', 'status': 'Active'},
      {'name': 'Gram', 'short': 'g', 'status': 'Active'},
      {'name': 'Millilitre', 'short': 'ml', 'status': 'Active'},
    ],
    'ingredients': [
      {'name': 'Basmati Rice', 'category': 'Grain', 'unit': 'kg', 'stock': '120', 'status': 'Active'},
      {'name': 'Sunflower Oil', 'category': 'Oil', 'unit': 'ltr', 'stock': '45', 'status': 'Active'},
      {'name': 'Chicken Breast', 'category': 'Meat', 'unit': 'kg', 'stock': '15', 'status': 'Low Stock'},
    ],
    'sms_config': {
      'api_key': 'SK_CHY_882199',
      'sender_id': 'CHIYALAA',
      'status': 'Enabled',
      'service_enabled': true,
    },
    'sms_templates': [
      {'id': 1, 'name': 'Reservation Confirmation', 'tag': 'Booking', 'desc': "Confirm a customer's table reservation.", 'body': 'Hello {customer_name}, your reservation at {restaurant_name} is confirmed for {date} at {time}. Thank you.', 'status': 'Active', 'icon': Icons.event_available_rounded},
      {'id': 2, 'name': 'Reservation Reminder', 'tag': 'Reminder', 'desc': 'Remind customers before their reservation.', 'body': 'Hi {customer_name}, just a friendly reminder of your booking at {restaurant_name} today at {time}. See you soon!', 'status': 'Active', 'icon': Icons.alarm_on_rounded},
      {'id': 3, 'name': 'Meal Preparing', 'tag': 'Update', 'desc': 'Inform customer that chef has started cooking.', 'body': 'Chefs at work! {customer_name}, your meal for order {order_number} is being prepared with love. - {restaurant_name}', 'status': 'Active', 'icon': Icons.outdoor_grill_rounded},
      {'id': 4, 'name': 'Food Ready', 'tag': 'Update', 'desc': 'Notify customer that food is ready for pickup/serve.', 'body': 'Hi {customer_name}, your order {order_number} is fast and ready for pickup! - {restaurant_name}', 'status': 'Active', 'icon': Icons.check_circle_outline_rounded},
      {'id': 5, 'name': 'Payment Received', 'tag': 'Billing', 'desc': 'Confirm successful payment collection.', 'body': 'Payment Confirmed! We have received {amount} for order {order_number}. Thank you, {customer_name}!', 'status': 'Active', 'icon': Icons.receipt_long_rounded},
      {'id': 6, 'name': 'Payment Pending', 'tag': 'Billing', 'desc': 'Alert customer about unpaid bills.', 'body': 'Hi {customer_name}, your payment of {amount} for order {order_number} is currently pending. Please check. - {restaurant_name}', 'status': 'Active', 'icon': Icons.hourglass_empty_rounded},
      {'id': 7, 'name': 'Cancellation Notification', 'tag': 'Alert', 'desc': 'Notify customer about cancellation.', 'body': 'Dear {customer_name}, your reservation at {restaurant_name} for {date} has been cancelled as requested.', 'status': 'Active', 'icon': Icons.cancel_outlined},
    ],
    'sms_rules': [
      {'name': 'Reservation Confirmation', 'desc': 'Send confirmation when a table is booked.', 'enabled': true},
      {'name': 'Order Ready Notify', 'desc': 'Alert customer when order is ready.', 'enabled': true},
    ],
    'sms_history': [
      {'customer': 'Arbind Patel', 'phone': '9841234567', 'type': 'Order Ready', 'preview': 'Your order #7105 is ready! Please collect your meal. Thank you!', 'status': 'DELIVERED', 'time': 'Today, 10:30 AM'},
      {'customer': 'Sandhya Sharma', 'phone': '9801223344', 'type': 'Reservation', 'preview': 'Hello Sandhya, your reservation at StartupsGo is confirmed for 7:00 PM', 'status': 'SENT', 'time': 'Today, 09:15 AM'},
    ],
    'banks': [
      {'name': 'Global IME Bank', 'account': '001002938475', 'branch': 'Butwal', 'balance': 'NPR 1,24,500', 'status': 'Active'},
      {'name': 'NIC Asia Bank', 'account': '992837465011', 'branch': 'HQ Branch', 'balance': 'NPR 88,400', 'status': 'Active'},
    ],
    'bank_transactions': [
      {'date': '18 Sep 2026', 'bank': 'Global IME', 'type': 'Credit', 'amount': 'NPR 15,000', 'status': 'Cleared'},
      {'date': '17 Sep 2026', 'bank': 'NIC Asia', 'type': 'Debit', 'amount': 'NPR 4,200', 'status': 'Cleared'},
    ],
    'app_settings': {
      'primary_color': '#0047AB',
      'dark_mode': false,
      'font_size': 'Medium',
      'notifications': true,
    },
    'reset_actions': [
      {'title': 'Clear Orders', 'desc': 'Delete all order history.', 'icon': Icons.receipt_long_rounded, 'isNuclear': false, 'status': 'Active'},
      {'title': 'Full System Reset', 'desc': 'Wipe everything.', 'icon': Icons.delete_forever_rounded, 'isNuclear': true, 'status': 'Active'},
    ],
    'pricing_plans': [
      {'name': '3 Days Free Trial', 'price': 'NPR 0', 'duration': '3 Days', 'features': 'Full Access • No Credit Card', 'color': AdminTheme.royalBlue},
      {'name': 'Monthly Starter', 'price': 'NPR 799', 'duration': '28 Days', 'features': 'Standard Features • 1 Store', 'color': Colors.blueGrey},
      {'name': '3 Months Pro', 'price': 'NPR 2,396.52', 'duration': '84 Days', 'features': 'Priority Support • Advanced Analytics', 'color': AdminTheme.royalBlue},
      {'name': '6 Months Enterprise', 'price': 'NPR 4,793.04', 'duration': '168 Days', 'features': 'Unlimited • Multi-Store Ready', 'color': AdminTheme.emeraldGreen},
    ],
    'sub_monitoring': [
      {'name': 'Cafe Himalaya', 'plan': '3 Months Pro', 'passed': '45 Days', 'left': '39 Days', 'status': 'Active', 'icon': Icons.storefront_rounded},
      {'name': 'Momo Station', 'plan': 'Monthly Starter', 'passed': '20 Days', 'left': '8 Days', 'status': 'Active', 'icon': Icons.storefront_rounded},
      {'name': 'Boudha Bakery', 'plan': '6 Months Enterprise', 'passed': '150 Days', 'left': '18 Days', 'status': 'Active', 'icon': Icons.storefront_rounded},
      {'name': 'Spice Garden', 'plan': '3 Days Free Trial', 'passed': '3 Days', 'left': 'Expired', 'status': 'Expired', 'icon': Icons.restaurant_rounded, 'isTrial': true},
      {'name': 'Lakeside Café', 'plan': '3 Days Free Trial', 'passed': '1 Day', 'left': '2 Days', 'status': 'Active', 'icon': Icons.restaurant_rounded, 'isTrial': true},
      {'name': 'Everest Dine', 'plan': 'Monthly Starter', 'passed': '28 Days', 'left': 'Expired', 'status': 'Expired', 'icon': Icons.restaurant_rounded},
    ],
    'revenue_history': [
      {'name': 'Cafe Himalaya', 'id': '#INV-982', 'amount': 'NPR 2,396.52', 'status': 'Paid'},
      {'name': 'Momo Station', 'id': '#INV-981', 'amount': 'NPR 799.00', 'status': 'Pending'},
      {'name': 'Boudha Bakery', 'id': '#INV-980', 'amount': 'NPR 4,793.04', 'status': 'Paid'},
    ],
    'app_configs_list': [
      {'id': '1', 'name': 'Restaurant Name', 'value': 'Chiyalaa Global Hub', 'key': 'rest_name', 'icon': Icons.storefront_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '2', 'name': 'Official Address', 'value': 'Main Road, Butwal, Nepal', 'key': 'address', 'icon': Icons.location_on_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '3', 'name': 'Official Email', 'value': 'admin@chiyalaa.com', 'key': 'email', 'icon': Icons.email_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '4', 'name': 'Phone Number', 'value': '+977-98XXXXXXXX', 'key': 'phone', 'icon': Icons.phone_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '5', 'name': 'VAT / Tax (%)', 'value': '13', 'key': 'vat', 'icon': Icons.receipt_long_rounded, 'type': 'number', 'status': 'Active'},
      {'id': '6', 'name': 'Service Charge (%)', 'value': '10', 'key': 'service_charge', 'icon': Icons.room_service_rounded, 'type': 'number', 'status': 'Active'},
      {'id': '7', 'name': 'Auto KOT Print', 'value': true, 'key': 'print_kot_auto', 'icon': Icons.print_rounded, 'type': 'toggle', 'status': 'Active'},
      {'id': '8', 'name': 'Opening Time', 'value': '09:00 AM', 'key': 'opening_time', 'icon': Icons.schedule_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '9', 'name': 'Closing Time', 'value': '11:00 PM', 'key': 'closing_time', 'icon': Icons.bedtime_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '10', 'name': 'Stock Threshold', 'value': '10', 'key': 'low_stock_threshold', 'icon': Icons.warning_amber_rounded, 'type': 'number', 'status': 'Active'},
      {'id': '11', 'name': 'Paper Size', 'value': '80mm', 'key': 'thermal_paper_size', 'icon': Icons.description_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '12', 'name': 'Default Order Type', 'value': 'Dine-in', 'key': 'default_order_type', 'icon': Icons.restaurant_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '13', 'name': 'Decimal Places', 'value': '2', 'key': 'decimal_places', 'icon': Icons.exposure_zero_rounded, 'type': 'number', 'status': 'Active'},
      {'id': '14', 'name': 'KDS Refresh Rate', 'value': '10s', 'key': 'kds_refresh', 'icon': Icons.sync_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '15', 'name': 'Invoice Footer', 'value': 'Thank you for your visit!', 'key': 'invoice_footer', 'icon': Icons.speaker_notes_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '16', 'name': 'Currency Symbol', 'value': 'Rs.', 'key': 'currency_symbol', 'icon': Icons.currency_rupee_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '17', 'name': 'Booking Buffer', 'value': '30 min', 'key': 'booking_buffer', 'icon': Icons.timer_rounded, 'type': 'text', 'status': 'Active'},
    ],
    'payment_setup_list': [
      {'id': '1', 'name': 'E-Sewa Merchant ID', 'value': 'ESW_CHY_101', 'key': 'esewa_id', 'icon': Icons.account_balance_wallet_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '2', 'name': 'Khalti Secret Key', 'value': 'KH_KEY_9921', 'key': 'khalti_key', 'icon': Icons.vpn_key_rounded, 'type': 'text', 'status': 'Active'},
      {'id': '3', 'name': 'Test Mode (Sandbox)', 'value': true, 'key': 'payment_test_mode', 'icon': Icons.bug_report_rounded, 'type': 'toggle', 'status': 'Active'},
      {'id': '4', 'name': 'Fonepay Merchant ID', 'value': 'FP_992837', 'key': 'fonepay_id', 'icon': Icons.qr_code_scanner_rounded, 'type': 'text', 'status': 'Inactive'},
    ],
  };

  String _locSearchQuery = "";
  String _invSearchQuery = ""; // New: Search for Inventory
  String _commSearchQuery = ""; // New: Commission Search
  String _resetSearchQuery = "";
  String _appSearchQuery = ""; // New: App Setting Search
  String _paySearchQuery = ""; // New: Payment Search
  String _paySetupSearchQuery = ""; // New: Payment Setup Search
  String _shipSearchQuery = ""; // New: Shipping Search
  String _smsSearchQuery = ""; // New: SMS search
  String _smsTemplateSearchQuery = ""; // New: Template search
  String _locStatusFilter = "ALL";
  String _subMonitorFilter = "All"; 
  String _smsTypeFilter = "All Types";
  String _smsStatusFilter = "All Status";
  String _smsTemplateStatusFilter = "All"; // All, Active, Inactive
  bool _smsTodayOnly = false; // New: Today filter
  int _displayCount = 10; // New: Display count for lists
  String _langFilter = "TOTAL"; // For filtering language cards via stats cards
  String _resetFilter = "TOTAL"; // For filtering factory reset actions via stats cards
  String _appFilter = "TOTAL"; // For filtering app settings via stats cards
  String _payFilter = "TOTAL"; // For filtering payment methods via stats cards
  String _shipFilter = "TOTAL"; // For filtering shipping methods via stats cards

  void _updateConfig(String key, dynamic value) {
    setState(() => _configState[key] = value);
    _saveConfig();
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('system_config_data', json.encode(_configState));
    } catch (e) {
      debugPrint("Error saving config: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _restNameController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _smsApiKeyController = TextEditingController();
    _smsSenderIdController = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _restNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _smsApiKeyController.dispose();
    _smsSenderIdController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('system_config_data');
      if (savedData != null && mounted) {
        setState(() {
          final Map<String, dynamic> decoded = json.decode(savedData);
          _configState.addAll(decoded);
          
          // Sync controllers with loaded data
          _restNameController.text = _configState['rest_name'] ?? '';
          _addressController.text = _configState['address'] ?? '';
          _emailController.text = _configState['email'] ?? '';
          _phoneController.text = _configState['phone'] ?? '';
          _smsApiKeyController.text = _configState['sms_config']['api_key'] ?? '';
          _smsSenderIdController.text = _configState['sms_config']['sender_id'] ?? '';
          
          _isLoadingSettings = false;
        });
      } else if (mounted) {
        setState(() {
          _restNameController.text = _configState['rest_name'] ?? '';
          _addressController.text = _configState['address'] ?? '';
          _emailController.text = _configState['email'] ?? '';
          _phoneController.text = _configState['phone'] ?? '';
          _smsApiKeyController.text = _configState['sms_config']['api_key'] ?? '';
          _smsSenderIdController.text = _configState['sms_config']['sender_id'] ?? '';
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _handleGlobalSave() async {
    setState(() {
      _isSyncing = true;
      // Capture data from controllers
      _configState['rest_name'] = _restNameController.text.trim();
      _configState['address'] = _addressController.text.trim();
      _configState['email'] = _emailController.text.trim();
      _configState['phone'] = _phoneController.text.trim();
      _configState['sms_config']['api_key'] = _smsApiKeyController.text.trim();
      _configState['sms_config']['sender_id'] = _smsSenderIdController.text.trim();
    });
    
    await _saveConfig();
    await Future.delayed(const Duration(milliseconds: 1000)); 
    if (mounted) {
      setState(() => _isSyncing = false);
      _showFeedback("Success", "All configuration changes saved and synced.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResponsiveHeader(),
          if (widget.mode != "Language") const SizedBox(height: 32),
          if (widget.mode == "Application Setting") _buildApplicationSetting()
          else if (widget.mode == "Commission") _buildCommissionModule()
          else if (widget.mode == "Subscription Status") _buildSubscriptionStatus()
          else if (widget.mode == "Factory Reset") _buildFactoryReset()
          else if (["Currency", "Country", "State", "City"].contains(widget.mode)) _buildLocationDataManager()
          else if (["Unit Measurement List", "Ingredient List"].contains(widget.mode)) _buildInventoryModule()
          else if (["SMS Configuration", "SMS Template"].contains(widget.mode)) _buildSMSSettingModule()
          else if (["Bank List", "Bank Transaction"].contains(widget.mode)) _buildBankModule()
          else if (["Payment Method List", "Payment Setup"].contains(widget.mode)) _buildPaymentModule()
          else if (widget.mode == "Shipping Method Setting") _buildShippingModule()
          else if (widget.mode == "Language") _buildLanguageModule()
          else _buildGenericList(),
        ],
      ),
    );
  }

  Widget _buildResponsiveHeader() {
    if (widget.mode == "Language") return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.4), 
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.settings_rounded, color: AdminTheme.royalBlue, size: 30),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mode.startsWith("SMS") ? (widget.mode == "SMS Configuration" ? "SMS Hub" : "SMS Templates") : widget.mode, 
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy, letterSpacing: -0.5)
            ),
            const SizedBox(height: 4),
            Text(
              widget.mode.startsWith("SMS") ? (widget.mode == "SMS Configuration" ? "Configure automated communication & logs" : "Manage reusable messages for customer notifications.") : "System Configuration Node • Professional Management", 
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ],
    );
  }

  // --- 1. APPLICATION SETTING ---
  Widget _buildApplicationSetting() {
    final List allSettings = List.from(_configState['app_configs_list'] ?? []);
    
    // Stats calculation
    final total = allSettings.length;
    final active = allSettings.where((s) => s['status'] == 'Active').length;
    final inactive = allSettings.where((s) => s['status'] != 'Active').length;
    final toggles = allSettings.where((s) => s['type'] == 'toggle').length;

    final filtered = allSettings.where((s) {
      bool matchesSearch = s['name'].toString().toLowerCase().contains(_appSearchQuery.toLowerCase()) ||
                           s['value'].toString().toLowerCase().contains(_appSearchQuery.toLowerCase());
      bool matchesFilter = true;
      if (_appFilter == "ACTIVE") matchesFilter = s['status'] == 'Active';
      else if (_appFilter == "INACTIVE") matchesFilter = s['status'] != 'Active';
      else if (_appFilter == "TOGGLES") matchesFilter = s['type'] == 'toggle';
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive Stats Row
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildAppStatCard("TOTAL", total.toString(), isSelected: _appFilter == "TOTAL"),
            _buildAppStatCard("ACTIVE", active.toString(), valueColor: Colors.green, isSelected: _appFilter == "ACTIVE"),
            _buildAppStatCard("INACTIVE", inactive.toString(), valueColor: Colors.orange, isSelected: _appFilter == "INACTIVE"),
            _buildAppStatCard("TOGGLES", toggles.toString(), valueColor: AdminTheme.royalBlue, isSelected: _appFilter == "TOGGLES"),
          ],
        ),
        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
                child: TextField(
                  onChanged: (v) => setState(() => _appSearchQuery = v),
                  decoration: const InputDecoration(hintText: "Search configuration...", border: InputBorder.none, icon: Icon(Icons.search)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddEditAppSettingDialog(null), 
              icon: const Icon(Icons.add), 
              label: const Text("ADD APPLICATION SETTING"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.royalBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            boxShadow: AdminTheme.softShadow,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: AdminTheme.royalBlue.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text("SETTING NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 4, child: Text("CURRENT CONFIGURATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    SizedBox(width: 100, child: Center(child: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                const Padding(padding: EdgeInsets.all(64), child: Text("No settings found matching your search.", style: TextStyle(color: Colors.grey)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade50),
                  itemBuilder: (ctx, i) {
                    final s = filtered[i];
                    int realIdx = _configState['app_configs_list'].indexOf(s);
                    bool isToggle = s['type'] == 'toggle';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3, 
                            child: Row(
                              children: [
                                Icon(s['icon'] ?? Icons.settings_rounded, size: 18, color: AdminTheme.royalBlue),
                                const SizedBox(width: 12),
                                Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy)),
                              ],
                            )
                          ),
                          Expanded(
                            flex: 4, 
                            child: isToggle 
                              ? Text(s['value'] == true ? 'ENABLED' : 'DISABLED', style: TextStyle(color: s['value'] == true ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                              : Text(s['value'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis)
                          ),
                          Expanded(
                            flex: 2, 
                            child: Center(
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch.adaptive(
                                  value: s['status'] == 'Active',
                                  onChanged: (v) {
                                    setState(() => s['status'] = v ? 'Active' : 'Inactive');
                                    _saveConfig();
                                  },
                                  activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                                  activeColor: AdminTheme.royalBlue,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24), 
                                  onPressed: () => _showAddEditAppSettingDialog(realIdx),
                                  tooltip: "Modify ${s['name']}",
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), 
                                  onPressed: () => _showConfirmDeleteDialog("Setting", realIdx, "app_configs_list"),
                                  tooltip: "Remove ${s['name']}",
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppStatCard(String label, String value, {bool isSelected = false, Color? valueColor}) {
    return InkWell(
      onTap: () => setState(() => _appFilter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AdminTheme.royalBlue, width: 2) : Border.all(color: Colors.grey.shade100),
          boxShadow: AdminTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? AdminTheme.royalBlue : Colors.grey, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor ?? AdminTheme.darkNavy)),
          ],
        ),
      ),
    );
  }

  void _showAddEditAppSettingDialog(int? index) {
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState['app_configs_list'][index] : {};
    
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final valCtrl = TextEditingController(text: data['value']?.toString() ?? '');
    String selectedType = data['type'] ?? 'text';
    bool toggleVal = data['value'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
              const SizedBox(width: 12),
              Text(isEditing ? "Edit Setting" : "Add Setting", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Setting Name", hintText: "e.g. Printer Address")),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['text', 'number', 'toggle'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                  onChanged: (v) => setModalState(() => selectedType = v!),
                  decoration: const InputDecoration(labelText: "Configuration Type"),
                ),
                const SizedBox(height: 16),
                selectedType == 'toggle'
                  ? SwitchListTile.adaptive(
                      title: const Text("Default State"),
                      value: toggleVal, 
                      onChanged: (v) => setModalState(() => toggleVal = v),
                    )
                  : TextField(
                      controller: valCtrl, 
                      decoration: const InputDecoration(labelText: "Current Configuration"),
                      keyboardType: selectedType == 'number' ? TextInputType.number : TextInputType.text,
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                setState(() {
                  final List list = _configState['app_configs_list'];
                  final newItem = {
                    'id': isEditing ? data['id'] : (list.length + 1).toString(),
                    'name': nameCtrl.text.trim(),
                    'value': selectedType == 'toggle' ? toggleVal : valCtrl.text.trim(),
                    'key': data['key'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    'icon': data['icon'] ?? Icons.settings_applications_rounded,
                    'type': selectedType,
                    'status': data['status'] ?? 'Active',
                  };
                  if (isEditing) {
                    _configState['app_configs_list'][index] = newItem;
                    // Sync main config keys for core settings
                    if (newItem['key'] == 'rest_name') _configState['rest_name'] = newItem['value'];
                    if (newItem['key'] == 'address') _configState['address'] = newItem['value'];
                    if (newItem['key'] == 'email') _configState['email'] = newItem['value'];
                    if (newItem['key'] == 'phone') _configState['phone'] = newItem['value'];
                  } else {
                    _configState['app_configs_list'].add(newItem);
                  }
                });
                _saveConfig();
                Navigator.pop(ctx);
                _showFeedback("Success", "Setting ${isEditing ? 'updated' : 'added'} successfully.");
              }, 
              child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStableSettingField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminTheme.royalBlue, width: 2)),
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy, fontSize: 15),
          )
        ]
      )
    );
  }

  // --- 2. LOCATION DATA MANAGER (Fully Workable) ---
  Widget _buildLocationDataManager() {
    String type = widget.mode;
    String key = type == "Currency" ? "currencies" : (type == "Country" ? "countries" : (type == "City" ? "cities" : "states"));
    final List allItems = List.from(_configState[key] ?? []);
    
    // Stats calculation
    final total = allItems.length;
    final active = allItems.where((i) => i['status'] == 'Active').length;
    final inactive = allItems.where((i) => i['status'] != 'Active').length;

    final filtered = allItems.where((i) {
      bool matchesSearch = i['name'].toString().toLowerCase().contains(_locSearchQuery.toLowerCase());
      bool matchesStatus = true;
      if (_locStatusFilter == "ACTIVE") matchesStatus = i['status'] == 'Active';
      else if (_locStatusFilter == "INACTIVE") matchesStatus = i['status'] != 'Active';
      
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive Stats Row
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildLocStatCard("TOTAL", total.toString(), isSelected: _locStatusFilter == "ALL"),
            _buildLocStatCard("ACTIVE", active.toString(), valueColor: Colors.green, isSelected: _locStatusFilter == "ACTIVE"),
            _buildLocStatCard("INACTIVE", inactive.toString(), valueColor: Colors.orange, isSelected: _locStatusFilter == "INACTIVE"),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
                child: TextField(
                  onChanged: (v) => setState(() => _locSearchQuery = v),
                  decoration: const InputDecoration(hintText: "Search...", border: InputBorder.none, icon: Icon(Icons.search)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddEditLocationDialog(null, key, type), 
              icon: const Icon(Icons.add), 
              label: Text("ADD $type")
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildLocationDataTable(filtered, key, type),
      ],
    );
  }

  Widget _buildLocationDataTable(List items, String key, String type) {
    bool isCurrency = type == "Currency";
    bool isCountry = type == "Country";
    bool isState = type == "State";
    bool isCity = type == "City";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: AdminTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AdminTheme.royalBlue.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 50, child: Text("SL.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                Expanded(flex: 3, child: Text("$type NAME".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                if (isCurrency) ...[
                   const Expanded(flex: 2, child: Text("ISO CODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                   const Expanded(flex: 2, child: Text("SYMBOL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                ],
                if (isCountry) ...[
                   const Expanded(flex: 2, child: Text("CODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                   const Expanded(flex: 2, child: Text("PHONE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                ],
                if (isState) const Expanded(flex: 3, child: Text("COUNTRY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                if (isCity) const Expanded(flex: 3, child: Text("STATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                const Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                const SizedBox(width: 120, child: Center(child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(padding: const EdgeInsets.all(64), child: Text("No $type found.", style: const TextStyle(color: Colors.grey)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade50),
              itemBuilder: (ctx, i) {
                final item = items[i];
                int realIdx = _configState[key].indexOf(item);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Row(
                    children: [
                      SizedBox(width: 50, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                      Expanded(flex: 3, child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.darkNavy))),
                      
                      // Dynamic Columns based on type
                      if (isCurrency) ...[
                        Expanded(flex: 2, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                          child: Text(item['code'] ?? 'N/A', style: const TextStyle(color: AdminTheme.royalBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                        )),
                        Expanded(flex: 2, child: Text(item['symbol'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.darkNavy))),
                      ],
                      if (isCountry) ...[
                        Expanded(flex: 2, child: Text(item['code'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.darkNavy))),
                        Expanded(flex: 2, child: Text(item['phone'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
                      ],
                      if (isState) Expanded(flex: 3, child: Text(item['country'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
                      if (isCity) Expanded(flex: 3, child: Text(item['state'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),

                      Expanded(flex: 2, child: Center(
                        child: Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: item['status'] == 'Active',
                            onChanged: (v) {
                              setState(() => item['status'] = v ? 'Active' : 'Inactive');
                              _saveConfig();
                            },
                            activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                            activeColor: AdminTheme.royalBlue,
                          ),
                        ),
                      )),
                      SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24), 
                              onPressed: () => _showAddEditLocationDialog(realIdx, key, type)
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22), 
                              onPressed: () => _showConfirmDeleteDialog(type, realIdx, key)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencyMeta(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
      ],
    );
  }

  // --- 3. COMMISSION ---
  // --- 3. COMMISSION ---
  Widget _buildCommissionModule() {
    final List allComms = List.from(_configState['commissions'] ?? []);
    final filtered = allComms.where((c) => 
      c['name'].toString().toLowerCase().contains(_commSearchQuery.toLowerCase()) ||
      c['category'].toString().toLowerCase().contains(_commSearchQuery.toLowerCase())
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
                child: TextField(
                  onChanged: (v) => setState(() => _commSearchQuery = v),
                  decoration: const InputDecoration(hintText: "Search commissions...", border: InputBorder.none, icon: Icon(Icons.search)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddEditCommissionDialog(null), 
              icon: const Icon(Icons.add), 
              label: const Text("ADD COMMISSION")
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            boxShadow: AdminTheme.softShadow,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: AdminTheme.royalBlue.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 50, child: Text("SL.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 3, child: Text("COMMISSION NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("CATEGORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("TYPE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("VALUE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    SizedBox(width: 120, child: Center(child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                const Padding(padding: EdgeInsets.all(64), child: Text("No commissions found.", style: TextStyle(color: Colors.grey)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade50),
                  itemBuilder: (ctx, i) {
                    final comm = filtered[i];
                    int realIdx = _configState['commissions'].indexOf(comm);
                    bool isPercentage = comm['type'] == 'Percentage';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Row(
                        children: [
                          SizedBox(width: 50, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                          Expanded(flex: 3, child: Text(comm['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.darkNavy))),
                          Expanded(flex: 2, child: Text(comm['category'], style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(comm['type'], style: const TextStyle(fontSize: 13, color: AdminTheme.royalBlue, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(
                            "${comm['value']}${isPercentage ? '%' : ''}", 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AdminTheme.emeraldGreen)
                          )),
                          Expanded(flex: 2, child: Center(
                            child: Transform.scale(
                              scale: 0.8,
                              child: Switch.adaptive(
                                value: comm['status'] == 'Active',
                                onChanged: (v) {
                                  setState(() => comm['status'] = v ? 'Active' : 'Inactive');
                                  _saveConfig();
                                },
                                activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                                activeColor: AdminTheme.royalBlue,
                              ),
                            ),
                          )),
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24), 
                                  onPressed: () => _showAddEditCommissionDialog(realIdx)
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22), 
                                  onPressed: () => _showConfirmDeleteDialog("Commission", realIdx, "commissions")
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddEditCommissionDialog(int? index) {
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState['commissions'][index] : {};
    
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final valCtrl = TextEditingController(text: data['value'] ?? '');
    String selectedType = data['type'] ?? 'Percentage';
    String selectedCat = data['category'] ?? 'Partner';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
              const SizedBox(width: 12),
              Text(isEditing ? "Edit Commission" : "Add Commission", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Commission Name")),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCat,
                      items: ['Partner', 'Staff', 'Affiliate', 'Platform'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setModalState(() => selectedCat = v!),
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      items: ['Percentage', 'Fixed'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setModalState(() => selectedType = v!),
                      decoration: const InputDecoration(labelText: "Type"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: valCtrl, decoration: const InputDecoration(labelText: "Value", hintText: "e.g. 15"), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                setState(() {
                  final newItem = {
                    'name': nameCtrl.text.trim(),
                    'category': selectedCat,
                    'type': selectedType,
                    'value': valCtrl.text.trim(),
                    'status': data['status'] ?? 'Active',
                  };
                  if (isEditing) {
                    _configState['commissions'][index] = newItem;
                  } else {
                    _configState['commissions'].add(newItem);
                  }
                });
                _saveConfig();
                Navigator.pop(ctx);
              }, 
              child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. SUBSCRIPTION & Plan Manager (Premium Design based on Photo 2) ---
  Widget _buildSubscriptionStatus() {
    final sub = _configState['subscription'] ?? {};
    final List features = _configState['feature_entitlements'] ?? [];
    final List logs = _configState['license_audit_logs'] ?? [];
    final List devices = _configState['activated_devices'] ?? [];
    
    // Dynamic Calculations
    DateTime startDate = DateTime(2026, 8, 26);
    DateTime expiryDate = DateTime(2026, 10, 2);
    DateTime today = DateTime.now();
    int totalDurationDays = expiryDate.difference(startDate).inDays;
    int daysUsed = today.isAfter(startDate) ? today.difference(startDate).inDays : 0;
    int daysRemaining = expiryDate.isAfter(today) ? expiryDate.difference(today).inDays : 0;
    double progress = totalDurationDays > 0 ? (daysUsed / totalDurationDays).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: const Color(0xFFF2EFE4), // Soft beige background from Photo 2
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(),
            const SizedBox(height: 32),
            _buildTerracottaPlanCard(sub, progress, daysUsed, daysRemaining, totalDurationDays),
            const SizedBox(height: 40),
            _buildSubHeader("Technical Infrastructure"),
            _buildInfrastructureGrid(sub),
            const SizedBox(height: 48),
            _buildSubHeader("Operational Capacity"),
            _buildResourceGrid(sub),
            const SizedBox(height: 48),
            _buildSubHeader("Authorized Terminal Hardware"),
            _buildHardwarePanel(devices),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSubHeader("Active Entitlements"),
                TextButton(onPressed: () {}, child: const Text("View Details", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ],
            ),
            _buildFeatureList(features),
            const SizedBox(height: 48),
            _buildSubHeader("Security & Audit Timeline"),
            _buildAuditTimeline(logs),
            const SizedBox(height: 48),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showFeedback("Redirecting", "Connecting to renewal gateway..."),
                icon: const Icon(Icons.autorenew_rounded),
                label: const Text("UPGRADE OR RENEW SUBSCRIPTION"),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.darkNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)));
  }

  Widget _buildPremiumHeader() {
    return Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, image: const DecorationImage(image: NetworkImage("https://ui-avatars.com/api/?name=Arbind+Patel&background=random"), fit: BoxFit.cover), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        ),
        const SizedBox(width: 16),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Arbind Patel", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)), Text("Enterprise Administrator • Support Active", style: TextStyle(fontSize: 13, color: AdminTheme.emeraldGreen, fontWeight: FontWeight.bold))]),
        const Spacer(),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.grey.shade200)), child: const Icon(Icons.add, size: 24, color: AdminTheme.darkNavy)),
      ],
    );
  }

  Widget _buildTerracottaPlanCard(Map sub, double progress, int used, int left, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: const Color(0xFFC07B63), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: const Color(0xFFC07B63).withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 15))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Enterprise License Status", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.circle, size: 6, color: Colors.white), SizedBox(width: 8), Text("ACTIVE NODE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))])),
            ],
          ),
          const SizedBox(height: 12),
          Text(sub['plan_name'] ?? "ENTERPRISE ELITE", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Days Elapsed", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)), Text("$used Days", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Days Remaining", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)), Text("$left Days", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))]),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 14, backgroundColor: Colors.white12, color: AdminTheme.emeraldGreen)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Issued: ${sub['start_date']}", style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)), Text("Expires: ${sub['expiry_date']}", style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))],
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureGrid(Map sub) {
    return LayoutBuilder(builder: (context, constraints) {
      int count = constraints.maxWidth > 1000 ? 2 : 1;
      return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: count, crossAxisSpacing: 24, mainAxisSpacing: 24,
        childAspectRatio: count == 2 ? 3.5 : 2.5,
        children: [
          _buildInfrastructureCard("Storage Usage", sub['storage_used'] ?? "2.4 GB", "of 10 GB Encrypted Node", Icons.storage_rounded, AdminTheme.royalBlue),
          _buildInfrastructureCard("Active Domain", "startupsgo.tech", "Primary Endpoint", Icons.language_rounded, AdminTheme.emeraldGreen),
        ],
      );
    });
  }

  Widget _buildInfrastructureCard(String label, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)), Text(subtext, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
        ],
      ),
    );
  }

  Widget _buildResourceGrid(Map sub) {
    return LayoutBuilder(builder: (context, constraints) {
      int count = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
      return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: count, crossAxisSpacing: 20, mainAxisSpacing: 20,
        childAspectRatio: 2.0,
        children: [
          _buildSummaryMiniCard("Staff Seats", sub['active_users'].toString(), "${sub['user_limit']} Max", Icons.people_outline_rounded, const Color(0xFFD6EAF8)),
          _buildSummaryMiniCard("Branch Nodes", sub['active_branches'].toString(), "${sub['branch_limit']} Max", Icons.account_tree_outlined, const Color(0xFFE8F8F5)),
          _buildSummaryMiniCard("License Key", "Verified", "AES-256", Icons.vpn_key_outlined, const Color(0xFFF9EBEA)),
          _buildSummaryMiniCard("Payments", "Paid & Clear", "Annual Cycle", Icons.account_balance_wallet_outlined, const Color(0xFFF1E6D2)),
        ],
      );
    });
  }

  Widget _buildSummaryMiniCard(String label, String val, String meta, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AdminTheme.darkNavy),
          const Spacer(),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
          Text(meta, style: TextStyle(fontSize: 10, color: AdminTheme.darkNavy.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildHardwarePanel(List devices) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          ...devices.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)), child: Icon(d['type'] == 'Desktop' ? Icons.desktop_windows_rounded : Icons.tablet_mac_rounded, size: 20, color: AdminTheme.royalBlue)),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminTheme.darkNavy)), Text("${d['os']} • ${d['branch']}", style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AdminTheme.emeraldGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text("AUTHORIZED", style: TextStyle(color: AdminTheme.emeraldGreen, fontSize: 9, fontWeight: FontWeight.w900))),
                const SizedBox(width: 12),
                IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.grey)),
              ],
            ),
          )).toList(),
          const Divider(height: 40),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_to_queue_rounded, size: 18), label: const Text("ACTIVATE NEW TERMINAL"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
        ],
      ),
    );
  }

  Widget _buildFeatureList(List features) {
    final List<Color> pastelColors = [const Color(0xFFD5E8D4), const Color(0xFFFFF2CC), const Color(0xFFF8CECC), const Color(0xFFE1D5E7), const Color(0xFFDAE8FC)];
    return Column(
      children: List.generate(features.length, (i) {
        final f = features[i];
        bool isEnabled = f['status'] == 'Enabled';
        return Container(
          margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isEnabled ? pastelColors[i % pastelColors.length] : Colors.grey[200], borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)), child: Icon(f['icon'] ?? Icons.star_outline_rounded, color: AdminTheme.darkNavy, size: 24)),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(f['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)), const Text("Enterprise System Feature Status", style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.bold))])),
              Text(isEnabled ? "ACTIVE" : "LOCKED", style: TextStyle(fontWeight: FontWeight.w900, color: isEnabled ? AdminTheme.darkNavy : Colors.grey, fontSize: 13)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAuditTimeline(List logs) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: logs.map((l) => Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade50))),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.grey, size: 18),
              const SizedBox(width: 16),
              Expanded(child: Text(l['action'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Text(l['date'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // --- 5. FACTORY RESET ---
  Widget _buildFactoryReset() {
    final List allActions = List.from(_configState['reset_actions'] ?? []);
    
    // Stats calculation
    final total = allActions.length;
    final active = allActions.where((a) => a['status'] == 'Active').length;
    final inactive = allActions.where((a) => a['status'] != 'Active').length;
    final critical = allActions.where((a) => a['isNuclear'] == true).length;

    final filtered = allActions.where((action) {
      bool matchesSearch = action['title'].toString().toLowerCase().contains(_resetSearchQuery.toLowerCase());
      bool matchesFilter = true;
      if (_resetFilter == "ACTIVE") matchesFilter = action['status'] == 'Active';
      else if (_resetFilter == "INACTIVE") matchesFilter = action['status'] != 'Active';
      else if (_resetFilter == "CRITICAL") matchesFilter = action['isNuclear'] == true;
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive Stats Row
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildResetStatCard("TOTAL", total.toString(), isSelected: _resetFilter == "TOTAL"),
            _buildResetStatCard("ACTIVE", active.toString(), valueColor: Colors.green, isSelected: _resetFilter == "ACTIVE"),
            _buildResetStatCard("INACTIVE", inactive.toString(), valueColor: Colors.orange, isSelected: _resetFilter == "INACTIVE"),
            _buildResetStatCard("CRITICAL", critical.toString(), valueColor: Colors.red, isSelected: _resetFilter == "CRITICAL"),
          ],
        ),
        const SizedBox(height: 40),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
                child: TextField(
                  onChanged: (v) => setState(() => _resetSearchQuery = v),
                  decoration: const InputDecoration(hintText: "Search reset actions...", border: InputBorder.none, icon: Icon(Icons.search)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddEditResetActionDialog(null), 
              icon: const Icon(Icons.add), 
              label: const Text("ADD RESET ACTION")
            ),
          ],
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, 
                mainAxisSpacing: 24, 
                crossAxisSpacing: 24, 
                childAspectRatio: constraints.maxWidth > 1400 ? 2.5 : 2.0,
              ),
              itemBuilder: (ctx, i) {
                final action = filtered[i];
                int realIdx = _configState['reset_actions'].indexOf(action);
                bool isNuclear = action['isNuclear'] == true;

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24), 
                    boxShadow: AdminTheme.softShadow,
                    border: Border.all(color: isNuclear ? Colors.red.withValues(alpha: 0.1) : Colors.grey.shade100, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: (isNuclear ? Colors.red : AdminTheme.royalBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                            child: Icon(action['icon'] ?? Icons.settings_backup_restore_rounded, color: isNuclear ? Colors.red : AdminTheme.royalBlue, size: 24),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(action['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AdminTheme.darkNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    Text(action['status'] ?? 'Active', style: TextStyle(color: action['status'] == 'Active' ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Transform.scale(
                                      scale: 0.6,
                                      child: Switch.adaptive(
                                        value: action['status'] == 'Active', 
                                        onChanged: (v) {
                                          setState(() => action['status'] = v ? 'Active' : 'Inactive');
                                          _saveConfig();
                                        }
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isNuclear)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                              child: const Text("NUCLEAR", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 22), 
                            onPressed: () => _showAddEditResetActionDialog(realIdx)
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), 
                            onPressed: () => _deleteResetAction(realIdx)
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(action['desc'], style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _runResetAction(action), 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isNuclear ? Colors.red : AdminTheme.royalBlue,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ), 
                        child: Text("RUN ACTION", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocStatCard(String label, String value, {bool isSelected = false, Color? valueColor}) {
    return InkWell(
      onTap: () => setState(() => _locStatusFilter = label == "TOTAL" ? "ALL" : label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AdminTheme.royalBlue, width: 2) : Border.all(color: Colors.grey.shade100),
          boxShadow: AdminTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isSelected ? AdminTheme.royalBlue : Colors.grey, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor ?? AdminTheme.darkNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildResetStatCard(String label, String value, {bool isSelected = false, Color? valueColor}) {
    return InkWell(
      onTap: () => setState(() => _resetFilter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AdminTheme.royalBlue, width: 2) : Border.all(color: Colors.grey.shade100),
          boxShadow: AdminTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isSelected ? AdminTheme.royalBlue : Colors.grey, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor ?? AdminTheme.darkNavy)),
          ],
        ),
      ),
    );
  }

  void _showAddEditResetActionDialog(int? index) {
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState['reset_actions'][index] : {};
    
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final descCtrl = TextEditingController(text: data['desc'] ?? '');
    bool isNuclear = data['isNuclear'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
              const SizedBox(width: 12),
              Text(isEditing ? "Edit Reset Action" : "Add Reset Action", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl, 
                  decoration: const InputDecoration(labelText: "Action Title", hintText: "e.g. Wipe Cache, Reset Sales")
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl, 
                  decoration: const InputDecoration(labelText: "Description", hintText: "What does this action do?"),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isNuclear ? Colors.red.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isNuclear ? Colors.red.withValues(alpha: 0.2) : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Critical (Nuclear) Action?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Checking this makes the action high-risk and destructive.", style: TextStyle(fontSize: 10)),
                        value: isNuclear, 
                        activeColor: Colors.red,
                        onChanged: (v) => setModalState(() => isNuclear = v!),
                      ),
                      if (isNuclear)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.report_problem_rounded, color: Colors.red, size: 14),
                              SizedBox(width: 8),
                              Expanded(child: Text("Warning: Destructive actions cannot be undone once executed.", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) {
                  _showFeedback("Error", "Title is required.", isError: true);
                  return;
                }
                setState(() {
                  final newItem = {
                    'title': titleCtrl.text.trim(),
                    'desc': descCtrl.text.trim(),
                    'icon': data['icon'] ?? Icons.settings_backup_restore_rounded,
                    'isNuclear': isNuclear,
                    'status': data['status'] ?? 'Active',
                  };
                  if (isEditing) {
                    _configState['reset_actions'][index] = newItem;
                  } else {
                    _configState['reset_actions'].add(newItem);
                  }
                });
                _saveConfig();
                Navigator.pop(ctx);
                _showFeedback("Success", "Reset action ${isEditing ? 'updated' : 'added'}.");
              }, 
              child: const Text("SAVE ACTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  void _deleteResetAction(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Action?"),
        content: const Text("This will remove this reset action from the list."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              setState(() => _configState['reset_actions'].removeAt(index));
              _saveConfig();
              Navigator.pop(ctx);
            }, 
            child: const Text("DELETE", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _runResetAction(Map action) {
    bool isNuclear = action['isNuclear'] == true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isNuclear ? Icons.warning_rounded : Icons.info_rounded, color: isNuclear ? Colors.red : AdminTheme.royalBlue),
            const SizedBox(width: 12),
            Text(isNuclear ? "Critical Operation" : "Confirm Action"),
          ],
        ),
        content: Text("Are you sure you want to perform: '${action['title']}'?\n\n${action['desc']}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isNuclear ? Colors.red : AdminTheme.royalBlue),
            onPressed: () {
              // Simulate action
              Navigator.pop(ctx);
              
              if (isNuclear) {
                _showFeedback("CRITICAL ACTION", "Executing high-risk operation: ${action['title']}...");
              } else {
                _showFeedback("Action Started", "${action['title']} is being executed in the background.");
              }
              
              // Real destructive logic simulation
              Future.delayed(const Duration(seconds: 2), () {
                if (action['title'] == 'Full System Reset') {
                   _showFeedback("SYSTEM WIPE", "All local data has been successfully cleared.", isError: true);
                } else if (action['title'] == 'Clear Orders') {
                   _showFeedback("SUCCESS", "Order history has been purged.");
                } else {
                   _showFeedback("COMPLETE", "Operation '${action['title']}' finished successfully.");
                }
              });
            }, 
            child: const Text("CONFIRM & RUN", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  // --- COMMON COMPONENTS ---
  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)));
  }

  Widget _buildTabGrid(List<Widget> children) {
    return Wrap(spacing: 24, runSpacing: 24, children: children);
  }

  Widget _buildSettingSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(32), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AdminTheme.royalBlue, size: 22),
          ),
          const SizedBox(width: 20), 
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AdminTheme.darkNavy))
        ]),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 32),
        ...children,
      ]),
    );
  }

  Widget _buildSettingField(String label, String val, Function(String) onChanged, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)), 
          const SizedBox(height: 8),
          TextField(
            onChanged: onChanged, 
            controller: TextEditingController.fromValue(TextEditingValue(text: val, selection: TextSelection.collapsed(offset: val.length))),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.royalBlue, width: 1.5)),
              fillColor: AdminTheme.pearlWhite.withValues(alpha: 0.3),
              filled: true,
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy, fontSize: 14),
          )
        ]
      )
    );
  }

  Widget _buildStatusBadge(String status, {VoidCallback? onTap}) {
    Color color = status == "Active" ? AdminTheme.emeraldGreen : Colors.redAccent;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
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

  void _showFeedback(String title, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title: $msg"), backgroundColor: isError ? Colors.red : AdminTheme.royalBlue));
  }

  void _showConfirmDeleteDialog(String type, int index, String key) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text("Delete $type?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")), TextButton(onPressed: () { setState(() => (_configState[key] as List).removeAt(index)); Navigator.pop(ctx); }, child: const Text("DELETE"))]));
  }

  void _showAddEditItemDialog(String type, {int? index, Map<String, dynamic>? existingData}) {
    _showFeedback("Demo Mode", "Adding/Editing is disabled for this $type in simulation.");
  }

  // --- 6. INVENTORY MODULE (Fully Workable & Professional) ---
  Widget _buildInventoryModule() {
    bool isUnit = widget.mode == "Unit Measurement List";
    final String dataKey = isUnit ? 'unit_measurements' : 'ingredients';
    final List allItems = List.from(_configState[dataKey] ?? []);
    
    // Filter logic
    final filtered = allItems.where((i) {
      return i['name'].toString().toLowerCase().contains(_invSearchQuery.toLowerCase());
    }).toList();

    final visibleList = _displayCount == -1 ? filtered : filtered.take(_displayCount).toList();

    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 900;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionHeader(
            isUnit ? "Add Unit" : "Add Ingredient", 
            allItems.length,
            onAdd: () => _showAddEditInventoryDialog(null, isUnit),
          ),
          const SizedBox(height: 24),
          
          // Search & Display Filter Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AdminTheme.softShadow),
                  child: TextField(
                    onChanged: (v) => setState(() => _invSearchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search ${isUnit ? 'units' : 'ingredients'}...",
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: AdminTheme.royalBlue),
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
                  items: [5, 10, 20, 50, -1].map((int val) => DropdownMenuItem<int>(
                    value: val,
                    child: Text(val == -1 ? "Show All" : "Display $val", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )).toList(),
                  onChanged: (v) => setState(() => _displayCount = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (isMobile)
            _buildInventoryMobileList(visibleList, isUnit)
          else
            _buildInventoryTableDesktop(visibleList, isUnit),

          if (_displayCount != -1 && filtered.length > _displayCount) 
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _displayCount = -1),
                  child: Text("VIEW ALL ${filtered.length} ITEMS", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildInventoryTableDesktop(List items, bool isUnit) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(
              children: [
                const SizedBox(width: 40, child: Text("SL.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                Expanded(flex: 3, child: Text(isUnit ? "UNIT NAME" : "INGREDIENT NAME", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                if (isUnit)
                  const Expanded(flex: 2, child: Text("UNIT CODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))
                else ...[
                  const Expanded(flex: 2, child: Text("CATEGORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                  const Expanded(flex: 2, child: Text("STOCK LEVEL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                ],
                const Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                const SizedBox(width: 100, child: Center(child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(64), child: Text("No items found matching your search.", style: TextStyle(color: Colors.grey)))
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (ctx, i) {
                final item = items[i];
                // Find real index in master list for correct editing/deletion
                final String dataKey = isUnit ? 'unit_measurements' : 'ingredients';
                int realIndex = _configState[dataKey].indexOf(item);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                      Expanded(flex: 3, child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy))),
                      if (isUnit)
                        Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(item['short'], style: const TextStyle(color: AdminTheme.royalBlue, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)))
                      else ...[
                        Expanded(flex: 2, child: Text(item['category'], style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text("${item['stock']} ${item['unit']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy))),
                      ],
                      Expanded(flex: 2, child: Center(child: _buildStatusBadge(
                        item['status'], 
                        onTap: () => _toggleInventoryStatus(realIndex, isUnit)
                      ))),
                      SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 22), 
                              onPressed: () => _showAddEditInventoryDialog(realIndex, isUnit)
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), 
                              onPressed: () => _deleteInventoryItem(realIndex, isUnit)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryMobileList(List items, bool isUnit) {
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 20, backgroundColor: AdminTheme.royalBlue.withValues(alpha: 0.1), child: Text("${i + 1}", style: const TextStyle(color: AdminTheme.royalBlue, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(isUnit ? "Code: ${item['short']}" : "Category: ${item['category']}", style: const TextStyle(fontSize: 12, color: Colors.grey))])),
                  _buildStatusBadge(item['status'], onTap: () => _toggleInventoryStatus(i, isUnit)),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isUnit) Text("Stock: ${item['stock']} ${item['unit']}", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showAddEditInventoryDialog(i, isUnit), 
                        icon: const Icon(Icons.edit, size: 16), 
                        label: const Text("EDIT")
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteInventoryItem(i, isUnit), 
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red), 
                        label: const Text("REMOVE", style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // --- 7. SMS SETTING MODULE ---


  // --- 7. SMS SETTING MODULE ---
  Widget _buildSMSSettingModule() {
    bool isConfig = widget.mode == "SMS Configuration";
    if (isConfig) {
      final config = _configState['sms_config'];
      final rules = _configState['sms_rules'] as List;
      final history = _configState['sms_history'] as List;

      // Filter History Logic
      final filteredHistory = history.where((h) {
        bool matchesSearch = _smsSearchQuery.isEmpty || 
                            h['customer'].toString().toLowerCase().contains(_smsSearchQuery.toLowerCase()) ||
                            h['phone'].toString().contains(_smsSearchQuery);
        bool matchesType = _smsTypeFilter == "All Types" || h['type'] == _smsTypeFilter;
        bool matchesStatus = _smsStatusFilter == "All Status" || h['status'] == _smsStatusFilter;
        bool matchesToday = !_smsTodayOnly || h['time'].toString().contains('Today');
        return matchesSearch && matchesType && matchesStatus && matchesToday;
      }).toList();

      final limitedHistory = filteredHistory.take(_displayCount).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Service Toggle Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AdminTheme.softShadow,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.notifications_active_outlined, color: AdminTheme.royalBlue, size: 24),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SMS Notifications Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.darkNavy)),
                      Text("Automatically send SMS updates and alerts to customers and staff.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: config['service_enabled'] ?? true,
                  onChanged: (v) {
                    setState(() => config['service_enabled'] = v);
                    _saveConfig();
                  },
                  activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                  activeThumbColor: AdminTheme.royalBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. Rules Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_fix_high_rounded, size: 18, color: AdminTheme.royalBlue),
                  SizedBox(width: 12),
                  Text("Automatic SMS Rules", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAddSmsRuleDialog(), 
                icon: const Icon(Icons.add, size: 16), 
                label: const Text("Add New Rule", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
              ),
            ],
          ),
          const Divider(height: 32),
          ...rules.asMap().entries.map((entry) {
            int idx = entry.key;
            var r = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.darkNavy)),
                        Text(r['desc'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: r['enabled'],
                    onChanged: (v) {
                      setState(() => r['enabled'] = v);
                      _saveConfig();
                    },
                    activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                    activeThumbColor: AdminTheme.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), 
                    onPressed: () {
                      setState(() => rules.removeAt(idx));
                      _saveConfig();
                    }
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 48),


          // 3. History Section
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 18, color: AdminTheme.royalBlue),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SMS History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
                  Text("Track customer and restaurant notification messages", style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          const Divider(height: 48),

          // Summary Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSmsMiniStat(
                  "TOTAL SENT", 
                  "${history.length}", 
                  AdminTheme.royalBlue, 
                  _smsStatusFilter == "All Status" && !_smsTodayOnly,
                  onTap: () => setState(() { _smsStatusFilter = "All Status"; _smsTodayOnly = false; })
                ),
                _buildSmsMiniStat(
                  "DELIVERED", 
                  "${history.where((h)=>h['status']=='DELIVERED').length}", 
                  AdminTheme.emeraldGreen, 
                  _smsStatusFilter == "DELIVERED",
                  onTap: () => setState(() { _smsStatusFilter = "DELIVERED"; _smsTodayOnly = false; })
                ),
                _buildSmsMiniStat(
                  "FAILED", 
                  "${history.where((h)=>h['status']=='FAILED').length}", 
                  Colors.red, 
                  _smsStatusFilter == "FAILED",
                  onTap: () => setState(() { _smsStatusFilter = "FAILED"; _smsTodayOnly = false; })
                ),
                _buildSmsMiniStat(
                  "PENDING", 
                  "${history.where((h)=>h['status']=='PENDING').length}", 
                  Colors.orange, 
                  _smsStatusFilter == "PENDING",
                  onTap: () => setState(() { _smsStatusFilter = "PENDING"; _smsTodayOnly = false; })
                ),
                _buildSmsMiniStat(
                  "TODAY", 
                  "${history.where((h)=>h['time'].toString().contains('Today')).length}", 
                  Colors.blue, 
                  _smsTodayOnly,
                  onTap: () => setState(() { _smsStatusFilter = "All Status"; _smsTodayOnly = true; })
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Filter Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _smsSearchQuery = v),
                          decoration: const InputDecoration(hintText: "Search customer, phone...", border: InputBorder.none, hintStyle: TextStyle(fontSize: 13, color: Colors.grey)),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildSmsDropdown(_smsTypeFilter, ["All Types", "Order Ready", "Reservation", "OTP"], (v) => setState(() => _smsTypeFilter = v!)),
              const SizedBox(width: 12),
              _buildSmsDropdown(_smsStatusFilter, ["All Status", "DELIVERED", "SENT", "FAILED"], (v) => setState(() => _smsStatusFilter = v!)),
              const SizedBox(width: 12),
              _buildSmsDropdown("Display $_displayCount", ["Display 10", "Display 20", "Display 50"], (v) => setState(() => _displayCount = int.parse(v!.split(' ')[1]))),
            ],
          ),
          const SizedBox(height: 32),

          // History Table
          _buildSmsHistoryTable(limitedHistory),
          
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleSmsTestSend(),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text("SEND TEST NOTIFICATION"),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                ),
                const SizedBox(height: 16),
                const Text("Showing real-time logs for offline simulation environment.", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            )
          ),
        ],
      );
    } else {
      final List templates = _configState['sms_templates'];
      
      // Filter Logic
      final filtered = templates.where((t) {
        bool matchesSearch = _smsTemplateSearchQuery.isEmpty || t['name'].toString().toLowerCase().contains(_smsTemplateSearchQuery.toLowerCase());
        bool matchesStatus = _smsTemplateStatusFilter == "All" || t['status'] == _smsTemplateStatusFilter;
        return matchesSearch && matchesStatus;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Filter by Status:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  _buildTemplateStatusBtn("All"),
                  const SizedBox(width: 8),
                  _buildTemplateStatusBtn("Active"),
                  const SizedBox(width: 8),
                  _buildTemplateStatusBtn("Inactive"),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 250, height: 40,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                    child: TextField(
                      onChanged: (v) => setState(() => _smsTemplateSearchQuery = v),
                      decoration: const InputDecoration(hintText: "Search templates...", prefixIcon: Icon(Icons.search, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.only(top: 8)),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditTemplateDialog(null),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add Template"),
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue, padding: const EdgeInsets.symmetric(horizontal: 20)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text("Template Library", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
          const Divider(height: 40),
          
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
              mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 1.5,
            ),
            itemBuilder: (ctx, i) {
              final t = filtered[i];
              int realIdx = templates.indexOf(t);
              return _buildTemplateCard(t, realIdx);
            },
          ),
        ],
      );
    }
  }

  Widget _buildTemplateStatusBtn(String label) {
    bool isSelected = _smsTemplateStatusFilter == label;
    return InkWell(
      onTap: () => setState(() => _smsTemplateStatusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.royalBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AdminTheme.royalBlue : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            if (isSelected) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check, color: Colors.white, size: 14)),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map t, int idx) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
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
                decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(t['icon'] ?? Icons.sms_rounded, color: AdminTheme.royalBlue, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.darkNavy)),
                    Text(t['tag'], style: const TextStyle(color: AdminTheme.royalBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: t['status'] == 'Active', 
                onChanged: (v) {
                  setState(() => t['status'] = v ? 'Active' : 'Inactive');
                  _saveConfig();
                },
                activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                activeThumbColor: AdminTheme.royalBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t['desc'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text(t['body'], style: const TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.4)),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("Preview", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildIconButton(Icons.edit_note_rounded, Colors.blue, () => _showAddEditTemplateDialog(idx)),
              const SizedBox(width: 8),
              _buildIconButton(Icons.delete_outline_rounded, Colors.red, () {
                setState(() => (_configState['sms_templates'] as List).removeAt(idx));
                _saveConfig();
                _showFeedback("Templates", "Template removed successfully.");
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showAddEditTemplateDialog(int? idx) {
    final isEditing = idx != null;
    final data = isEditing ? _configState['sms_templates'][idx] : {};
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final tagCtrl = TextEditingController(text: data['tag'] ?? '');
    final descCtrl = TextEditingController(text: data['desc'] ?? '');
    final bodyCtrl = TextEditingController(text: data['body'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "Edit Template" : "Add New Template"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Template Name")),
              TextField(controller: tagCtrl, decoration: const InputDecoration(labelText: "Category/Tag")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Short Description")),
              const SizedBox(height: 16),
              TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: "Message Body", border: OutlineInputBorder()), maxLines: 4),
              const SizedBox(height: 8),
              const Text("Use {customer_name}, {restaurant_name}, etc. as placeholders.", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              final newItem = {
                'name': nameCtrl.text,
                'tag': tagCtrl.text,
                'desc': descCtrl.text,
                'body': bodyCtrl.text,
                'status': data['status'] ?? 'Active',
                'icon': data['icon'] ?? Icons.sms_rounded,
              };
              setState(() {
                if (isEditing) {
                  _configState['sms_templates'][idx] = newItem;
                } else {
                  _configState['sms_templates'].add(newItem);
                }
              });
              _saveConfig();
              Navigator.pop(ctx);
              _showFeedback("Success", "SMS template saved and synchronized.");
            }, 
            child: const Text("SAVE")
          ),
        ],
      ),
    );
  }

  Widget _buildSmsMiniStat(String label, String val, Color color, bool isSelected, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade100, width: 1.5),
          boxShadow: AdminTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? color : Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isSelected ? color : AdminTheme.darkNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items[0],
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSmsHistoryTable(List history) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("CUSTOMER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text("PHONE NUMBER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text("MESSAGE TYPE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 4, child: Text("MESSAGE PREVIEW", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                SizedBox(width: 80, child: Center(child: Text("ACTION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)))),
              ],
            ),
          ),
          ...history.map((h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade50))),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(h['customer'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy))),
                Expanded(flex: 2, child: Text(h['phone'], style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text(h['type'], style: const TextStyle(fontSize: 12, color: AdminTheme.royalBlue, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text(h['preview'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: (h['status'] == 'DELIVERED' ? Colors.green : AdminTheme.royalBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(h['status'], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: h['status'] == 'DELIVERED' ? Colors.green : AdminTheme.royalBlue)),
                )),
                SizedBox(width: 80, child: Center(child: IconButton(icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AdminTheme.royalBlue), onPressed: () {}))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // --- 8. BANK MODULE (Workable) ---
  Widget _buildBankModule() {
    bool isList = widget.mode == "Bank List";
    final String key = isList ? 'banks' : 'bank_transactions';
    final List items = List.from(_configState[key] ?? []);
    
    return Column(
      children: [
        _buildActionHeader(
          isList ? "Link Bank" : "New Transaction", 
          items.length,
          onAdd: () => _showAddEditBankDialog(null, isList),
        ),
        const SizedBox(height: 24),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          var b = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AdminTheme.softShadow),
            child: Row(
              children: [
                Icon(isList ? Icons.account_balance_rounded : Icons.receipt_long_rounded, color: AdminTheme.royalBlue),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isList ? b['name'] : b['bank'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(isList ? "A/C: ${b['account']}" : "Date: ${b['date']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(isList ? b['balance'] : b['amount'], style: TextStyle(fontWeight: FontWeight.bold, color: isList ? AdminTheme.darkNavy : (b['type'] == 'Credit' ? Colors.green : Colors.red))),
                    Row(
                      children: [
                        _buildStatusBadge(b['status']),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                          onPressed: () => _showAddEditBankDialog(idx, isList),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- 9. LANGUAGE MODULE ---
  Widget _buildLanguageModule() {
    return ValueListenableBuilder<List<AppLanguage>>(
      valueListenable: LanguageService().languages,
      builder: (context, langs, _) {
        return ValueListenableBuilder<String>(
          valueListenable: LanguageService().currentLanguageCode,
          builder: (context, currentCode, _) {
            final total = langs.length;
            final active = langs.where((l) => l.status).length;
            final inactive = langs.where((l) => !l.status).length;
            final defaultCount = langs.where((l) => l.isDefault).length;

            // Statistics Bar Row
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Icon and Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AdminTheme.softShadow,
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: const Icon(Icons.g_translate_rounded, color: AdminTheme.royalBlue, size: 32),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Language Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                        const SizedBox(height: 4),
                        Text("Customize how your app speaks to your customers and staff.", style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _buildLanguageStatCard("TOTAL", total.toString(), isSelected: _langFilter == "TOTAL"),
                    _buildLanguageStatCard("ACTIVE", active.toString(), valueColor: const Color(0xFF00CBA9), isSelected: _langFilter == "ACTIVE"),
                    _buildLanguageStatCard("INACTIVE", inactive.toString(), valueColor: Colors.orange, isSelected: _langFilter == "INACTIVE"),
                    _buildLanguageStatCard("DEFAULT", defaultCount.toString(), valueColor: Colors.purple, isSelected: _langFilter == "DEFAULT"),
                  ],
                ),
                const SizedBox(height: 40),

                // Section Title and Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Language List ($_langFilter)", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                        const SizedBox(height: 4),
                        Text("Showing $total records found in database.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddNewLanguageDialog(),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text("Add New Language", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CBA9),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Responsive Layout Box without strict heights to remove overfitting/yellow warning bars
                LayoutBuilder(
                  builder: (context, constraints) {
                    final filteredLangs = langs.where((l) {
                      if (_langFilter == "ACTIVE") return l.status;
                      if (_langFilter == "INACTIVE") return !l.status;
                      if (_langFilter == "DEFAULT") return l.isDefault;
                      return true;
                    }).toList();

                    int crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredLangs.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: constraints.maxWidth > 1400 ? 1.4 : 1.25,
                      ),
                      itemBuilder: (ctx, i) {
                        return _buildLanguageCard(filteredLangs[i]);
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageStatCard(String label, String value, {bool isSelected = false, Color? valueColor}) {
    return InkWell(
      onTap: () {
        setState(() {
          _langFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AdminTheme.royalBlue, width: 2) : Border.all(color: Colors.grey.shade100),
          boxShadow: AdminTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isSelected ? AdminTheme.royalBlue : Colors.grey, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: valueColor ?? AdminTheme.darkNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(AppLanguage l) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
        border: l.isDefault 
            ? Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 2) 
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AdminTheme.royalBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(l.code.toUpperCase(), style: const TextStyle(color: AdminTheme.royalBlue, fontWeight: FontWeight.w900, fontSize: 16))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(l.nativeName, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (l.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("DEFAULT", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
            ],
          ),
          const Spacer(),
          const Text("Translation Progress", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (l.code == 'ds' || l.name.toLowerCase() == 'sfsf') ? 0.0 : 1.0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CBA9)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text((l.code == 'ds' || l.name.toLowerCase() == 'sfsf') ? "0%" : "100%", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
            ],
          ),
          const Spacer(),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.status ? "DISPLAY ON " : "DISPLAY OFF",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: l.status ? const Color(0xFF00CBA9) : Colors.grey.shade400),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: l.status,
                      activeTrackColor: const Color(0xFF00CBA9).withValues(alpha: 0.3),
                      activeColor: const Color(0xFF00CBA9),
                      onChanged: l.isDefault ? null : (v) {
                        LanguageService().toggleLanguageStatus(l.id);
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      l.isDefault ? Icons.star_rounded : Icons.star_outline_rounded, 
                      color: Colors.orange, 
                      size: 24
                    ),
                    onPressed: () => LanguageService().toggleDefaultLanguage(l.id),
                    tooltip: l.isDefault ? "Unset Default" : "Set as Default",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: AdminTheme.royalBlue, size: 24),
                    onPressed: () => _showEditLanguageDialog(l),
                    tooltip: "Edit Language",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  if (!l.isDefault) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteLanguageConfirmation(l),
                      tooltip: "Remove Language",
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddNewLanguageDialog() {
    final nameCtrl = TextEditingController();
    final nativeCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
            SizedBox(width: 12),
            Text("Add New Language", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl, 
              decoration: const InputDecoration(labelText: "Language Name (e.g. French)", hintText: "English, Nepali, etc.")
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nativeCtrl, 
              decoration: const InputDecoration(labelText: "Native Name (e.g. Français)", hintText: "Native characters supported")
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl, 
              decoration: const InputDecoration(labelText: "Language Code (e.g. fr)", hintText: "Two letter ISO code preferred")
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) {
                _showFeedback("Error", "Name and Code are required.", isError: true);
                return;
              }
              
              final newLang = AppLanguage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                nativeName: nativeCtrl.text.trim(),
                code: codeCtrl.text.trim().toLowerCase(),
                status: true,
                isDefault: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await LanguageService().addLanguage(newLang);
              Navigator.pop(ctx);
              _showFeedback("Success", "${newLang.name} added to the system.");
            },
            child: const Text("SAVE LANGUAGE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditLanguageDialog(AppLanguage l) {
    final nameCtrl = TextEditingController(text: l.name);
    final nativeCtrl = TextEditingController(text: l.nativeName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AdminTheme.royalBlue),
            const SizedBox(width: 12),
            Text("Edit: ${l.name}"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Language Name")),
            const SizedBox(height: 12),
            TextField(controller: nativeCtrl, decoration: const InputDecoration(labelText: "Native Name")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                _showFeedback("Error", "Language name cannot be empty.", isError: true);
                return;
              }
              
              final updatedLang = AppLanguage(
                id: l.id,
                name: nameCtrl.text.trim(),
                nativeName: nativeCtrl.text.trim(),
                code: l.code,
                status: l.status,
                isDefault: l.isDefault,
                createdAt: l.createdAt,
                updatedAt: DateTime.now(),
              );
              
              await LanguageService().updateLanguage(updatedLang);
              Navigator.pop(ctx);
              _showFeedback("Updated", "${updatedLang.name} updated successfully.");
            },
            child: const Text("UPDATE CHANGES", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteLanguageConfirmation(AppLanguage l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            const Text("Remove Language?"),
          ],
        ),
        content: Text("Are you sure you want to remove '${l.name}' from your application? All translations associated with this language will be lost locally."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await LanguageService().deleteLanguage(l.id);
              Navigator.pop(ctx);
              _showFeedback("Deleted", "${l.name} has been removed.");
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 11. PAYMENT MODULE ---
  Widget _buildPaymentModule() {
    bool isSetup = widget.mode == "Payment Setup";
    if (isSetup) {
      final List allSetup = List.from(_configState['payment_setup_list'] ?? []);
      final filtered = allSetup.where((s) {
        return s['name'].toString().toLowerCase().contains(_paySetupSearchQuery.toLowerCase()) ||
               s['value'].toString().toLowerCase().contains(_paySetupSearchQuery.toLowerCase());
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Digital Gateway Configuration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              ElevatedButton.icon(
                onPressed: () => _showAddEditPaymentSetupDialog(null), 
                icon: const Icon(Icons.add), 
                label: const Text("ADD SETUP CONFIG"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.royalBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
            child: TextField(
              onChanged: (v) => setState(() => _paySetupSearchQuery = v),
              decoration: const InputDecoration(hintText: "Search setup keys or values...", border: InputBorder.none, icon: Icon(Icons.search)),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24), 
              boxShadow: AdminTheme.softShadow,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: AdminTheme.royalBlue.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 50, child: Text("SL.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 3, child: Text("CONFIGURATION KEY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 4, child: Text("VALUE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                      SizedBox(width: 120, child: Center(child: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  const Padding(padding: EdgeInsets.all(64), child: Text("No configuration found.", style: TextStyle(color: Colors.grey)))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade50),
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      int realIdx = _configState['payment_setup_list'].indexOf(s);
                      bool isToggle = s['type'] == 'toggle';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                          children: [
                            SizedBox(width: 50, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                            Expanded(
                              flex: 3, 
                              child: Row(
                                children: [
                                  Icon(s['icon'] ?? Icons.settings_rounded, size: 18, color: AdminTheme.royalBlue),
                                  const SizedBox(width: 12),
                                  Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy)),
                                ],
                              )
                            ),
                            Expanded(
                              flex: 4, 
                              child: isToggle 
                                ? Text(s['value'] == true ? 'ACTIVE (SANDBOX)' : 'PRODUCTION MODE', style: TextStyle(color: s['value'] == true ? Colors.blue : Colors.green, fontWeight: FontWeight.bold, fontSize: 12))
                                : Text(s['value'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis)
                            ),
                            Expanded(
                              flex: 2, 
                              child: Center(
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Switch.adaptive(
                                    value: s['status'] == 'Active',
                                    onChanged: (v) {
                                      setState(() => s['status'] = v ? 'Active' : 'Inactive');
                                      _saveConfig();
                                    },
                                    activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                                    activeColor: AdminTheme.royalBlue,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24), 
                                    onPressed: () => _showAddEditPaymentSetupDialog(realIdx),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), 
                                    onPressed: () => _showConfirmDeleteDialog("Setup Key", realIdx, "payment_setup_list"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      final List allItems = List.from(_configState['payment_methods'] ?? []);
      
      // Stats
      final total = allItems.length;
      final active = allItems.where((i) => i['status'] == 'Active').length;
      final inactive = allItems.where((i) => i['status'] != 'Active').length;

      final filtered = allItems.where((i) {
        bool matchesSearch = i['name'].toString().toLowerCase().contains(_paySearchQuery.toLowerCase()) ||
                             i['gateway'].toString().toLowerCase().contains(_paySearchQuery.toLowerCase());
        bool matchesFilter = true;
        if (_payFilter == "ACTIVE") matchesFilter = i['status'] == 'Active';
        else if (_payFilter == "INACTIVE") matchesFilter = i['status'] != 'Active';
        
        return matchesSearch && matchesFilter;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildPayStatCard("TOTAL", total.toString(), isSelected: _payFilter == "TOTAL"),
              _buildPayStatCard("ACTIVE", active.toString(), valueColor: Colors.green, isSelected: _payFilter == "ACTIVE"),
              _buildPayStatCard("INACTIVE", inactive.toString(), valueColor: Colors.orange, isSelected: _payFilter == "INACTIVE"),
            ],
          ),
          const SizedBox(height: 40),

          // Search & Add Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
                  child: TextField(
                    onChanged: (v) => setState(() => _paySearchQuery = v),
                    decoration: const InputDecoration(hintText: "Search payment methods...", border: InputBorder.none, icon: Icon(Icons.search)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddEditPaymentMethodDialog(null), 
                icon: const Icon(Icons.add), 
                label: const Text("ADD METHOD"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.royalBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Table Layout
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24), 
              boxShadow: AdminTheme.softShadow,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: AdminTheme.royalBlue.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 50, child: Text("SL.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 3, child: Text("METHOD NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 3, child: Text("GATEWAY / PROVIDER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                      SizedBox(width: 120, child: Center(child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  const Padding(padding: EdgeInsets.all(64), child: Text("No payment methods found.", style: TextStyle(color: Colors.grey)))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade50),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      int realIdx = _configState['payment_methods'].indexOf(item);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                          children: [
                            SizedBox(width: 50, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                            Expanded(
                              flex: 3, 
                              child: Row(
                                children: [
                                  Icon(item['icon'] ?? Icons.payment_rounded, size: 20, color: AdminTheme.royalBlue),
                                  const SizedBox(width: 12),
                                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.darkNavy)),
                                ],
                              )
                            ),
                            Expanded(
                              flex: 3, 
                              child: Text(
                                item['gateway'] ?? 'None', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)
                              )
                            ),
                            Expanded(
                              flex: 2, 
                              child: Center(
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Switch.adaptive(
                                    value: item['status'] == 'Active',
                                    onChanged: (v) {
                                      setState(() => item['status'] = v ? 'Active' : 'Inactive');
                                      _saveConfig();
                                    },
                                    activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                                    activeColor: AdminTheme.royalBlue,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24), 
                                    onPressed: () => _showAddEditPaymentMethodDialog(realIdx)
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22), 
                                    onPressed: () => _showConfirmDeleteDialog("Payment Method", realIdx, "payment_methods")
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      );
    }
  }

  void _showAddEditPaymentSetupDialog(int? index) {
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState['payment_setup_list'][index] : {};
    
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final valCtrl = TextEditingController(text: data['value']?.toString() ?? '');
    String selectedType = data['type'] ?? 'text';
    bool toggleVal = data['value'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
              const SizedBox(width: 12),
              Text(isEditing ? "Edit Setup Key" : "Add Setup Config", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Configuration Name")),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['text', 'number', 'toggle'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                  onChanged: (v) => setModalState(() => selectedType = v!),
                  decoration: const InputDecoration(labelText: "Data Type"),
                ),
                const SizedBox(height: 16),
                selectedType == 'toggle'
                  ? SwitchListTile.adaptive(
                      title: const Text("Initial State"),
                      value: toggleVal, 
                      onChanged: (v) => setModalState(() => toggleVal = v),
                    )
                  : TextField(
                      controller: valCtrl, 
                      decoration: const InputDecoration(labelText: "Config Value"),
                      keyboardType: selectedType == 'number' ? TextInputType.number : TextInputType.text,
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                setState(() {
                  final newItem = {
                    'name': nameCtrl.text.trim(),
                    'value': selectedType == 'toggle' ? toggleVal : valCtrl.text.trim(),
                    'key': data['key'] ?? 'pay_custom_${DateTime.now().millisecondsSinceEpoch}',
                    'icon': data['icon'] ?? Icons.payment_rounded,
                    'type': selectedType,
                    'status': data['status'] ?? 'Active',
                  };
                  if (isEditing) {
                    _configState['payment_setup_list'][index] = newItem;
                  } else {
                    _configState['payment_setup_list'].add(newItem);
                  }
                });
                _saveConfig();
                Navigator.pop(ctx);
                _showFeedback("Success", "Payment setup configuration updated.");
              }, 
              child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayStatCard(String label, String value, {bool isSelected = false, Color? valueColor}) {
    return InkWell(
      onTap: () => setState(() => _payFilter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AdminTheme.royalBlue, width: 2) : Border.all(color: Colors.grey.shade100),
          boxShadow: AdminTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isSelected ? AdminTheme.royalBlue : Colors.grey, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor ?? AdminTheme.darkNavy)),
          ],
        ),
      ),
    );
  }

  void _showAddEditPaymentMethodDialog(int? index) {
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState['payment_methods'][index] : {};
    
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final gatewayCtrl = TextEditingController(text: data['gateway'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
            const SizedBox(width: 12),
            Text(isEditing ? "Edit Payment Method" : "Add Payment Method", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Method Name", hintText: "e.g. Cash, Fonepay")),
            const SizedBox(height: 16),
            TextField(controller: gatewayCtrl, decoration: const InputDecoration(labelText: "Gateway / Provider", hintText: "e.g. E-Sewa, None")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              setState(() {
                final newItem = {
                  'name': nameCtrl.text.trim(),
                  'gateway': gatewayCtrl.text.trim(),
                  'icon': data['icon'] ?? Icons.payment_rounded,
                  'status': data['status'] ?? 'Active',
                };
                if (isEditing) {
                  _configState['payment_methods'][index] = newItem;
                } else {
                  _configState['payment_methods'].add(newItem);
                }
              });
              _saveConfig();
              Navigator.pop(ctx);
              _showFeedback("Success", "Payment method saved.");
            }, 
            child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  // --- 12. SHIPPING MODULE ---
  Widget _buildShippingModule() {
    final List allItems = List.from(_configState['shipping_methods'] ?? []);
    
    // Stats
    final total = allItems.length;
    final active = allItems.where((i) => i['status'] == 'Active').length;
    final inactive = allItems.where((i) => i['status'] != 'Active').length;

    final filtered = allItems.where((i) {
      bool matchesSearch = i['name'].toString().toLowerCase().contains(_shipSearchQuery.toLowerCase());
      bool matchesFilter = true;
      if (_shipFilter == "ACTIVE") matchesFilter = i['status'] == 'Active';
      else if (_shipFilter == "INACTIVE") matchesFilter = i['status'] != 'Active';
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Row
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildShipStatCard("TOTAL", total.toString(), isSelected: _shipFilter == "TOTAL"),
            _buildShipStatCard("ACTIVE", active.toString(), valueColor: Colors.green, isSelected: _shipFilter == "ACTIVE"),
            _buildShipStatCard("INACTIVE", inactive.toString(), valueColor: Colors.orange, isSelected: _shipFilter == "INACTIVE"),
          ],
        ),
        const SizedBox(height: 40),

        // Search & Add Bar
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminTheme.softShadow),
                child: TextField(
                  onChanged: (v) => setState(() => _shipSearchQuery = v),
                  decoration: const InputDecoration(hintText: "Search shipping methods...", border: InputBorder.none, icon: Icon(Icons.search)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddEditShippingMethodDialog(null), 
              icon: const Icon(Icons.add), 
              label: const Text("ADD SHIPPING"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.royalBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Table Layout
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            boxShadow: AdminTheme.softShadow,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: AdminTheme.royalBlue.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 50, child: Text("SL.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 3, child: Text("METHOD NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("COST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("EST. TIME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    SizedBox(width: 120, child: Center(child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                const Padding(padding: EdgeInsets.all(64), child: Text("No shipping methods found.", style: TextStyle(color: Colors.grey)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade50),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    int realIdx = _configState['shipping_methods'].indexOf(item);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Row(
                        children: [
                          SizedBox(width: 50, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                          Expanded(
                            flex: 3, 
                            child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.darkNavy))
                          ),
                          Expanded(
                            flex: 2, 
                            child: Text(
                              item['cost'], 
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AdminTheme.royalBlue)
                            )
                          ),
                          Expanded(
                            flex: 2, 
                            child: Text(
                              item['time'], 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)
                            )
                          ),
                          Expanded(
                            flex: 2, 
                            child: Center(
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch.adaptive(
                                  value: item['status'] == 'Active',
                                  onChanged: (v) {
                                    setState(() => item['status'] = v ? 'Active' : 'Inactive');
                                    _saveConfig();
                                  },
                                  activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
                                  activeColor: AdminTheme.royalBlue,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24), 
                                  onPressed: () => _showAddEditShippingMethodDialog(realIdx)
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22), 
                                  onPressed: () => _showConfirmDeleteDialog("Shipping Method", realIdx, "shipping_methods")
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShipStatCard(String label, String value, {bool isSelected = false, Color? valueColor}) {
    return InkWell(
      onTap: () => setState(() => _shipFilter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AdminTheme.royalBlue, width: 2) : Border.all(color: Colors.grey.shade100),
          boxShadow: AdminTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isSelected ? AdminTheme.royalBlue : Colors.grey, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor ?? AdminTheme.darkNavy)),
          ],
        ),
      ),
    );
  }

  void _showAddEditShippingMethodDialog(int? index) {
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState['shipping_methods'][index] : {};
    
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final costCtrl = TextEditingController(text: data['cost'] ?? '');
    final timeCtrl = TextEditingController(text: data['time'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
            const SizedBox(width: 12),
            Text(isEditing ? "Edit Shipping Method" : "Add Shipping Method", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Method Name", hintText: "e.g. Standard Delivery")),
            const SizedBox(height: 16),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: "Cost", hintText: "e.g. NPR 50")),
            const SizedBox(height: 16),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "Est. Time", hintText: "e.g. 30-45 min")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              setState(() {
                final newItem = {
                  'name': nameCtrl.text.trim(),
                  'cost': costCtrl.text.trim(),
                  'time': timeCtrl.text.trim(),
                  'status': data['status'] ?? 'Active',
                };
                if (isEditing) {
                  _configState['shipping_methods'][index] = newItem;
                } else {
                  _configState['shipping_methods'].add(newItem);
                }
              });
              _saveConfig();
              Navigator.pop(ctx);
              _showFeedback("Success", "Shipping method saved.");
            }, 
            child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _toggleInventoryStatus(int index, bool isUnit) {
    final String key = isUnit ? 'unit_measurements' : 'ingredients';
    setState(() {
      final List list = _configState[key];
      final currentStatus = list[index]['status'];
      list[index]['status'] = currentStatus == 'Active' ? 'Inactive' : 'Active';
    });
    _saveConfig();
    _showFeedback("Status Updated", "Account marked as ${_configState[key][index]['status']}");
  }

  void _deleteInventoryItem(int index, bool isUnit) {
    final String key = isUnit ? 'unit_measurements' : 'ingredients';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove ${isUnit ? 'Unit' : 'Ingredient'}?"),
        content: const Text("This item will be deleted from your local configuration."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              setState(() => (_configState[key] as List).removeAt(index));
              _saveConfig();
              Navigator.pop(ctx);
              _showFeedback("Deleted", "Item removed successfully");
            }, 
            child: const Text("DELETE", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showAddEditLocationDialog(int? index, String key, String type) {
    final bool isEditing = index != null;
    final Map<String, dynamic> existing = isEditing ? _configState[key][index] : {};
    bool isCurrency = type == "Currency";
    bool isCountry = type == "Country";
    bool isState = type == "State";
    bool isCity = type == "City";

    final nameCtrl = TextEditingController(text: existing['name'] ?? '');
    final codeCtrl = TextEditingController(text: existing['code'] ?? '');
    final symbolCtrl = TextEditingController(text: existing['symbol'] ?? '');
    final phoneCtrl = TextEditingController(text: existing['phone'] ?? '');
    final parentCtrl = TextEditingController(text: isState ? (existing['country'] ?? '') : (existing['state'] ?? ''));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AdminTheme.royalBlue),
            const SizedBox(width: 12),
            Text("${isEditing ? 'Edit' : 'Add'} $type", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl, 
                decoration: InputDecoration(labelText: "$type Name", hintText: "e.g. ${isCurrency ? 'Nepalese Rupee' : (isCountry ? 'Nepal' : (isState ? 'Lumbini' : 'Butwal'))}")
              ),
              if (isCurrency) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Currency Code", hintText: "e.g. NPR"))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: symbolCtrl, decoration: const InputDecoration(labelText: "Symbol", hintText: "e.g. Rs."))),
                  ],
                ),
              ],
              if (isCountry) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Country Code", hintText: "e.g. NP"))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Prefix", hintText: "e.g. +977"))),
                  ],
                ),
              ],
              if (isState) ...[
                const SizedBox(height: 16),
                TextField(controller: parentCtrl, decoration: const InputDecoration(labelText: "Country", hintText: "e.g. Nepal")),
              ],
              if (isCity) ...[
                const SizedBox(height: 16),
                TextField(controller: parentCtrl, decoration: const InputDecoration(labelText: "State", hintText: "e.g. Lumbini")),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              setState(() {
                final Map<String, dynamic> newItem = {
                  'name': nameCtrl.text.trim(),
                  'status': existing['status'] ?? 'Active',
                };
                if (isCurrency) {
                  newItem['code'] = codeCtrl.text.trim().toUpperCase();
                  newItem['symbol'] = symbolCtrl.text.trim();
                } else if (isCountry) {
                  newItem['code'] = codeCtrl.text.trim().toUpperCase();
                  newItem['phone'] = phoneCtrl.text.trim();
                } else if (isState) {
                  newItem['country'] = parentCtrl.text.trim();
                } else if (isCity) {
                  newItem['state'] = parentCtrl.text.trim();
                }

                if (isEditing) {
                  _configState[key][index] = newItem;
                } else {
                  (_configState[key] as List).insert(0, newItem);
                }
              });
              _saveConfig();
              Navigator.pop(ctx);
              _showFeedback("Success", "$type saved successfully.");
            }, 
            child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showAddEditBankDialog(int? index, bool isList) {
    final String key = isList ? 'banks' : 'bank_transactions';
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState[key][index] : {};
    
    final ctrl1 = TextEditingController(text: isList ? (data['name'] ?? '') : (data['bank'] ?? ''));
    final ctrl2 = TextEditingController(text: isList ? (data['account'] ?? '') : (data['amount'] ?? ''));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${isEditing ? 'Edit' : 'Add'} ${isList ? 'Bank' : 'Transaction'}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrl1, decoration: InputDecoration(labelText: isList ? "Bank Name" : "Bank Reference")),
            TextField(controller: ctrl2, decoration: InputDecoration(labelText: isList ? "Account Number" : "Amount (NPR)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final Map<String, dynamic> newItem = {
                  'status': data['status'] ?? 'Active',
                };
                if (isList) {
                  newItem['name'] = ctrl1.text;
                  newItem['account'] = ctrl2.text;
                  newItem['branch'] = data['branch'] ?? 'Main';
                  newItem['balance'] = data['balance'] ?? 'NPR 0';
                } else {
                  newItem['bank'] = ctrl1.text;
                  newItem['amount'] = ctrl2.text;
                  newItem['date'] = data['date'] ?? DateFormat('dd MMM yyyy').format(DateTime.now());
                  newItem['type'] = data['type'] ?? 'Credit';
                }

                if (isEditing) {
                  _configState[key][index] = newItem;
                } else {
                  (_configState[key] as List).insert(0, newItem);
                }
              });
              _saveConfig();
              Navigator.pop(ctx);
              _showFeedback("Saved", "Transaction data updated.");
            }, 
            child: const Text("SAVE")
          ),
        ],
      ),
    );
  }

  void _showAddEditInventoryDialog(int? index, bool isUnit) {
    final String key = isUnit ? 'unit_measurements' : 'ingredients';
    final bool isEditing = index != null;
    final Map<String, dynamic> data = isEditing ? _configState[key][index] : {};

    final nameController = TextEditingController(text: data['name'] ?? '');
    final extraController = TextEditingController(text: isUnit ? (data['short'] ?? '') : (data['stock'] ?? '0'));
    String selectedCat = data['category'] ?? 'Grain';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(isEditing ? "Edit ${isUnit ? 'Unit' : 'Ingredient'}" : "Add New ${isUnit ? 'Unit' : 'Ingredient'}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: InputDecoration(labelText: "${isUnit ? 'Unit' : 'Ingredient'} Name"),
                autofocus: true,
              ),
              if (isUnit)
                TextField(controller: extraController, decoration: const InputDecoration(labelText: "Unit Code (e.g. kg)"))
              else ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  items: ['Grain', 'Oil', 'Meat', 'Vegetable', 'Dairy'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => selectedCat = v!),
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                const SizedBox(height: 16),
                TextField(controller: extraController, decoration: const InputDecoration(labelText: "Current Stock"), keyboardType: TextInputType.number),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                   _showFeedback("Error", "Name cannot be empty", isError: true);
                   return;
                }
                
                final Map<String, dynamic> newItem = {
                  'name': nameController.text.trim(),
                  'status': data['status'] ?? 'Active',
                };

                if (isUnit) {
                  newItem['short'] = extraController.text.trim();
                } else {
                  newItem['category'] = selectedCat;
                  newItem['stock'] = extraController.text.trim();
                  newItem['unit'] = data['unit'] ?? 'kg';
                }

                setState(() {
                  if (isEditing) {
                    _configState[key][index] = newItem;
                  } else {
                    (_configState[key] as List).insert(0, newItem);
                  }
                });
                _saveConfig();
                Navigator.pop(ctx);
                _showFeedback(isEditing ? "Updated" : "Added", "${newItem['name']} saved locally");
              },
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader(String label, int count, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Total Records: $count", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: onAdd ?? () {}, 
          icon: const Icon(Icons.add, size: 16), 
          label: Text(label.toUpperCase())
        ),
      ],
    );
  }

  void _handleSmsTestSend() {
    setState(() {
      _configState['sms_history'].insert(0, {
        'customer': 'Test User',
        'phone': '9800000000',
        'type': 'OTP',
        'preview': 'Your Chiyalaa verification code is: 123456',
        'status': 'DELIVERED',
        'time': 'Today, ${DateFormat('hh:mm A').format(DateTime.now())}'
      });
    });
    _saveConfig();
    _showFeedback("SMS Hub", "Test notification log recorded and dispatched.");
  }

  void _showAddSmsRuleDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New SMS Rule"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Rule Name (e.g. Low Stock Alert)")),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              setState(() {
                _configState['sms_rules'].add({
                  'name': nameCtrl.text,
                  'desc': descCtrl.text,
                  'enabled': true,
                });
              });
              _saveConfig();
              Navigator.pop(ctx);
            }, 
            child: const Text("ADD RULE")
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, String sub, bool val, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy, fontSize: 14)), 
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.3))
              ]
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: val, 
            onChanged: onChanged, 
            activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3),
            activeThumbColor: AdminTheme.royalBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildGenericList() => const Center(child: Text("Module placeholder."));
}
