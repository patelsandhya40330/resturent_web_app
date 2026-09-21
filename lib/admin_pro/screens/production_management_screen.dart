import 'package:flutter/material.dart';
import '../admin_theme.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// --- ENUMS & MODELS ---

enum ProductionStatus { planned, pending, inProgress, partiallyCompleted, completed, cancelled }
enum WasteReason { overproduction, spoilage, burnt, damaged, expired, preparationWaste, customerReturn, other }
enum ProductionPriority { low, normal, high, urgent }

class ProductionUnitModel {
  final String id;
  String name;
  String code;
  String type;
  String manager;
  String location;
  String contact;
  int dailyCapacity;
  String capacityUnit;
  String openingTime;
  String closingTime;
  List<String> workingDays;
  String description;
  bool isActive;

  ProductionUnitModel({
    required this.id, required this.name, required this.code, required this.type,
    required this.manager, required this.dailyCapacity, required this.openingTime,
    required this.closingTime, required this.description, this.location = "Main Branch",
    this.contact = "", this.capacityUnit = "Meals", this.workingDays = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'code': code, 'type': type, 'manager': manager,
    'dailyCapacity': dailyCapacity, 'capacityUnit': capacityUnit,
    'openingTime': openingTime, 'closingTime': closingTime, 'workingDays': workingDays,
    'description': description, 'location': location, 'contact': contact, 'isActive': isActive,
  };

  factory ProductionUnitModel.fromJson(Map<String, dynamic> json) => ProductionUnitModel(
    id: json['id'], name: json['name'], code: json['code'], type: json['type'] ?? "Kitchen",
    manager: json['manager'], dailyCapacity: json['dailyCapacity'],
    capacityUnit: json['capacityUnit'] ?? "Meals", openingTime: json['openingTime'],
    closingTime: json['closingTime'], workingDays: List<String>.from(json['workingDays'] ?? []),
    description: json['description'], location: json['location'] ?? "Main Branch",
    contact: json['contact'] ?? "", isActive: json['isActive'] ?? true,
  );
}

class AssignedProductModel {
  final String productId;
  String name;
  String category;
  double standardQty;
  int prepTime;
  int priority;
  bool isActive;

  AssignedProductModel({
    required this.productId, required this.name, required this.category,
    required this.standardQty, required this.prepTime, required this.priority,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId, 'name': name, 'category': category,
    'standardQty': standardQty, 'prepTime': prepTime, 'priority': priority, 'isActive': isActive,
  };

  factory AssignedProductModel.fromJson(Map<String, dynamic> json) => AssignedProductModel(
    productId: json['productId'], name: json['name'], category: json['category'],
    standardQty: json['standardQty'].toDouble(), prepTime: json['prepTime'],
    priority: json['priority'], isActive: json['isActive'] ?? true,
  );
}

class ProductionPlanModel {
  final String id;
  DateTime date;
  String unitId;
  String productId;
  double plannedQty;
  double producedQty;
  ProductionStatus status;
  String staff;
  String startTime;
  String endTime;
  String priority;
  String notes;

  ProductionPlanModel({
    required this.id, required this.date, required this.unitId, required this.productId,
    required this.plannedQty, this.producedQty = 0, required this.status,
    required this.staff, required this.startTime, required this.endTime,
    required this.priority, required this.notes,
  });

  double get remainingQty => plannedQty - producedQty;

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'unitId': unitId, 'productId': productId,
    'plannedQty': plannedQty, 'producedQty': producedQty, 'status': status.index,
    'staff': staff, 'startTime': startTime, 'endTime': endTime, 'priority': priority, 'notes': notes,
  };

  factory ProductionPlanModel.fromJson(Map<String, dynamic> json) => ProductionPlanModel(
    id: json['id'], date: DateTime.parse(json['date']), unitId: json['unitId'],
    productId: json['productId'], plannedQty: json['plannedQty'].toDouble(),
    producedQty: json['producedQty'].toDouble(), status: ProductionStatus.values[json['status']],
    staff: json['staff'], startTime: json['startTime'], endTime: json['endTime'],
    priority: json['priority'], notes: json['notes'],
  );
}

class ProductionBatchModel {
  final String id;
  DateTime date;
  String unitId;
  String productId;
  double plannedQty;
  double actualQty;
  String startTime;
  String endTime;
  String staff;
  ProductionStatus status;
  String notes;

  ProductionBatchModel({
    required this.id, required this.date, required this.unitId, required this.productId,
    required this.plannedQty, required this.actualQty, required this.startTime,
    required this.endTime, required this.staff, required this.status, required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'unitId': unitId, 'productId': productId,
    'plannedQty': plannedQty, 'actualQty': actualQty, 'startTime': startTime,
    'endTime': endTime, 'staff': staff, 'status': status.index, 'notes': notes,
  };

  factory ProductionBatchModel.fromJson(Map<String, dynamic> json) => ProductionBatchModel(
    id: json['id'], date: DateTime.parse(json['date']), unitId: json['unitId'],
    productId: json['productId'], plannedQty: json['plannedQty'].toDouble(),
    actualQty: json['actualQty'].toDouble(), startTime: json['startTime'],
    endTime: json['endTime'], staff: json['staff'], status: ProductionStatus.values[json['status']],
    notes: json['notes'],
  );
}

class MaterialUsageModel {
  final String id;
  String productionId;
  String ingredient;
  double plannedQty;
  double actualQty;
  String unit;
  String notes;

  MaterialUsageModel({
    required this.id, required this.productionId, required this.ingredient,
    required this.plannedQty, required this.actualQty, required this.unit, required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'productionId': productionId, 'ingredient': ingredient,
    'plannedQty': plannedQty, 'actualQty': actualQty, 'unit': unit, 'notes': notes,
  };

  factory MaterialUsageModel.fromJson(Map<String, dynamic> json) => MaterialUsageModel(
    id: json['id'], productionId: json['productionId'], ingredient: json['ingredient'],
    plannedQty: json['plannedQty'].toDouble(), actualQty: json['actualQty'].toDouble(),
    unit: json['unit'], notes: json['notes'],
  );
}

class ProductionWasteModel {
  final String id;
  DateTime date;
  String unitId;
  String productId;
  double quantity;
  String unit;
  WasteReason reason;
  String recordedBy;
  String notes;

  ProductionWasteModel({
    required this.id, required this.date, required this.unitId, required this.productId,
    required this.quantity, required this.unit, required this.reason,
    required this.recordedBy, required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'unitId': unitId, 'productId': productId,
    'quantity': quantity, 'unit': unit, 'reason': reason.index, 'recordedBy': recordedBy, 'notes': notes,
  };

  factory ProductionWasteModel.fromJson(Map<String, dynamic> json) => ProductionWasteModel(
    id: json['id'], date: DateTime.parse(json['date']), unitId: json['unitId'],
    productId: json['productId'], quantity: json['quantity'].toDouble(), unit: json['unit'],
    reason: WasteReason.values[json['reason']], recordedBy: json['recordedBy'], notes: json['notes'],
  );
}

class ProductionSetModel {
  final String id;
  String name;
  String code;
  String unitId;
  List<ProductionSetItem> items;
  bool isActive;

  ProductionSetModel({
    required this.id, required this.name, required this.code, required this.unitId,
    required this.items, this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'code': code, 'unitId': unitId,
    'items': items.map((e) => e.toJson()).toList(), 'isActive': isActive,
  };

  factory ProductionSetModel.fromJson(Map<String, dynamic> json) => ProductionSetModel(
    id: json['id'], name: json['name'], code: json['code'], unitId: json['unitId'],
    items: (json['items'] as List).map((e) => ProductionSetItem.fromJson(e)).toList(),
    isActive: json['isActive'] ?? true,
  );
}

class ProductionSetItem {
  String productName;
  double quantity;
  String unit;

  ProductionSetItem({required this.productName, required this.quantity, required this.unit});

  Map<String, dynamic> toJson() => {'productName': productName, 'quantity': quantity, 'unit': unit};
  factory ProductionSetItem.fromJson(Map<String, dynamic> json) => ProductionSetItem(
    productName: json['productName'], quantity: json['quantity'].toDouble(), unit: json['unit'],
  );
}

class ProductionOrderModel {
  final String id;
  final String orderNo;
  DateTime date;
  String unitId;
  String productId;
  String recipeId;
  double plannedQty;
  double actualQty;
  String qtyUnit;
  ProductionPriority priority;
  ProductionStatus status;
  String assignedStaff;
  String startTime;
  String expectedCompletionTime;
  String actualCompletionTime;
  String notes;
  List<Map<String, dynamic>> auditTrail;
  List<Map<String, dynamic>> wasteLogs;

