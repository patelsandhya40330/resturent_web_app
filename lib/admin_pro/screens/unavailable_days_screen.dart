import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../services/api_service.dart';
import '../../services/tenant_service.dart';
import '../admin_theme.dart';

class UnavailableDaysScreen extends StatefulWidget {
  const UnavailableDaysScreen({super.key});

  @override
  State<UnavailableDaysScreen> createState() => _UnavailableDaysScreenState();
}

class _UnavailableDaysScreenState extends State<UnavailableDaysScreen> {
  final List<UnavailableDay> _allDays = [];
  List<UnavailableDay> _filteredDays = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _filterStatus = "All";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Simulation: In a real app, you'd fetch from API
    await Future.delayed(const Duration(milliseconds: 800));
    
    _allDays.clear();
    _allDays.addAll([
      UnavailableDay(
        id: "1",
        title: "Eid-ul-Fitr",
        reasonType: "Public Holiday",
        startDate: DateTime(2026, 8, 25),
        endDate: DateTime(2026, 8, 25),
        availabilityType: "Full Day",
        repeatType: "Every Year",
        isActive: true,
        createdAt: DateTime.now(),
      ),
      UnavailableDay(
        id: "2",
        title: "Independence Day",
        reasonType: "Public Holiday",
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 15),
        availabilityType: "Full Day",
        repeatType: "Every Year",
        isActive: true,
        createdAt: DateTime.now(),
      ),
      UnavailableDay(
        id: "3",
        title: "Renovation Break",
        reasonType: "Renovation",
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 10),
        availabilityType: "Specific Time",
        startTime: "14:00",
        endTime: "18:00",
        repeatType: "Does Not Repeat",
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ]);
    
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredDays = _allDays.where((day) {
        final matchesSearch = day.title.toLowerCase().contains(_searchQuery.toLowerCase());
        bool matchesStatus = true;
        if (_filterStatus == "Active") matchesStatus = day.isActive;
        if (_filterStatus == "Disabled") matchesStatus = !day.isActive;
        if (_filterStatus == "Upcoming") matchesStatus = day.startDate.isAfter(DateTime.now());
        if (_filterStatus == "Past") matchesStatus = day.endDate.isBefore(DateTime.now());
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          _buildFilterBar(),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_filteredDays.isEmpty)
            _buildEmptyState()
          else
            _buildDaysList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Unavailable Days", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
            const Text("Manage dates and times when reservations are blocked.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text("ADD UNAVAILABLE DAY"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.royalBlue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final upcoming = _allDays.where((d) => d.startDate.isAfter(DateTime.now())).length;
    final thisMonth = _allDays.where((d) => d.startDate.month == DateTime.now().month && d.startDate.year == DateTime.now().year).length;
    final fullDay = _allDays.where((d) => d.availabilityType == "Full Day").length;
    final partial = _allDays.where((d) => d.availabilityType == "Specific Time").length;

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
        if (constraints.maxWidth < 600) cardWidth = (constraints.maxWidth - 16) / 2;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMiniSummaryCard("Upcoming Closures", upcoming.toString(), Icons.event_note, Colors.blue),
            _buildMiniSummaryCard("This Month", thisMonth.toString(), Icons.calendar_month, Colors.orange),
            _buildMiniSummaryCard("Full Day Closures", fullDay.toString(), Icons.calendar_today, Colors.red),
            _buildMiniSummaryCard("Partial Closures", partial.toString(), Icons.access_time, Colors.purple),
          ],
        );
      }
    );
  }

  Widget _buildMiniSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200, // Approximate width, Wrap handles it
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: "Search by reason/title...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    items: ["All", "Upcoming", "Past", "Active", "Disabled"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) {
                      setState(() => _filterStatus = v!);
                      _applyFilters();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredDays.length,
      itemBuilder: (context, index) {
        final day = _filteredDays[index];
        return _buildUnavailableDayCard(day);
      },
    );
  }

  Widget _buildUnavailableDayCard(UnavailableDay day) {
    final bool isExpired = day.endDate.isBefore(DateTime.now());
    final Color statusColor = day.isActive ? (isExpired ? Colors.grey : AdminTheme.emeraldGreen) : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminTheme.softShadow,
        border: day.isActive ? null : Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(_getReasonIcon(day.reasonType), color: AdminTheme.royalBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(day.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.darkNavy)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                      child: Text(day.reasonType.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateRange(day.startDate, day.endDate),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      day.availabilityType == "Full Day" ? "Full Day" : "${day.startTime} - ${day.endTime}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  day.isActive ? (isExpired ? "EXPIRED" : "ACTIVE") : "DISABLED",
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIconButton(Icons.edit_outlined, Colors.blue, () => _showAddEditDialog(day: day)),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    day.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    day.isActive ? Colors.orange : Colors.green,
                    () => _toggleStatus(day),
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.delete_outline, Colors.red, () => _deleteDay(day)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
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

  IconData _getReasonIcon(String type) {
    switch (type) {
      case "Public Holiday": return Icons.celebration;
      case "Restaurant Holiday": return Icons.restaurant;
      case "Private Event": return Icons.lock_person;
      case "Maintenance": return Icons.build;
      case "Renovation": return Icons.home_repair_service;
      case "Staff Training": return Icons.groups;
      case "Emergency Closure": return Icons.warning;
      default: return Icons.event_busy;
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final f = DateFormat('MMM dd, yyyy');
    if (start == end) return f.format(start);
    return "${f.format(start)} - ${f.format(end)}";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No unavailable days found.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Click 'ADD UNAVAILABLE DAY' to create a new rule.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddEditDialog({UnavailableDay? day}) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditUnavailableDayDialog(
        day: day,
        onSave: (newDay) {
          setState(() {
            if (day == null) {
              _allDays.add(newDay);
            } else {
              final idx = _allDays.indexWhere((d) => d.id == day.id);
              _allDays[idx] = newDay;
            }
            _applyFilters();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unavailable day ${day == null ? 'added' : 'updated'} successfully!"), backgroundColor: AdminTheme.emeraldGreen),
          );
        },
      ),
    );
  }

  void _toggleStatus(UnavailableDay day) {
    final idx = _allDays.indexWhere((d) => d.id == day.id);
    final updated = UnavailableDay(
      id: day.id,
      title: day.title,
      reasonType: day.reasonType,
      startDate: day.startDate,
      endDate: day.endDate,
      availabilityType: day.availabilityType,
      startTime: day.startTime,
      endTime: day.endTime,
      repeatType: day.repeatType,
      notes: day.notes,
      isActive: !day.isActive,
      createdAt: day.createdAt,
    );
    setState(() {
      _allDays[idx] = updated;
      _applyFilters();
    });
  }

  void _deleteDay(UnavailableDay day) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Unavailable Period?"),
        content: const Text("Are you sure you want to permanently delete this unavailable period? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _allDays.removeWhere((d) => d.id == day.id);
        _applyFilters();
      });
    }
  }
}