  ProductionOrderModel({
    required this.id, required this.orderNo, required this.date, required this.unitId,
    required this.productId, required this.recipeId, required this.plannedQty,
    this.actualQty = 0, this.qtyUnit = "Pcs", required this.priority, 
    this.status = ProductionStatus.pending,
    required this.assignedStaff, required this.startTime, 
    required this.expectedCompletionTime, this.actualCompletionTime = "",
    this.notes = "",
    required this.auditTrail,
    this.wasteLogs = const [],
  });

  double get remainingQty => plannedQty - actualQty;
  double get progress => plannedQty > 0 ? (actualQty / plannedQty).clamp(0.0, 1.5) : 0.0;

  Map<String, dynamic> toJson() => {
    'id': id, 'orderNo': orderNo, 'date': date.toIso8601String(), 'unitId': unitId,
    'productId': productId, 'recipeId': recipeId, 'plannedQty': plannedQty,
    'actualQty': actualQty, 'qtyUnit': qtyUnit, 'priority': priority.index, 
    'status': status.index, 'assignedStaff': assignedStaff, 'startTime': startTime, 
    'expectedCompletionTime': expectedCompletionTime, 'actualCompletionTime': actualCompletionTime,
    'notes': notes, 'auditTrail': auditTrail, 'wasteLogs': wasteLogs,
  };

  factory ProductionOrderModel.fromJson(Map<String, dynamic> json) => ProductionOrderModel(
    id: json['id'], orderNo: json['orderNo'], date: DateTime.parse(json['date']),
    unitId: json['unitId'], productId: json['productId'], recipeId: json['recipeId'],
    plannedQty: json['plannedQty'].toDouble(), actualQty: json['actualQty'].toDouble(),
    qtyUnit: json['qtyUnit'] ?? "Pcs",
    priority: ProductionPriority.values[json['priority'] ?? 0],
    status: ProductionStatus.values[json['status'] ?? 1], assignedStaff: json['assignedStaff'],
    startTime: json['startTime'], expectedCompletionTime: json['expectedCompletionTime'] ?? "",
    actualCompletionTime: json['actualCompletionTime'] ?? "",
    notes: json['notes'] ?? "",
    auditTrail: List<Map<String, dynamic>>.from(json['auditTrail'] ?? []),
    wasteLogs: List<Map<String, dynamic>>.from(json['wasteLogs'] ?? []),
  );
}

// --- SCREEN IMPLEMENTATION ---

class ProductionManagementScreen extends StatefulWidget {
  final String mode;
  const ProductionManagementScreen({super.key, required this.mode});

  @override
  State<ProductionManagementScreen> createState() => _ProductionManagementScreenState();
}

class _ProductionManagementScreenState extends State<ProductionManagementScreen> {
  bool _isLoading = true;
  
  final List<ProductionUnitModel> _units = [];
  final List<AssignedProductModel> _assignedProducts = [];
  final List<ProductionPlanModel> _plans = [];
  final List<ProductionBatchModel> _batches = [];
  final List<MaterialUsageModel> _usages = [];
  final List<ProductionWasteModel> _waste = [];
  final List<ProductionSetModel> _sets = [];
  final List<ProductionOrderModel> _orders = [];

  int _displayCount = 10;
  int _ordersDisplayLimit = 10;
  String _setsStatusFilter = "ALL"; // ALL, ACTIVE, INACTIVE
  String _setsUnitFilter = "ALL"; // ALL or specific unitId
  String _ordersStatusFilter = "ALL"; // ALL, INPROGRESS, COMPLETED, CANCELLED
  String _ordersHubFilter = "ALL"; // ALL or specific hub name
  String _ordersSearchQuery = "";
  DateTime? _ordersDateFilter;
  String _ordersSortBy = "Newest"; // Newest, Oldest, Priority, Quantity

  // Production Settings State
  final Map<String, dynamic> _prodSettings = {
    'autoCalcRemaining': true,
    'allowPartialProduction': true,
    'allowOverProduction': false,
    'autoCompleteTarget': true,
    'deductIngredientsOnComplete': true,
    'reserveIngredientsOnStart': false,
    'preventInsufficientStock': true,
    'enableWasteTracking': true,
    'wasteAlerts': true,
    'wasteThreshold': 10,
    'dailyPlanning': true,
    'allowFutureProduction': true,
    'allowBackdatedProduction': false,
  };

  final List<String> _masterProducts = ["Chicken Momo", "Veg Chowmein", "Mutton Thali", "Artisanal Bread", "Fruit Tart", "Sourdough", "Croissant", "Plain Tea"];
  final List<String> _masterIngredients = ["Minced Chicken", "Wheat Flour", "Refined Oil", "Seasonal Vegetables", "Basmati Rice", "Sugar", "Butter", "Yeast"];
  final List<String> _staffList = ["Chef Suresh", "Anjali Rai", "Arjun Thapa", "Priya Sharma", "Rajiv KC"];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      final unitStr = prefs.getString('prod_units_v3');
      if (unitStr != null) {
        _units.addAll((json.decode(unitStr) as List).map((e) => ProductionUnitModel.fromJson(e)));
      } else {
        _units.addAll([
          ProductionUnitModel(id: "U1", name: "Main Kitchen", code: "MK01", type: "Kitchen", manager: "Chef Suresh", dailyCapacity: 500, openingTime: "06:00 AM", closingTime: "11:00 PM", description: "Hot kitchen operations"),
          ProductionUnitModel(id: "U2", name: "Bakery", code: "BK01", type: "Bakery", manager: "Anjali Rai", dailyCapacity: 200, openingTime: "04:00 AM", closingTime: "08:00 PM", description: "Breads and pastries"),
        ]);
      }

      final prodStr = prefs.getString('prod_assigned_v3');
      if (prodStr != null) {
        _assignedProducts.addAll((json.decode(prodStr) as List).map((e) => AssignedProductModel.fromJson(e)));
      } else {
        _assignedProducts.addAll([
          AssignedProductModel(productId: "P1", name: "Chicken Momo", category: "Appetizer", standardQty: 100, prepTime: 30, priority: 3),
          AssignedProductModel(productId: "P2", name: "Croissant", category: "Bakery", standardQty: 50, prepTime: 120, priority: 2),
        ]);
      }

      final planStr = prefs.getString('prod_plans_v3');
      if (planStr != null) _plans.addAll((json.decode(planStr) as List).map((e) => ProductionPlanModel.fromJson(e)));

      final batchStr = prefs.getString('prod_batches_v3');
      if (batchStr != null) _batches.addAll((json.decode(batchStr) as List).map((e) => ProductionBatchModel.fromJson(e)));

      final usageStr = prefs.getString('prod_usage_v3');
      if (usageStr != null) _usages.addAll((json.decode(usageStr) as List).map((e) => MaterialUsageModel.fromJson(e)));

      final wasteStr = prefs.getString('prod_waste_v3');
      if (wasteStr != null) _waste.addAll((json.decode(wasteStr) as List).map((e) => ProductionWasteModel.fromJson(e)));

      final setStr = prefs.getString('prod_sets_v3');
      if (setStr != null) {
        _sets.addAll((json.decode(setStr) as List).map((e) => ProductionSetModel.fromJson(e)));
      } else {
        _sets.addAll([
          ProductionSetModel(id: "S1", name: "Momo Master Batch", code: "MM-100", unitId: "U1", items: [
             ProductionSetItem(productName: "Chicken Momo", quantity: 500, unit: "Pcs"),
             ProductionSetItem(productName: "Momo Chutney", quantity: 10, unit: "Ltr"),
          ]),
          ProductionSetModel(id: "S2", name: "Daily Bakery Run", code: "BK-01", unitId: "U2", items: [
             ProductionSetItem(productName: "Sourdough Bread", quantity: 50, unit: "Loaves"),
             ProductionSetItem(productName: "Butter Croissant", quantity: 100, unit: "Pcs"),
          ]),
        ]);
      }

      final orderStr = prefs.getString('prod_orders_v3');
      if (orderStr != null) {
        _orders.addAll((json.decode(orderStr) as List).map((e) => ProductionOrderModel.fromJson(e)));
      }

      // Load Settings
      final settingsStr = prefs.getString('prod_settings_v3');
      if (settingsStr != null) {
        final Map<String, dynamic> decoded = json.decode(settingsStr);
        decoded.forEach((key, value) {
          if (_prodSettings.containsKey(key)) _prodSettings[key] = value;
        });
      }

      _isLoading = false;
    });
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prod_units_v3', json.encode(_units.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_assigned_v3', json.encode(_assignedProducts.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_plans_v3', json.encode(_plans.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_batches_v3', json.encode(_batches.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_usage_v3', json.encode(_usages.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_waste_v3', json.encode(_waste.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_sets_v3', json.encode(_sets.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_orders_v3', json.encode(_orders.map((e) => e.toJson()).toList()));
    await prefs.setString('prod_settings_v3', json.encode(_prodSettings));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    switch (widget.mode) {
      case "Production Units": return _buildUnitsView();
      case "Production List": return _buildProductionSetsView();
      case "Add Production": return _buildAddProductionView();
      case "Production Settings": return _buildSettingsView();
      default: return _buildProductionSetsView();
    }
  }

  // --- CORE VIEW BUILDERS ---

  Widget _buildProductionSetsView() {
    int activeCount = _sets.where((s) => s.isActive).length;
    int inactiveCount = _sets.where((s) => !s.isActive).length;

    // Apply Filters
    final filteredSets = _sets.where((s) {
      bool statusMatch = _setsStatusFilter == "ALL" || 
                         (_setsStatusFilter == "ACTIVE" && s.isActive) || 
                         (_setsStatusFilter == "INACTIVE" && !s.isActive);
      bool unitMatch = _setsUnitFilter == "ALL" || s.unitId == _setsUnitFilter;
      return statusMatch && unitMatch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResponsiveHeader("Service Formula Matrix"),
              Row(
                children: [
                  _buildStatusCounter("ACTIVE", activeCount, AdminTheme.emeraldGreen, isSelected: _setsStatusFilter == "ACTIVE", onTap: () => setState(() => _setsStatusFilter = _setsStatusFilter == "ACTIVE" ? "ALL" : "ACTIVE")),
                  const SizedBox(width: 12),
                  _buildStatusCounter("INACTIVE", inactiveCount, Colors.grey, isSelected: _setsStatusFilter == "INACTIVE", onTap: () => setState(() => _setsStatusFilter = _setsStatusFilter == "INACTIVE" ? "ALL" : "INACTIVE")),
                  const SizedBox(width: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSetDialog(), 
                    icon: const Icon(Icons.add_task_rounded), label: const Text("DEFINE NEW SET")
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Hub Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("TOTAL HUB", "ALL", _setsUnitFilter == "ALL"),
                ..._units.map((u) => _buildFilterChip(u.name.toUpperCase(), u.id, _setsUnitFilter == u.id)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                  child: const Row(
                    children: [
                      SizedBox(width: 50, child: Text("SL.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 3, child: Text("SET NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 2, child: Text("RESPONSIBLE HUB", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 4, child: Text("FORMULA ITEMS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                      Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                      SizedBox(width: 100, child: Center(child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    ],
                  ),
                ),
                if (filteredSets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(64), 
                    child: Center(child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text("No formulas found for this selection.", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        TextButton(onPressed: () => setState(() { _setsStatusFilter = "ALL"; _setsUnitFilter = "ALL"; }), child: const Text("Clear Filters"))
                      ],
                    ))
                  )
                else
                  ListView.separated(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredSets.length,
                    separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (ctx, i) {
                      final s = filteredSets[i];
                      final unit = _units.firstWhere((u) => u.id == s.unitId, orElse: () => _units[0]);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                          children: [
                            SizedBox(width: 50, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                            Expanded(flex: 3, child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AdminTheme.darkNavy))),
                            Expanded(flex: 2, child: Text(unit.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            Expanded(flex: 4, child: Wrap(
                              spacing: 8, runSpacing: 4,
                              children: s.items.map((item) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                child: Text("${item.productName} (${item.quantity.toInt()})", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              )).toList(),
                            )),
                            Expanded(flex: 2, child: Center(child: Switch.adaptive(
                              value: s.isActive, 
                              activeThumbColor: AdminTheme.emeraldGreen,
                              onChanged: (v) { setState(() => s.isActive = v); _saveAllData(); }
                            ))),
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 22), onPressed: () => _showAddSetDialog(existing: s)),
                                  IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), onPressed: () {
                                     setState(() => _sets.remove(s));
                                     _saveAllData();
                                  }),
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
      ),
    );
  }

  Widget _buildAddProductionView() {
    int totalCount = _orders.length;
    
    // Map status to counts
    Map<ProductionStatus, int> statusCounts = {};
    for (var status in ProductionStatus.values) {
      statusCounts[status] = _orders.where((o) => o.status == status).length;
    }

    // Apply Filters
    List<ProductionOrderModel> filteredOrders = _orders.where((o) {
      // Status Filter
      bool statusMatch = true;
      if (_ordersStatusFilter != "ALL") {
        statusMatch = o.status.name.toUpperCase() == _ordersStatusFilter;
      }

      // Hub Filter
      final unit = _units.firstWhere((u) => u.id == o.unitId, orElse: () => _units[0]);
      bool hubMatch = _ordersHubFilter == "ALL" || unit.name == _ordersHubFilter;

      // Date Filter
      bool dateMatch = _ordersDateFilter == null || DateUtils.isSameDay(o.date, _ordersDateFilter!);

      // Search Filter
      bool searchMatch = _ordersSearchQuery.isEmpty || 
                         o.productId.toLowerCase().contains(_ordersSearchQuery.toLowerCase()) ||
                         o.assignedStaff.toLowerCase().contains(_ordersSearchQuery.toLowerCase()) ||
                         o.orderNo.toLowerCase().contains(_ordersSearchQuery.toLowerCase());

      return statusMatch && hubMatch && searchMatch && dateMatch;
    }).toList();

    // Apply Sorting
    if (_ordersSortBy == "Newest") {
      filteredOrders.sort((a, b) => b.date.compareTo(a.date));
    } else if (_ordersSortBy == "Oldest") {
      filteredOrders.sort((a, b) => a.date.compareTo(b.date));
    } else if (_ordersSortBy == "Priority") {
      filteredOrders.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    } else if (_ordersSortBy == "Quantity") {
      filteredOrders.sort((a, b) => b.plannedQty.compareTo(a.plannedQty));
    }

    final limitedOrders = filteredOrders.take(_ordersDisplayLimit).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResponsiveHeader("Production Execution Matrix"),
              ElevatedButton.icon(
                onPressed: () => _showDispatchRunDialog(), 
                icon: const Icon(Icons.add_circle_outline_rounded), 
                label: const Text("ADD NEW PRODUCTION"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.royalBlue, 
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // --- SUMMARY CARDS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard("TOTAL", totalCount, Icons.inventory_2_outlined, AdminTheme.royalBlue, isSelected: _ordersStatusFilter == "ALL", onTap: () => setState(() => _ordersStatusFilter = "ALL")),
                const SizedBox(width: 16),
                ...ProductionStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildSummaryCard(
                      status.name.toUpperCase(), 
                      statusCounts[status] ?? 0, 
                      _getStatusIcon(status),
                      _getStatusColor(status.name), 
                      isSelected: _ordersStatusFilter == status.name.toUpperCase(), 
                      onTap: () => setState(() => _ordersStatusFilter = _ordersStatusFilter == status.name.toUpperCase() ? "ALL" : status.name.toUpperCase())
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- HUB FILTERS & DATE ---
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("ALL UNITS", "ALL", _ordersHubFilter == "ALL", (v) => setState(() => _ordersHubFilter = "ALL")),
                      ..._units.map((u) => _buildFilterChip(u.name.toUpperCase(), u.name, _ordersHubFilter == u.name, (v) => setState(() => _ordersHubFilter = u.name))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _ordersDateFilter ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setState(() => _ordersDateFilter = d);
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(_ordersDateFilter == null ? "FILTER BY DATE" : DateFormat('dd MMM yyyy').format(_ordersDateFilter!)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.royalBlue,
                  side: BorderSide(color: _ordersDateFilter == null ? Colors.grey.shade300 : AdminTheme.royalBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_ordersDateFilter != null) IconButton(onPressed: () => setState(() => _ordersDateFilter = null), icon: const Icon(Icons.clear, size: 18, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 32),
          
          // --- SEARCH & SORT ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader("Add Production List"),
              Row(
                children: [
                  Container(
                    width: 300, height: 45,
                    margin: const EdgeInsets.only(right: 16),
                    child: TextField(
                      onChanged: (v) => setState(() => _ordersSearchQuery = v),
                      decoration: InputDecoration(
                        hintText: "Search Production ID, Product, Leader...",
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.royalBlue)),
                        fillColor: Colors.white, filled: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _ordersSortBy,
                    underline: const SizedBox(),
                    items: ["Newest", "Oldest", "Priority", "Quantity"].map((s) => DropdownMenuItem(value: s, child: Text("Sort: $s", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) => setState(() => _ordersSortBy = v!),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _ordersDisplayLimit,
                    underline: const SizedBox(),
                    items: [5, 10, 20, 50, 100].map((int val) => DropdownMenuItem<int>(
                      value: val,
                      child: Text("Display $val", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )).toList(),
                    onChanged: (v) => setState(() => _ordersDisplayLimit = v!),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLiveOrdersTable(limitedOrders),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, IconData icon, Color color, {required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AdminTheme.softShadow,
          border: Border.all(color: isSelected ? color : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text("$count", style: TextStyle(color: isSelected ? Colors.white : AdminTheme.darkNavy, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ProductionStatus s) {
    switch (s) {
      case ProductionStatus.planned: return Icons.event_note_rounded;
      case ProductionStatus.pending: return Icons.hourglass_empty_rounded;
      case ProductionStatus.inProgress: return Icons.play_circle_outline_rounded;
      case ProductionStatus.partiallyCompleted: return Icons.incomplete_circle_rounded;
      case ProductionStatus.completed: return Icons.check_circle_outline_rounded;
      case ProductionStatus.cancelled: return Icons.cancel_outlined;
    }
  }

  Widget _buildLiveOrdersTable(List<ProductionOrderModel> list) {
    bool isMobile = MediaQuery.of(context).size.width < 900;
    
    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (ctx, i) => _buildMobileOrderCard(list[i], i),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: isMobile ? 900 : 1200, // Ensure a minimum width for the table
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                child: const Row(
                  children: [
                    SizedBox(width: 40, child: Text("SL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("PROD ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("DATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 3, child: Text("LEADER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 3, child: Text("PRODUCT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 2, child: Text("UNIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
                    Expanded(flex: 3, child: Center(child: Text("QTY (P/A/R)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    Expanded(flex: 2, child: Center(child: Text("PROGRESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    Expanded(flex: 3, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                    SizedBox(width: 180, child: Center(child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)))),
                  ],
                ),
              ),
              if (list.isEmpty)
                _buildEmptyState("No production records found.")
              else
                ListView.separated(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (ctx, i) {
                    final o = list[i];
                    final unit = _units.firstWhere((u) => u.id == o.unitId, orElse: () => _units[0]);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                          Expanded(flex: 2, child: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.royalBlue, fontSize: 12))),
                          Expanded(flex: 2, child: Text(DateFormat('dd MMM yy').format(o.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Row(children: [const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 14, color: Colors.white)), const SizedBox(width: 8), Expanded(child: Text(o.assignedStaff, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy, fontSize: 12)))] )),
                          Expanded(flex: 3, child: Text(o.productId, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.darkNavy, fontSize: 13))),
                          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)), child: Text(unit.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)))),
                          Expanded(flex: 3, child: Center(child: Column(children: [Text("${o.plannedQty.toInt()} / ${o.actualQty.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text("Rem: ${o.remainingQty.toInt()}", style: TextStyle(color: o.remainingQty > 0 ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold))]))),
                          Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("${(o.progress * 100).toInt()}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 4), SizedBox(width: 60, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: o.progress, minHeight: 4, backgroundColor: Colors.grey[100], color: _getPriorityColor(o.priority))))])),
                          Expanded(flex: 3, child: Center(child: InkWell(onTap: () => _showStatusChangeDialog(o), borderRadius: BorderRadius.circular(8), child: _buildStatusBadge(o.status.name)))),
                          SizedBox(
                            width: 180,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildActionBtn(Icons.visibility_outlined, "View", Colors.blue, () => _showProductionDetailsDialog(o)),
                                _buildActionBtn(Icons.update_rounded, "Update", Colors.orange, () => _showUpdateExecutionDialog(o)),
                                _buildActionBtn(Icons.edit_note_rounded, "Edit", Colors.teal, () => _showEditRunDialog(o)),
                                _buildActionBtn(Icons.delete_outline_rounded, "Delete", Colors.red, () => _showDeleteOrderConfirm(o)),
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
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(icon: Icon(icon, color: color, size: 20), onPressed: onTap),
    );
  }

  Widget _buildMobileOrderCard(ProductionOrderModel o, int index) {
    final unit = _units.firstWhere((u) => u.id == o.unitId, orElse: () => _units[0]);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AdminTheme.softShadow),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)),
              _buildStatusBadge(o.status.name),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("ITEM", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text(o.productId, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("LEADER", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text(o.assignedStaff, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("UNIT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text(unit.name, style: const TextStyle(fontWeight: FontWeight.bold))])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("QTY (P/A/R)", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text("${o.plannedQty.toInt()} / ${o.actualQty.toInt()} / ${o.remainingQty.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold))])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: o.progress, minHeight: 8, backgroundColor: Colors.grey[100], color: AdminTheme.royalBlue))),
              const SizedBox(width: 16),
              Text("${(o.progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(onPressed: () => _showProductionDetailsDialog(o), icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text("VIEW")),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: () => _showUpdateExecutionDialog(o), icon: const Icon(Icons.update, size: 18), label: const Text("UPDATE")),
            ],
          )
        ],
      ),
    );
  }

  Color _getPriorityColor(ProductionPriority p) {
    switch (p) {
      case ProductionPriority.low: return Colors.blue;
      case ProductionPriority.normal: return AdminTheme.royalBlue;
      case ProductionPriority.high: return Colors.orange;
      case ProductionPriority.urgent: return Colors.red;
    }
  }

  Widget _buildSettingsView() {
    double width = MediaQuery.of(context).size.width;
    double cardWidth = width > 1200 ? (width - 100) / 2 : (width - 48);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResponsiveHeader("Production System Configuration"),
          const Text("Tailor your kitchen production logic, inventory sync, and scheduling rules.", 
            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // 1. Production Workflow
              SizedBox(
                width: cardWidth,
                child: _buildSettingCard("Production Workflow", Icons.settings_suggest_outlined, [
                  _buildToggleOption(
                    "Auto-calculate Remaining Quantity", 
                    "Automatically adjust pending quantities based on yield logs.",
                    _prodSettings['autoCalcRemaining'], 
                    (v) => _updateSetting('autoCalcRemaining', v)
                  ),
                  _buildToggleOption(
                    "Allow Partial Production", 
                    "Permit logging quantities less than the planned target.",
                    _prodSettings['allowPartialProduction'], 
                    (v) => _updateSetting('allowPartialProduction', v)
                  ),
                  _buildToggleOption(
                    "Allow Over-production", 
                    "Permit recording yields higher than the planned target.",
                    _prodSettings['allowOverProduction'], 
                    (v) => _updateSetting('allowOverProduction', v)
                  ),
                  _buildToggleOption(
                    "Auto-complete Target Reached", 
                    "Automatically mark run as completed once target is achieved.",
                    _prodSettings['autoCompleteTarget'], 
                    (v) => _updateSetting('autoCompleteTarget', v)
                  ),
                ]),
              ),

              // 2. Inventory & Material
              SizedBox(
                width: cardWidth,
                child: _buildSettingCard("Inventory & Material", Icons.inventory_2_outlined, [
                  _buildToggleOption(
                    "Deduct Ingredients on Completion", 
                    "Instantly reduce stock levels when a batch is finalized.",
                    _prodSettings['deductIngredientsOnComplete'], 
                    (v) => _updateSetting('deductIngredientsOnComplete', v)
                  ),
                  _buildToggleOption(
                    "Reserve Ingredients on Start", 
                    "Hold raw materials in stock as 'Reserved' when a run begins.",
                    _prodSettings['reserveIngredientsOnStart'], 
                    (v) => _updateSetting('reserveIngredientsOnStart', v)
                  ),
                  _buildToggleOption(
                    "Prevent Insufficient Stock", 
                    "Block starting a production run if ingredients are missing.",
                    _prodSettings['preventInsufficientStock'], 
                    (v) => _updateSetting('preventInsufficientStock', v)
                  ),
                ]),
              ),

              // 3. Waste Management
              SizedBox(
                width: cardWidth,
                child: _buildSettingCard("Waste Management", Icons.delete_sweep_outlined, [
                  _buildToggleOption(
                    "Enable Waste Tracking", 
                    "Show waste logging options in the production hub.",
                    _prodSettings['enableWasteTracking'], 
                    (v) => _updateSetting('enableWasteTracking', v)
                  ),
                  _buildToggleOption(
                    "Waste Alerts", 
                    "Notify management if wastage exceeds the defined threshold.",
                    _prodSettings['wasteAlerts'], 
                    (v) => _updateSetting('wasteAlerts', v)
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Waste Alert Threshold", style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy, fontSize: 14)),
                            Text("Trigger alert if waste exceeds this % of planned qty.", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AdminTheme.royalBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<int>(
                            value: _prodSettings['wasteThreshold'],
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: AdminTheme.royalBlue),
                            items: [5, 10, 15, 20, 25].map((int val) => DropdownMenuItem(value: val, child: Text("$val%", style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.royalBlue)))).toList(),
                            onChanged: (v) => _updateSetting('wasteThreshold', v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              // 4. Production Schedule
              SizedBox(
                width: cardWidth,
                child: _buildSettingCard("Production Schedule", Icons.calendar_month_outlined, [
                  _buildToggleOption(
                    "Daily Production Planning", 
                    "Enable the planning module for daily hub targets.",
                    _prodSettings['dailyPlanning'], 
                    (v) => _updateSetting('dailyPlanning', v)
                  ),
                  _buildToggleOption(
                    "Allow Future Production", 
                    "Permit planning for future dates ahead of time.",
                    _prodSettings['allowFutureProduction'], 
                    (v) => _updateSetting('allowFutureProduction', v)
                  ),
                  _buildToggleOption(
                    "Allow Backdated Production", 
                    "Permit logging production runs for past dates.",
                    _prodSettings['allowBackdatedProduction'], 
                    (v) => _updateSetting('allowBackdatedProduction', v)
                  ),
                ]),
              ),
            ],
          ),
          
          const SizedBox(height: 64),
          const Center(
            child: Opacity(
              opacity: 0.5,
              child: Text("CORE PRODUCTION ENGINE v4.0 • HIGH AVAILABILITY", 
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  void _updateSetting(String key, dynamic value) {
    setState(() => _prodSettings[key] = value);
    _saveAllData();
  }

  Widget _buildUnitsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResponsiveHeader("Production Hubs Matrix"),
              ElevatedButton.icon(
                onPressed: () => _showAddUnitDialog(), 
                icon: const Icon(Icons.add), label: const Text("ADD NEW HUB")
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 3 : (MediaQuery.of(context).size.width > 700 ? 2 : 1),
              crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 1.4
            ),
            itemCount: _units.length,
            itemBuilder: (context, index) {
              final u = _units[index];
              final todayPlans = _orders.where((p) => p.unitId == u.id && DateUtils.isSameDay(p.date, DateTime.now())).toList();
              double totalPlanned = todayPlans.fold(0, (sum, item) => sum + item.plannedQty);
              double totalProduced = todayPlans.fold(0, (sum, item) => sum + item.actualQty);
              double progress = totalPlanned > 0 ? (totalProduced / totalPlanned) : 0.0;

              return InkWell(
                onTap: () => _showUnitDetailDialog(u),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: AdminTheme.softShadow),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.factory_outlined, color: AdminTheme.royalBlue)),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AdminTheme.darkNavy)), Text("Lead: ${u.manager}", style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))])),
                          Switch.adaptive(value: u.isActive, activeThumbColor: AdminTheme.emeraldGreen, onChanged: (v) { setState(() => u.isActive = v); _saveAllData(); }),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMinorStat("CAPACITY", "${u.dailyCapacity} ${u.capacityUnit}"),
                          _buildMinorStat("PROGRESS", "${(progress * 100).toInt()}%"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey[100], color: AdminTheme.royalBlue)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUnitDetailDialog(ProductionUnitModel unit) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(32),
            child: DefaultTabController(
            length: 7,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.factory_outlined, color: AdminTheme.royalBlue),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(unit.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                        Text("Unit Matrix Console • Active Node", style: TextStyle(color: AdminTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                const TabBar(
                  isScrollable: true,
                  labelColor: AdminTheme.royalBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AdminTheme.royalBlue,
                  tabs: [
                    Tab(text: "Overview"),
                    Tab(text: "Products"),
                    Tab(text: "Plans"),
                    Tab(text: "Batches"),
                    Tab(text: "Usage"),
                    Tab(text: "Waste"),
                    Tab(text: "History"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUnitOverview(unit, setModalState),
                      _buildUnitProducts(unit, setModalState),
                      _buildUnitPlan(unit, setModalState),
                      _buildUnitBatches(unit, setModalState),
                      _buildUnitUsage(unit, setModalState),
                      _buildUnitWaste(unit, setModalState),
                      _buildUnitHistory(unit),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitOverview(ProductionUnitModel u, StateSetter setModalState) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Core Node Parameters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddUnitDialog(existing: u),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text("EDIT CONFIG"),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoRow("Manager", u.manager),
        _buildInfoRow("Location", u.location),
        _buildInfoRow("Working Hours", "${u.openingTime} - ${u.closingTime}"),
        _buildInfoRow("Daily Capacity", "${u.dailyCapacity} ${u.capacityUnit}"),
        _buildInfoRow("Working Days", u.workingDays.join(", ")),
        const Divider(height: 48),
        const Text("System Description", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text(u.description, style: const TextStyle(color: Colors.blueGrey, height: 1.6)),
      ],
    );
  }

  Widget _buildUnitProducts(ProductionUnitModel u, StateSetter setModalState) {
    final unitProducts = _assignedProducts; // Simplified for demo
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Serviceable Product Matrix", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                DropdownButton<int>(
                  value: _displayCount == -1 ? 10 : _displayCount, // Visual fallback
                  underline: const SizedBox(),
                  items: [5, 10, 20, 50].map((int val) => DropdownMenuItem<int>(
                    value: val,
                    child: Text("Display $val", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )).toList(),
                  onChanged: (v) => setState(() => _displayCount = v!),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAssignProductDialog(u, setModalState), 
                  icon: const Icon(Icons.add, size: 16), label: const Text("ASSIGN")
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: unitProducts.length,
            itemBuilder: (ctx, i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: AdminTheme.royalBlue, size: 20),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unitProducts[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(unitProducts[i].category, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  )),
                  _buildMinorStat("PREP", "${unitProducts[i].prepTime}m"),
                  const SizedBox(width: 12),
                  IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 20), onPressed: () => _showEditAssignedProductDialog(unitProducts[i], setModalState)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () {
                    setState(() => _assignedProducts.removeAt(i));
                    setModalState(() {});
                    _saveAllData();
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditAssignedProductDialog(AssignedProductModel product, StateSetter setModalState) {
    final qtyCtrl = TextEditingController(text: product.standardQty.toInt().toString());
    final timeCtrl = TextEditingController(text: product.prepTime.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit ${product.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Standard Production Qty"), keyboardType: TextInputType.number),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "Est. Prep Time (Mins)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            setState(() {
              product.standardQty = double.tryParse(qtyCtrl.text) ?? product.standardQty;
              product.prepTime = int.tryParse(timeCtrl.text) ?? product.prepTime;
            });
            setModalState(() {});
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("SAVE CHANGES")),
        ],
      ),
    );
  }

  Widget _buildUnitPlan(ProductionUnitModel u, StateSetter setModalState) {
    final plans = _plans.where((p) => p.unitId == u.id).toList();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Execution Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showAddPlanDialog(u, setModalState), 
              icon: const Icon(Icons.event_note_rounded, size: 16), label: const Text("NEW PLAN ENTRY")
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: plans.isEmpty ? _buildEmptyTabState("No production planned for this hub.") : ListView.builder(
            itemCount: plans.length,
            itemBuilder: (ctx, i) {
              final p = plans[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatusBadge(p.status.name),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p.productId, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                        Text("${p.producedQty.toInt()} / ${p.plannedQty.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMinorStat("REMAINING", "${p.remainingQty.toInt()} Units"),
                        _buildMinorStat("LEAD", p.staff),
                        _buildMinorStat("TIME", "${p.startTime} - ${p.endTime}"),
                        IconButton(
                          icon: const Icon(Icons.add_task_rounded, color: AdminTheme.royalBlue), 
                          onPressed: () => _showUpdateProducedDialog(p, setModalState)
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnitBatches(ProductionUnitModel u, StateSetter setModalState) {
    final batches = _batches.where((b) => b.unitId == u.id).toList();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Batch Control Ledger", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showRecordBatchDialog(u, setModalState), 
              icon: const Icon(Icons.layers_outlined, size: 16), label: const Text("RECORD BATCH")
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: batches.isEmpty ? _buildEmptyTabState("No batch records found.") : ListView.builder(
            itemCount: batches.length,
            itemBuilder: (ctx, i) {
              final b = batches[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.layers_outlined, size: 16, color: AdminTheme.royalBlue)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${b.productId} • Batch #${b.id.substring(0,4)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Produced by ${b.staff} at ${b.startTime}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text("${b.actualQty.toInt()} Units", style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.royalBlue)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnitUsage(ProductionUnitModel u, StateSetter setModalState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Ingredient Consumption", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showRecordUsageDialog(u, setModalState), 
              icon: const Icon(Icons.inventory_2_outlined, size: 16), label: const Text("LOG USAGE")
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _usages.isEmpty ? _buildEmptyTabState("No material usage logs yet.") : ListView.builder(
            itemCount: _usages.length,
            itemBuilder: (ctx, i) {
               final item = _usages[i];
               return ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: const Icon(Icons.science_outlined, size: 16)),
                title: Text(item.ingredient, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Planned: ${item.plannedQty} • Actual: ${item.actualQty} ${item.unit}"),
                trailing: Text("${((item.actualQty / item.plannedQty) * 100).toInt()}% Used", style: TextStyle(color: item.actualQty > item.plannedQty ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnitWaste(ProductionUnitModel u, StateSetter setModalState) {
    final unitWaste = _waste.where((w) => w.unitId == u.id).toList();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Loss & Wastage Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showUnitWasteDialog(u, setModalState), 
              icon: const Icon(Icons.delete_sweep_outlined, size: 16), label: const Text("RECORD WASTE")
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: unitWaste.isEmpty ? _buildEmptyTabState("Zero waste recorded. Excellent!") : ListView.builder(
            itemCount: unitWaste.length,
            itemBuilder: (ctx, i) => ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text("${unitWaste[i].quantity} ${unitWaste[i].unit} - ${unitWaste[i].productId}"),
              subtitle: Text("Reason: ${unitWaste[i].reason.name}"),
              trailing: Text(DateFormat('dd MMM').format(unitWaste[i].date)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitHistory(ProductionUnitModel u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Audit Trail & Node History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: [
              _buildHistoryItem("10:30 AM", "Batch BCH-42 completed for Chicken Momo (100 Pcs)"),
              _buildHistoryItem("09:15 AM", "Material Issue: 5kg Minced Chicken released to hub"),
              _buildHistoryItem("08:00 AM", "Production Node active - Lead: ${u.manager}"),
            ],
          ),
        ),
      ],
    );
  }

  void _showProductionDetailsDialog(ProductionOrderModel o) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.productId, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                      Text("Production ID: ${o.orderNo} • ${DateFormat('dd MMM yyyy').format(o.date)}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildStatusBadge(o.status.name),
                      const SizedBox(width: 16),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // --- TOP STATS ---
                      Row(
                        children: [
                          _buildDetailStatCard("Planned", "${o.plannedQty.toInt()}", AdminTheme.royalBlue),
                          _buildDetailStatCard("Produced", "${o.actualQty.toInt()}", AdminTheme.emeraldGreen),
                          _buildDetailStatCard("Remaining", "${o.remainingQty.toInt()}", Colors.orange),
                          _buildDetailStatCard("Progress", "${(o.progress * 100).toInt()}%", Colors.teal),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- LEFT COLUMN ---
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildDetailSection("Overview Details", [
                                  _buildDetailRow("Production Unit", _units.firstWhere((u)=>u.id==o.unitId, orElse:()=>_units[0]).name),
                                  _buildDetailRow("Production Leader", o.assignedStaff),
                                  _buildDetailRow("Priority Level", o.priority.name.toUpperCase()),
                                  _buildDetailRow("Expected Start", o.startTime),
                                  _buildDetailRow("Expected Completion", o.expectedCompletionTime),
                                  _buildDetailRow("Actual Completion", o.actualCompletionTime.isEmpty ? "--" : o.actualCompletionTime),
                                ]),
                                const SizedBox(height: 24),
                                _buildDetailSection("Production Notes", [
                                  Text(o.notes.isEmpty ? "No notes recorded for this run." : o.notes, style: const TextStyle(color: Colors.blueGrey, height: 1.5)),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // --- RIGHT COLUMN ---
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildDetailSection("Audit History", [
                                  ...o.auditTrail.map((log) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Text(log['time'] ?? "", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(log['action'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  )),
                                ]),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showOrderWasteDialog(o), 
                                  icon: const Icon(Icons.delete_sweep_rounded),
                                  label: const Text("RECORD WASTE"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, minimumSize: const Size(double.infinity, 50)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStatCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100), boxShadow: AdminTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy, fontSize: 13)),
        ],
      ),
    );
  }

  void _showUpdateExecutionDialog(ProductionOrderModel o) {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Log Production: ${o.productId}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Planned: ${o.plannedQty.toInt()} • Current: ${o.actualQty.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "New Produced Quantity"), keyboardType: TextInputType.number, autofocus: true),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Batch Notes (Optional)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              double added = double.tryParse(qtyCtrl.text) ?? 0;
              setState(() {
                o.actualQty += added;
                // Status Logic
                if (o.actualQty >= o.plannedQty) {
                  o.status = ProductionStatus.completed;
                  o.actualCompletionTime = DateFormat('hh:mm a').format(DateTime.now());
                } else if (o.actualQty > 0) {
                  o.status = ProductionStatus.inProgress;
                }
                o.auditTrail.add({
                  "action": "Produced $added ${o.qtyUnit}",
                  "time": DateFormat('hh:mm a').format(DateTime.now()),
                  "user": "Staff"
                });
              });
              _saveAllData();
              Navigator.pop(ctx);
              _showFeedback("Success", "Logged $added units for ${o.productId}");
            },
            child: const Text("RECORD YIELD"),
          ),
        ],
      ),
    );
  }

  void _showOrderWasteDialog(ProductionOrderModel o) {
    final qtyCtrl = TextEditingController();
    WasteReason selectedReason = WasteReason.spoilage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => AlertDialog(
          title: const Text("Record Production Waste"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Waste Quantity"), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              DropdownButtonFormField<WasteReason>(
                initialValue: selectedReason,
                items: WasteReason.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                onChanged: (v) => setMState(() => selectedReason = v!),
                decoration: const InputDecoration(labelText: "Reason for Waste"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                double waste = double.tryParse(qtyCtrl.text) ?? 0;
                setState(() {
                  o.wasteLogs.add({
                    "date": DateTime.now().toIso8601String(),
                    "qty": waste,
                    "reason": selectedReason.name,
                  });
                  o.auditTrail.add({
                    "action": "Recorded Waste: $waste (${selectedReason.name})",
                    "time": DateFormat('hh:mm a').format(DateTime.now()),
                    "user": "Staff"
                  });
                });
                _saveAllData();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("SAVE WASTE LOG"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteOrderConfirm(ProductionOrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete the production record for ${order.productId} (Batch: ${order.orderNo})? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("KEEP RECORD")),
          ElevatedButton(
            onPressed: () {
              setState(() => _orders.remove(order));
              _saveAllData();
              Navigator.pop(ctx);
              _showFeedback("Deleted", "Production record has been removed.");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE PERMANENTLY"),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(ProductionOrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Production Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ProductionStatus.values.map((s) => ListTile(
            title: Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            leading: Icon(Icons.circle, color: _getStatusColor(s.name), size: 12),
            trailing: order.status == s ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => order.status = s);
              _saveAllData();
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == "InProgress") return Colors.orange;
    if (status == "Completed") return AdminTheme.emeraldGreen;
    if (status == "Planned") return Colors.blueGrey;
    if (status == "Cancelled") return Colors.red;
    return AdminTheme.royalBlue;
  }

  void _showEditRunDialog(ProductionOrderModel order) {
    final hubCtrl = TextEditingController(text: _units.firstWhere((u)=>u.id == order.unitId, orElse: ()=>_units[0]).name);
    final productCtrl = TextEditingController(text: order.productId);
    final planQtyCtrl = TextEditingController(text: order.plannedQty.toInt().toString());
    final actualQtyCtrl = TextEditingController(text: order.actualQty.toInt().toString());
    final staffCtrl = TextEditingController(text: order.assignedStaff);
    ProductionStatus currentStatus = order.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => AlertDialog(
          title: const Text("Update Production Record"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypableAutocomplete(controller: hubCtrl, label: "Production Hub", suggestions: _units.map((u)=>u.name).toList()),
                _TypableAutocomplete(controller: productCtrl, label: "Menu Item / Product", suggestions: _masterProducts),
                TextField(controller: planQtyCtrl, decoration: const InputDecoration(labelText: "Planned Quantity"), keyboardType: TextInputType.number),
                TextField(controller: actualQtyCtrl, decoration: const InputDecoration(labelText: "Actual Produced Quantity"), keyboardType: TextInputType.number),
                _TypableAutocomplete(controller: staffCtrl, label: "Responsible Staff", suggestions: _staffList),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProductionStatus>(
                  initialValue: currentStatus,
                  items: ProductionStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (v) => setMState(() => currentStatus = v!),
                  decoration: const InputDecoration(labelText: "Manual Status Override"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(onPressed: () {
               setState(() {
                 int index = _orders.indexOf(order);
                 if (index != -1) {
                   String hubId = _units.firstWhere((u)=>u.name == hubCtrl.text, orElse: ()=>_units[0]).id;
                   _orders[index] = ProductionOrderModel(
                     id: order.id, orderNo: order.orderNo, date: order.date,
                     unitId: hubId, productId: productCtrl.text, recipeId: order.recipeId,
                     plannedQty: double.tryParse(planQtyCtrl.text) ?? order.plannedQty,
                     actualQty: double.tryParse(actualQtyCtrl.text) ?? order.actualQty,
                     priority: order.priority, status: currentStatus,
                     assignedStaff: staffCtrl.text, startTime: order.startTime,
                     expectedCompletionTime: order.expectedCompletionTime, auditTrail: order.auditTrail,
                   );
                   // Auto-recalculate if status wasn't manually set to something specific like Cancelled
                   if (currentStatus != ProductionStatus.cancelled) {
                     if (_orders[index].actualQty >= _orders[index].plannedQty) {
                       _orders[index].status = ProductionStatus.completed;
                     } else if (_orders[index].actualQty > 0) {
                       _orders[index].status = ProductionStatus.inProgress;
                     }
                   }
                 }
               });
               _saveAllData();
               Navigator.pop(ctx);
            }, child: const Text("UPDATE DATA")),
          ],
        ),
      ),
    );
  }

  void _showDispatchRunDialog() {
    final hubCtrl = TextEditingController(text: _units.isNotEmpty ? _units[0].name : "");
    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "100");
    final staffCtrl = TextEditingController(text: _staffList.isNotEmpty ? _staffList[0] : "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_shopping_cart_rounded, color: AdminTheme.royalBlue, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Add Production List", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Enter details to dispatch a new kitchen batch.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 24),
              _TypableAutocomplete(controller: hubCtrl, label: "Target Kitchen / Hub", suggestions: _units.map((u) => u.name).toList()),
              _TypableAutocomplete(controller: productCtrl, label: "Item Name", suggestions: _masterProducts),
              Row(
                children: [
                  Expanded(child: TextField(
                    controller: qtyCtrl, 
                    decoration: const InputDecoration(labelText: "Goal Quantity", prefixIcon: Icon(Icons.numbers, size: 18)), 
                    keyboardType: TextInputType.number
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _TypableAutocomplete(controller: staffCtrl, label: "Assign Lead", suggestions: _staffList)),
                ],
              ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.1))),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text("Status will be set to 'IN PROGRESS' automatically.", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
               if (productCtrl.text.isEmpty || hubCtrl.text.isEmpty) {
                 _showFeedback("Error", "Product and Hub are required.");
                 return;
               }

               // Business Logic: Auto-add new product/staff to master list for future suggestions
               if (!_masterProducts.contains(productCtrl.text)) {
                 _masterProducts.add(productCtrl.text);
               }
               if (!_staffList.contains(staffCtrl.text)) {
                 _staffList.add(staffCtrl.text);
               }

               String hubId = _units.firstWhere(
                 (u) => u.name == hubCtrl.text, 
                 orElse: () => _units.isNotEmpty ? _units[0] : ProductionUnitModel(id: "U1", name: "", code: "", type: "", manager: "", dailyCapacity: 0, openingTime: "", closingTime: "", description: ""),
               ).id;

               setState(() {
                 _orders.insert(0, ProductionOrderModel(
                   id: "ORD-${DateTime.now().millisecondsSinceEpoch}",
                   orderNo: "BCH-${DateFormat('Hm').format(DateTime.now())}-${_orders.length + 1}",
                   date: DateTime.now(),
                   unitId: hubId,
                   productId: productCtrl.text,
                   recipeId: "DEFAULT",
                   plannedQty: double.tryParse(qtyCtrl.text) ?? 100,
                   actualQty: 0,
                   priority: ProductionPriority.normal,
                   status: ProductionStatus.inProgress,
                   assignedStaff: staffCtrl.text,
                   startTime: DateFormat('hh:mm a').format(DateTime.now()),
                   expectedCompletionTime: DateFormat('hh:mm a').format(DateTime.now().add(const Duration(hours: 2))),
                   auditTrail: [{"action": "Dispatched", "time": DateFormat('hh:mm a').format(DateTime.now()), "user": "Admin"}],
                 ));
               });

               _saveAllData();
               Navigator.pop(ctx);
               _showFeedback("Success", "Production run launched for ${productCtrl.text}");
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.royalBlue),
            child: const Text("LAUNCH BATCH"),
          ),
        ],
      ),
    );
  }


  void _showAddSetDialog({ProductionSetModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? "");
    String hubId = existing?.unitId ?? (_units.isNotEmpty ? _units[0].id : "");
    
    // Manage items and their controllers
    List<ProductionSetItem> tempItems = existing != null 
        ? List.from(existing.items.map((e) => ProductionSetItem(productName: e.productName, quantity: e.quantity, unit: e.unit)))
        : [];
    
    List<TextEditingController> itemControllers = tempItems.map((e) => TextEditingController(text: e.productName)).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(existing == null ? "Define Production Set" : "Update Set Formula"),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Set Name (e.g. Daily Lunch Prep)")),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: hubId,
                    items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                    onChanged: (v) => setModalState(() => hubId = v!),
                    decoration: const InputDecoration(labelText: "Responsible Hub"),
                  ),
                  const SizedBox(height: 32),
                  const Text("FORMULA ITEMS (Yield per Set)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
                  const Divider(),
                  ...tempItems.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _TypableAutocomplete(
                              controller: itemControllers[idx], 
                              label: "Item Name", 
                              suggestions: _masterProducts,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.quantity.toInt().toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: "Qty", isDense: true),
                              onChanged: (v) => item.quantity = double.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            onPressed: () => setModalState(() {
                               tempItems.removeAt(idx);
                               itemControllers[idx].dispose();
                               itemControllers.removeAt(idx);
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setModalState(() {
                      tempItems.add(ProductionSetItem(productName: _masterProducts[0], quantity: 10, unit: "Pcs"));
                      itemControllers.add(TextEditingController(text: _masterProducts[0]));
                    }),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("ADD ITEM TO MENU"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () {
               for (var c in itemControllers) { c.dispose(); }
               Navigator.pop(ctx);
            }, child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                 if (nameCtrl.text.isEmpty) return;
                 
                 // Update product names from controllers before saving
                 for(int i=0; i<tempItems.length; i++) {
                   tempItems[i].productName = itemControllers[i].text;
                 }

                 setState(() {
                   if (existing == null) {
                     _sets.add(ProductionSetModel(
                       id: "S${_sets.length+1}", 
                       name: nameCtrl.text, 
                       code: "F-${100 + _sets.length}", // Auto-generated code
                       unitId: hubId, 
                       items: tempItems
                     ));
                   } else {
                     existing.name = nameCtrl.text;
                     existing.unitId = hubId;
                     existing.items = tempItems;
                   }
                 });
                 
                 for (var c in itemControllers) { c.dispose(); }
                 _saveAllData();
                 Navigator.pop(ctx);
              }, 
              child: const Text("SAVE FORMULA"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUnitDialog({ProductionUnitModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? "");
    final leadCtrl = TextEditingController(text: existing?.manager ?? "");
    final capCtrl = TextEditingController(text: existing?.dailyCapacity.toString() ?? "100");
    final locCtrl = TextEditingController(text: existing?.location ?? "");
    final contactCtrl = TextEditingController(text: existing?.contact ?? "");
    final descCtrl = TextEditingController(text: existing?.description ?? "");
    String unitType = existing?.type ?? "Kitchen";
    String capUnit = existing?.capacityUnit ?? "Meals";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? "Register New Production Hub" : "Update Hub Matrix"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Unit Name *")),
              TextField(controller: leadCtrl, decoration: const InputDecoration(labelText: "Lead Manager")),
              Row(
                children: [
                  Expanded(child: TextField(controller: capCtrl, decoration: const InputDecoration(labelText: "Daily Capacity"), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<String>(
                    initialValue: capUnit,
                    items: ["Meals", "Plates", "Pcs", "KG", "Ltr"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => capUnit = v!,
                    decoration: const InputDecoration(labelText: "Unit"),
                  )),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: unitType,
                items: ["Kitchen", "Bakery", "Grill", "Beverage", "Dessert", "Prep"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => unitType = v!,
                decoration: const InputDecoration(labelText: "Unit Type"),
              ),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: "Location")),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: "Contact No.")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            if (nameCtrl.text.isEmpty) return;
            setState(() {
              if (existing == null) {
                _units.add(ProductionUnitModel(
                  id: "U${_units.length + 1}", name: nameCtrl.text, code: "C${_units.length + 1}",
                  type: unitType, manager: leadCtrl.text, dailyCapacity: int.tryParse(capCtrl.text) ?? 100,
                  openingTime: "06:00 AM", closingTime: "11:00 PM", description: descCtrl.text,
                  location: locCtrl.text, contact: contactCtrl.text, capacityUnit: capUnit,
                ));
              } else {
                existing.name = nameCtrl.text;
                existing.manager = leadCtrl.text;
                existing.dailyCapacity = int.tryParse(capCtrl.text) ?? existing.dailyCapacity;
                existing.location = locCtrl.text;
                existing.contact = contactCtrl.text;
                existing.description = descCtrl.text;
                existing.type = unitType;
                existing.capacityUnit = capUnit;
              }
            });
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("SAVE HUB")),
        ],
      ),
    );
  }

  void _showAssignProductDialog(ProductionUnitModel u, StateSetter setModalState) {
    String selected = _masterProducts[0];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Assign Product to Unit"),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          items: _masterProducts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => selected = v!,
          decoration: const InputDecoration(labelText: "Choose Item"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            setState(() => _assignedProducts.add(AssignedProductModel(productId: "P${_assignedProducts.length+1}", name: selected, category: "Menu", standardQty: 50, prepTime: 30, priority: 3)));
            setModalState(() {});
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("ASSIGN")),
        ],
      ),
    );
  }

  void _showAddPlanDialog(ProductionUnitModel u, StateSetter setModalState) {
    final qtyCtrl = TextEditingController(text: "100");
    String product = _masterProducts[0];
    String staff = _staffList[0];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Production Plan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: product,
              items: _masterProducts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => product = v!,
              decoration: const InputDecoration(labelText: "Product"),
            ),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Target Quantity"), keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              initialValue: staff,
              items: _staffList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => staff = v!,
              decoration: const InputDecoration(labelText: "Lead Staff"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            setState(() => _plans.add(ProductionPlanModel(
              id: "PLN-${_plans.length+1}",
              date: DateTime.now(), unitId: u.id, productId: product,
              plannedQty: double.tryParse(qtyCtrl.text) ?? 100,
              status: ProductionStatus.planned, staff: staff,
              startTime: "09:00 AM", endTime: "12:00 PM",
              priority: "High", notes: ""
            )));
            setModalState(() {});
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("ACTIVATE")),
        ],
      ),
    );
  }

  void _showUpdateProducedDialog(ProductionPlanModel plan, StateSetter setModalState) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Produced Qty"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Enter quantity produced now"), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            setState(() {
              plan.producedQty += double.tryParse(ctrl.text) ?? 0;
              if (plan.producedQty >= plan.plannedQty) {
                plan.status = ProductionStatus.completed;
              } else if (plan.producedQty > 0) {
                plan.status = ProductionStatus.inProgress;
              }
            });
            setModalState(() {});
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("UPDATE")),
        ],
      ),
    );
  }

  void _showRecordBatchDialog(ProductionUnitModel u, StateSetter setModalState) {
     final ctrl = TextEditingController(text: "50");
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Final Batch"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Batch Yield Quantity"), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            setState(() => _batches.add(ProductionBatchModel(
              id: "BTCH-${_batches.length+101}", date: DateTime.now(), unitId: u.id, productId: "Bulk Production",
              plannedQty: 50, actualQty: double.tryParse(ctrl.text) ?? 50,
              startTime: "10:00 AM", endTime: "11:00 AM", staff: _staffList[0],
              status: ProductionStatus.completed, notes: ""
            )));
            setModalState(() {});
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("RECORD")),
        ],
      ),
    );
  }

  void _showRecordUsageDialog(ProductionUnitModel u, StateSetter setModalState) {
    String ing = _masterIngredients[0];
    final ctrl = TextEditingController(text: "5");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Material Usage"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: ing,
              items: _masterIngredients.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: (v) => ing = v!,
              decoration: const InputDecoration(labelText: "Ingredient"),
            ),
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Used Quantity"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            setState(() => _usages.add(MaterialUsageModel(
              id: "USE-${_usages.length+1}", productionId: "GENERAL",
              ingredient: ing, plannedQty: double.tryParse(ctrl.text) ?? 5,
              actualQty: double.tryParse(ctrl.text) ?? 5, unit: "kg", notes: ""
            )));
            setModalState(() {});
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("LOG")),
        ],
      ),
    );
  }

  void _showUnitWasteDialog(ProductionUnitModel u, StateSetter setModalState) {
    final ctrl = TextEditingController();
    WasteReason reason = WasteReason.spoilage;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Production Waste"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Waste Quantity"), keyboardType: TextInputType.number),
            DropdownButtonFormField<WasteReason>(
              initialValue: reason,
              items: WasteReason.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
              onChanged: (v) => reason = v!,
              decoration: const InputDecoration(labelText: "Reason"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () {
            setState(() => _waste.add(ProductionWasteModel(
              id: "WST-${_waste.length+1}", date: DateTime.now(), unitId: u.id, productId: "Multiple Items",
              quantity: double.tryParse(ctrl.text) ?? 1, unit: "kg", reason: reason, recordedBy: "Chef Suresh", notes: ""
            )));
            setModalState(() {});
            _saveAllData();
            Navigator.pop(ctx);
          }, child: const Text("RECORD")),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy));
  }

  Widget _buildResponsiveHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.mode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMinorStat(String label, String val) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AdminTheme.darkNavy))]);
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
      child: Text(status.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      )
    );
  }

  Widget _buildEmptyTabState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.layers_clear_outlined, size: 48, color: Colors.grey.shade200), 
          const SizedBox(height: 16), 
          Text(msg, style: const TextStyle(color: Colors.grey))
        ]
      )
    );
  }

  void _showFeedback(String title, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title: $msg"), backgroundColor: AdminTheme.royalBlue));
  }

  Widget _buildStatusCounter(String label, int count, Color color, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            children: [
              Text(label, style: TextStyle(color: isSelected ? Colors.white : color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Text("$count", style: TextStyle(color: isSelected ? Colors.white : color, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected, [Function(bool)? onSelected]) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AdminTheme.darkNavy)),
        selected: isSelected,
        onSelected: onSelected ?? (v) => setState(() => _setsUnitFilter = value),
        selectedColor: AdminTheme.royalBlue,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? AdminTheme.royalBlue : Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [SizedBox(width: 150, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.darkNavy))]));
  }

  Widget _buildToggleOption(String title, String subtitle, bool val, Function(bool) onChanged) {
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
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Switch.adaptive(
            value: val, 
            activeTrackColor: AdminTheme.royalBlue.withValues(alpha: 0.3), 
            activeThumbColor: AdminTheme.royalBlue, 
            onChanged: onChanged
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(28), 
        boxShadow: AdminTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AdminTheme.royalBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
            ],
          ),
          const Divider(height: 48, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String time, String msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), 
      child: Row(
        children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)), 
          const SizedBox(width: 16), 
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: AdminTheme.darkNavy)))
        ]
      )
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TypableAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final List<String> suggestions;
  final EdgeInsets padding;

  const _TypableAutocomplete({
    required this.controller,
    required this.label,
    required this.suggestions,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  @override
  State<_TypableAutocomplete> createState() => _TypableAutocompleteState();
}

class _TypableAutocompleteState extends State<_TypableAutocomplete> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          return widget.suggestions.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (v) => onFieldSubmitted(),
            decoration: InputDecoration(
              labelText: widget.label,
              isDense: true,
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                onSelected: (String value) => controller.text = value,
                itemBuilder: (BuildContext context) => widget.suggestions.map((s) => PopupMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: 300,
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return ListTile(
                      title: Text(option, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      onTap: () => onSelected(option),
                      hoverColor: AdminTheme.royalBlue.withValues(alpha: 0.05),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