class AddEditUnavailableDayDialog extends StatefulWidget {
  final UnavailableDay? day;
  final Function(UnavailableDay) onSave;

  const AddEditUnavailableDayDialog({super.key, this.day, required this.onSave});

  @override
  State<AddEditUnavailableDayDialog> createState() => _AddEditUnavailableDayDialogState();
}

class _AddEditUnavailableDayDialogState extends State<AddEditUnavailableDayDialog> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _reasonType = "Public Holiday";
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _availabilityType = "Full Day";
  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String _repeatType = "Does Not Repeat";
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.day != null) {
      _titleController.text = widget.day!.title;
      _notesController.text = widget.day!.notes ?? "";
      _reasonType = widget.day!.reasonType;
      _startDate = widget.day!.startDate;
      _endDate = widget.day!.endDate;
      _availabilityType = widget.day!.availabilityType;
      if (widget.day!.startTime != null) {
        final parts = widget.day!.startTime!.split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (widget.day!.endTime != null) {
        final parts = widget.day!.endTime!.split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      _repeatType = widget.day!.repeatType;
      _isActive = widget.day!.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.day == null ? "Add Unavailable Day" : "Edit Unavailable Day", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
              const SizedBox(height: 8),
              const Text("Specify a period where the restaurant will be closed for reservations.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Divider(height: 48),
              
              _buildLabel("Reason / Title"),
              TextField(
                controller: _titleController,
                decoration: _inputDecoration("e.g. Eid Holiday, Private Event..."),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Reason Type"),
                        _buildDropdown(
                          value: _reasonType,
                          items: ["Public Holiday", "Restaurant Holiday", "Private Event", "Maintenance", "Renovation", "Staff Training", "Emergency Closure", "Other"],
                          onChanged: (v) => setState(() => _reasonType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Repeat"),
                        _buildDropdown(
                          value: _repeatType,
                          items: ["Does Not Repeat", "Every Week", "Every Month", "Every Year"],
                          onChanged: (v) => setState(() => _repeatType = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildLabel("Date Range"),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: "Start Date",
                      value: _startDate,
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (d != null) setState(() => _startDate = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(
                      label: "End Date",
                      value: _endDate,
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2030));
                        if (d != null) setState(() => _endDate = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildLabel("Availability Type"),
              Row(
                children: [
                  _buildChoiceChip("Full Day", _availabilityType == "Full Day", () => setState(() => _availabilityType = "Full Day")),
                  const SizedBox(width: 12),
                  _buildChoiceChip("Specific Time", _availabilityType == "Specific Time", () => setState(() => _availabilityType = "Specific Time")),
                ],
              ),
              
              if (_availabilityType == "Specific Time") ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        label: "Start Time",
                        value: _startTime,
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: _startTime);
                          if (t != null) setState(() => _startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        label: "End Time",
                        value: _endTime,
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: _endTime);
                          if (t != null) setState(() => _endTime = t);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              
              _buildLabel("Additional Notes"),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration("Write any extra details here..."),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  const Text("Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: AdminTheme.emeraldGreen,
                  ),
                  Text(_isActive ? "Active" : "Disabled", style: TextStyle(color: _isActive ? AdminTheme.emeraldGreen : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("CANCEL"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.royalBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("SAVE UNAVAILABLE DAY"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a reason/title.")));
      return;
    }

    setState(() => _isSaving = true);
    
    // Check for conflicts
    final conflicts = await _checkConflicts();
    if (conflicts > 0) {
      if (mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Existing Reservations Found"),
            content: Text("$conflicts reservations already exist during this period. Are you sure you want to proceed? Affecting existing bookings may require manual cancellation."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CONTINUE")),
            ],
          ),
        );
        if (proceed != true) {
          setState(() => _isSaving = false);
          return;
        }
      }
    }

    final newDay = UnavailableDay(
      id: widget.day?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      reasonType: _reasonType,
      startDate: _startDate,
      endDate: _endDate,
      availabilityType: _availabilityType,
      startTime: _availabilityType == "Specific Time" ? "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}" : null,
      endTime: _availabilityType == "Specific Time" ? "${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}" : null,
      repeatType: _repeatType,
      notes: _notesController.text.trim(),
      isActive: _isActive,
      createdAt: widget.day?.createdAt ?? DateTime.now(),
    );

    widget.onSave(newDay);
    if (mounted) Navigator.pop(context);
  }

  Future<int> _checkConflicts() async {
    final tenant = TenantService().currentTenant.value;
    if (tenant == null) return 0;
    
    final orders = await ApiService.fetchAllOrders(tenant.id);
    if (orders == null) return 0;
    
    int conflicts = 0;
    for (var order in orders) {
      try {
        final orderDate = DateTime.parse(order['created_at']);
        if (orderDate.isAfter(_startDate.subtract(const Duration(days: 1))) && orderDate.isBefore(_endDate.add(const Duration(days: 1)))) {
          // Simplistic date check for now, can be refined for time-based partial closures
          conflicts++;
        }
      } catch (e) {
        debugPrint("Error parsing date: $e");
      }
    }
    return conflicts;
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('MMM dd, yyyy').format(value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const Icon(Icons.calendar_month, size: 18, color: AdminTheme.royalBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({required String label, required TimeOfDay value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value.format(context), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const Icon(Icons.access_time, size: 18, color: AdminTheme.royalBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.royalBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
