import 'package:flutter/material.dart';
import '../../models.dart';
import '../admin_theme.dart';
import 'package:intl/intl.dart';

class ReservationManagementScreen extends StatefulWidget {
  final String mode;
  const ReservationManagementScreen({super.key, required this.mode});

  @override
  State<ReservationManagementScreen> createState() => _ReservationManagementScreenState();
}

class _ReservationManagementScreenState extends State<ReservationManagementScreen> {
  final List<UnavailableDay> _unavailableRules = [];
  final List<Booking> _bookings = [];
  String _searchQuery = "";
  String _activeFilter = "ALL";
  
  final List<String> _staffMembers = ["Ram Bahadur", "Sita Devi", "Hari Prasad", "Gita Thapa", "Arjun BK"];
  
  int _activeCheckInStep = 0; // 0: Guest Info, 1: Stay, 2: Docs, 3: Payment
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _guestCountController = TextEditingController(text: "1");
  
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _dob;
  String _idType = "Citizenship";
  
  // Mock available rooms for picker
  final Map<String, List<String>> _roomsByCategory = {
    "Standard Room": ["R-101", "R-102", "R-103", "R-104"],
    "Deluxe Room": ["R-201", "R-202", "R-205"],
    "Superior Room": ["R-301", "R-302"],
    "Executive Room": ["R-401", "R-405"],
    "Family Room": ["F-101", "F-102"],
    "Suite Room": ["S-501", "S-502"],
    "Presidential Suite": ["P-001"],
  };

  final List<Map<String, String>> _roomCategories = [
    {"title": "Standard Room", "desc": "Basic, comfortable room"},
    {"title": "Deluxe Room", "desc": "Better space and upgraded facilities"},
    {"title": "Superior Room", "desc": "Higher standard than Deluxe"},
    {"title": "Executive Room", "desc": "Business/premium facilities"},
    {"title": "Family Room", "desc": "Designed for families"},
    {"title": "Suite Room", "desc": "Separate bedroom + living area"},
    {"title": "Presidential Suite", "desc": "Highest luxury category"},
  ];

  final List<String> _roomTypes = [
    "One Setter – 1 guest",
    "Two Setter – 2 guests",
    "Three Setter – 3 guests",
    "Four Setter – 4 guests",
    "Five Setter – 5 guests",
    "Six Setter – 6 guests",
    "Dormitory – Multiple guests"
  ];

  String? _selectedCategory;
  final List<String> _selectedRooms = [];
  String _selectedRoomType = "One Setter – 1 guest";

  @override
  void initState() {
    super.initState();
    _loadUnavailableRules();
    _loadDemoBookings();
  }

  void _loadDemoBookings() {
    _bookings.addAll([
      Booking(
        id: "RES-4521",
        guestName: "Yuvraj Patwa",
        guestCount: 4,
        address: "Kathmandu, Nepal",
        phoneNumber: "+977-9801234567",
        roomNumbers: ["T-101"],
        roomType: "Four Setter – 4 guests",
        scheduledCheckIn: DateTime.now().subtract(const Duration(hours: 4)),
        scheduledCheckOut: DateTime.now().add(const Duration(days: 2)),
        actualCheckIn: DateTime.now().subtract(const Duration(hours: 3)),
        status: BookingStatus.Staying,
        isPaid: true,
        isIdVerified: true,
        orders: [OrderItem(name: "Pizza & Soda", qty: "1", price: "NPR 850")],
      ),
      Booking(
        id: "RES-4522",
        guestName: "Catherine J.",
        guestCount: 2,
        address: "Pokhara, Nepal",
        phoneNumber: "+977-9811112222",
        roomNumbers: ["R-502"],
        roomType: "Two Setter – 2 guests",
        scheduledCheckIn: DateTime.now().add(const Duration(hours: 2)),
        scheduledCheckOut: DateTime.now().add(const Duration(days: 3)),
        status: BookingStatus.Pending,
        isPaid: false,
        isIdVerified: true,
      ),
      Booking(
        id: "RES-4523",
        guestName: "Noah Smith",
        guestCount: 1,
        address: "Lalitpur, Nepal",
        phoneNumber: "+977-9822223333",
        roomNumbers: ["T-103"],
        roomType: "One Setter – 1 guest",
        scheduledCheckIn: DateTime.now().subtract(const Duration(days: 2)),
        scheduledCheckOut: DateTime.now().subtract(const Duration(hours: 1)),
        actualCheckIn: DateTime.now().subtract(const Duration(days: 2)),
        actualCheckOut: DateTime.now().subtract(const Duration(hours: 1)),
        status: BookingStatus.Completed,
        isPaid: true,
        isIdVerified: true,
      ),
    ]);
  }

  Future<void> _loadUnavailableRules() async {
    // In a real app, fetch from backend. Mocking for now.
    await Future.delayed(const Duration(milliseconds: 500));
    _unavailableRules.clear();
    _unavailableRules.addAll([
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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mode == "Add Booking") _buildAddBookingForm()
          else if (widget.mode == "Reservation Setting") _buildSettingView()
          else _buildReservationListView(context),
        ],
      ),
    );
  }

  Widget _buildReservationListView(BuildContext context) {
    final filteredBookings = _bookings.where((b) {
      // 1. Search Query Filter
      bool matchesSearch = b.guestName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        b.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        b.roomNumbers.any((rn) => rn.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      // 2. Summary Tile Filter Logic
      if (_activeFilter == "STAYING") return b.status == BookingStatus.Staying;
      if (_activeFilter == "ARRIVALS") return b.status == BookingStatus.Pending; // Pending check-ins
      if (_activeFilter == "DEPARTURES") return b.status == BookingStatus.Completed; // History/Archived
      if (_activeFilter == "DIRTY ROOMS") return b.status == BookingStatus.Cleaning;
      
      // Default ALL: Show everything except completed ones to keep work log active
      if (_activeFilter == "ALL") return b.status != BookingStatus.Completed;
      
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Booking Log & Operations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                Text(_activeFilter == "DEPARTURES" ? "Viewing Archived / History" : "Currently viewing: $_activeFilter", 
                     style: TextStyle(color: _activeFilter == "DEPARTURES" ? AdminTheme.royalBlue : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                _buildFilterChip("ALL ACTIVE", _activeFilter == "ALL", onTap: () => setState(() => _activeFilter = "ALL")),
                const SizedBox(width: 8),
                _buildFilterChip("HISTORY", _activeFilter == "DEPARTURES", onTap: () => setState(() => _activeFilter = "DEPARTURES")),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Professional Status Summary Bar
        _buildStayLogSummary(),
        const SizedBox(height: 24),
        
        // Search and Filter Bar
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AdminTheme.softShadow,
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey, size: 20),
                    hintText: "Search by ID, Name or Member No...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.royalBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        if (filteredBookings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No bookings found", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Add a new guest from the 'New Check-In' menu.", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...filteredBookings.map((booking) => _buildReservationCard(context, booking)),
      ],
    );
  }

  Widget _buildStayLogSummary() {
    int staying = _bookings.where((b) => b.status == BookingStatus.Staying).length;
    int pending = _bookings.where((b) => b.status == BookingStatus.Pending).length;
    int completed = _bookings.where((b) => b.status == BookingStatus.Completed).length;
    int cleaning = _bookings.where((b) => b.status == BookingStatus.Cleaning).length;

    return Row(
      children: [
        _buildSummaryItem("STAYING", staying.toString().padLeft(2, '0'), Colors.green, isSelected: _activeFilter == "STAYING"),
        const SizedBox(width: 12),
        _buildSummaryItem("ARRIVALS", pending.toString().padLeft(2, '0'), Colors.blue, isSelected: _activeFilter == "ARRIVALS"),
        const SizedBox(width: 12),
        _buildSummaryItem("DEPARTURES", completed.toString().padLeft(2, '0'), Colors.orange, isSelected: _activeFilter == "DEPARTURES"),
        const SizedBox(width: 12),
        _buildSummaryItem("DIRTY ROOMS", cleaning.toString().padLeft(2, '0'), Colors.red, isSelected: _activeFilter == "DIRTY ROOMS"),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, {bool isSelected = false}) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = isSelected ? "ALL" : label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : Colors.grey, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.royalBlue : AdminTheme.royalBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AdminTheme.royalBlue,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Booking booking) {
    Color statusColor;
    switch (booking.status) {
      case BookingStatus.Staying: statusColor = AdminTheme.emeraldGreen; break;
      case BookingStatus.Pending: statusColor = Colors.orange; break;
      case BookingStatus.Completed: statusColor = AdminTheme.royalBlue; break;
      case BookingStatus.Cancelled: statusColor = Colors.red; break;
      case BookingStatus.Cleaning: statusColor = Colors.purple; break;
    }
    
    // Payment-based border color ("Collar")
    Color billColor = booking.isPaid ? AdminTheme.emeraldGreen : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminTheme.softShadow,
        // The "Collar" change - Highlight border if paid
        border: Border(top: BorderSide(color: billColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name & ID, Status
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Icon(booking.status == BookingStatus.Pending ? Icons.other_houses_outlined : Icons.person_outline, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(booking.guestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: (booking.isPaid ? AdminTheme.emeraldGreen : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(booking.isPaid ? "SETTLED" : "PAYMENT PENDING", style: TextStyle(color: booking.isPaid ? AdminTheme.emeraldGreen : Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(booking.id, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status.name.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          
          // Details Grid-like structure
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildInfoItem(Icons.calendar_today_outlined, "Check-In", DateFormat('MMM dd, hh:mm a').format(booking.scheduledCheckIn)),
              _buildInfoItem(Icons.exit_to_app_rounded, "Check-Out", DateFormat('MMM dd, hh:mm a').format(booking.scheduledCheckOut)),
              _buildInfoItem(Icons.bedroom_child_outlined, "Room Nos.", booking.roomNumbers.join(", ")),
              _buildInfoItem(Icons.category_outlined, "Room Type", booking.roomType),
              _buildInfoItem(Icons.people_outline, "Guests", "${booking.guestCount} People"),
              _buildInfoItem(Icons.credit_card_outlined, "Bill Status", booking.isPaid ? "SETTLED" : "UNPAID", color: billColor),
              _buildInfoItem(Icons.badge_outlined, "ID Proof", booking.isIdVerified ? "Verified ✅" : "Pending ⚠️", color: booking.isIdVerified ? AdminTheme.emeraldGreen : Colors.orange),
              _buildInfoItem(Icons.cleaning_services_outlined, "HK Status", booking.housekeepingStatus.name, color: booking.housekeepingStatus == HousekeepingStatus.Completed ? AdminTheme.emeraldGreen : Colors.orange),
              if (booking.cleanedBy != null)
                _buildInfoItem(Icons.person_pin_outlined, "Cleaned By", booking.cleanedBy!, color: AdminTheme.royalBlue),
              if (booking.actualCheckIn != null)
                _buildInfoItem(Icons.access_time, "Actual Check-In", DateFormat('hh:mm a').format(booking.actualCheckIn!), color: AdminTheme.emeraldGreen),
              if (booking.actualCheckOut != null)
                _buildInfoItem(Icons.access_time_filled, "Actual Check-Out", DateFormat('hh:mm a').format(booking.actualCheckOut!), color: Colors.orange),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Check-in / Check-out Status Controls
          Row(
            children: [
              if (booking.status == BookingStatus.Pending)
                Expanded(child: _buildStatusAction("Check-In Guest", Icons.login, AdminTheme.emeraldGreen, () {
                  setState(() {
                    booking.status = BookingStatus.Staying;
                    booking.actualCheckIn = DateTime.now();
                  });
                })),
              if (booking.status == BookingStatus.Staying)
                Expanded(child: _buildStatusAction(booking.isPaid ? "Proceed to Check-Out" : "Settle Bill & Check-Out", Icons.logout, booking.isPaid ? AdminTheme.emeraldGreen : Colors.orange, () {
                  _showDetails(context, booking);
                })),
              if (booking.status == BookingStatus.Cleaning && booking.housekeepingStatus != HousekeepingStatus.Completed)
                Expanded(child: _buildStatusAction("Assign Staff & Start Cleaning", Icons.cleaning_services, Colors.purple, () {
                  _showCleaningAssignmentModal(context, booking);
                })),
              if (booking.status == BookingStatus.Cleaning && booking.housekeepingStatus == HousekeepingStatus.Completed)
                Expanded(child: _buildStatusAction("Ready for Production (Move to History)", Icons.check_circle_outline, AdminTheme.emeraldGreen, () {
                  setState(() {
                    booking.status = BookingStatus.Completed;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Room is now ready. Entry moved to Departures/History."), backgroundColor: AdminTheme.emeraldGreen));
                })),
            ],
          ),
          
          const Divider(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(child: _buildMainAction("Guest Folio", Icons.receipt_long_outlined, AdminTheme.royalBlue, () => _showDetails(context, booking))),
              const SizedBox(width: 12),
              Expanded(child: _buildMainAction("Print Invoice", Icons.print_outlined, Colors.blueGrey, () {})),
              const SizedBox(width: 12),
              Expanded(child: _buildMainAction("Cancel", Icons.cancel_outlined, Colors.red, () => _showCancelDialog(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCleaningAssignmentModal(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Housekeeping Staff"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _staffMembers.map((staff) => ListTile(
            title: Text(staff),
            leading: const Icon(Icons.person_outline),
            onTap: () {
              setState(() {
                booking.cleanedBy = staff;
                booking.housekeepingStatus = HousekeepingStatus.InProgress;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cleaning assigned to $staff")));
              
              // Simulate completion for demo
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    booking.housekeepingStatus = HousekeepingStatus.Completed;
                  });
                }
              });
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Booking booking) {
    bool isReadOnly = booking.status == BookingStatus.Completed;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isReadOnly ? "Archived Guest Folio (View Only)" : "Guest Folio & Management", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildSectionTitle(isReadOnly ? "GUEST INFORMATION" : "GUEST INFORMATION (EDITABLE)"),
                    if (isReadOnly) ...[
                      _buildDetailRow("Full Name", booking.guestName),
                      _buildDetailRow("Phone", booking.phoneNumber),
                      _buildDetailRow("Address", booking.address),
                    ] else ...[
                      _buildEditableTextField("Full Name", booking.guestName, (v) {
                        booking.guestName = v;
                        setState(() {});
                        setModalState(() {});
                      }),
                      const SizedBox(height: 12),
                      _buildEditableTextField("Phone", booking.phoneNumber, (v) {
                        booking.phoneNumber = v;
                        setState(() {});
                        setModalState(() {});
                      }),
                      const SizedBox(height: 12),
                      _buildEditableTextField("Address", booking.address, (v) {
                        booking.address = v;
                        setState(() {});
                        setModalState(() {});
                      }),
                    ],
                    
                    const SizedBox(height: 24),
                  _buildSectionTitle("STAY MANAGEMENT & ROOM ALLOCATION"),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Room Type", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _roomTypes.contains(booking.roomType) ? booking.roomType : _roomTypes.first,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                                  items: _roomTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: isReadOnly ? null : (v) {
                                    setState(() => booking.roomType = v!);
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Assign Room Numbers", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            if (isReadOnly)
                              Text(booking.roomNumbers.join(", "), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
                            else
                              TextField(
                                onChanged: (v) {
                                  booking.roomNumbers = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  setState(() {});
                                  setModalState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: booking.roomNumbers.join(", "),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                controller: TextEditingController.fromValue(TextEditingValue(text: booking.roomNumbers.join(", "), selection: TextSelection.collapsed(offset: booking.roomNumbers.join(", ").length))),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: isReadOnly ? null : () async {
                              final d = await showDatePicker(context: context, initialDate: booking.scheduledCheckIn, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime(2030));
                              if (d != null) {
                                setModalState(() {
                                  booking.scheduledCheckIn = d;
                                });
                                setState(() {});
                              }
                            },
                            child: _buildEditableInfoItem(Icons.login, "Check-In Date", DateFormat('MMM dd, yyyy').format(booking.scheduledCheckIn)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: isReadOnly ? null : () async {
                              final d = await showDatePicker(context: context, initialDate: booking.scheduledCheckOut, firstDate: booking.scheduledCheckIn.add(const Duration(days: 1)), lastDate: DateTime(2030));
                              if (d != null) {
                                setModalState(() {
                                  booking.scheduledCheckOut = d;
                                });
                                setState(() {});
                              }
                            },
                            child: _buildEditableInfoItem(Icons.logout, "Check-Out Date", DateFormat('MMM dd, yyyy').format(booking.scheduledCheckOut)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow("Nights", "${booking.scheduledCheckOut.difference(booking.scheduledCheckIn).inDays} Nights"),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("FOOD & EXTRA SERVICES"),
                        if (!isReadOnly)
                          TextButton.icon(
                            onPressed: () => _showAddServiceDialog(context, booking, () {
                              setModalState(() {});
                              setState(() {});
                            }),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Add Service"),
                          ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: booking.orders.isEmpty 
                          ? [const Text("No extra services added", style: TextStyle(color: Colors.grey, fontSize: 13))]
                          : booking.orders.map((o) => _buildOrderItem(o.name, o.qty, o.price)).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle("FINANCIAL SUMMARY & BILL STATUS"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (booking.isPaid ? AdminTheme.emeraldGreen : Colors.red).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Payment Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (isReadOnly)
                            Text("PAID / SETTLED", style: TextStyle(color: AdminTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12))
                          else
                            DropdownButton<bool>(
                              value: booking.isPaid,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: false, child: Text("UNPAID", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                                DropdownMenuItem(value: true, child: Text("PAID / SETTLED", style: TextStyle(color: AdminTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                              onChanged: (v) {
                                setState(() => booking.isPaid = v!);
                                setModalState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPriceBreakdown(booking),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle("INTERNAL STAFF NOTES"),
                    if (isReadOnly)
                      Text(booking.staffNotes ?? "No internal notes.", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))
                    else
                      _buildEditableTextField("Notes", booking.staffNotes ?? "No internal notes added.", (v) {
                        booking.staffNotes = v;
                        setState(() {});
                        setModalState(() {});
                      }),
                    
                    const SizedBox(height: 40),
                    if (booking.status == BookingStatus.Staying)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            booking.status = BookingStatus.Cleaning;
                            booking.actualCheckOut = DateTime.now();
                            booking.housekeepingStatus = HousekeepingStatus.Assigned;
                            booking.isPaid = true;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settled & Checked Out"), backgroundColor: Colors.orange));
                        },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text("SETTLE & CHECK-OUT NOW"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: AdminTheme.emeraldGreen,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableTextField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: value,
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          controller: TextEditingController.fromValue(TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length))),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AdminTheme.royalBlue, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSmallDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AdminTheme.royalBlue.withValues(alpha: 0.3), style: BorderStyle.none),
        borderRadius: BorderRadius.circular(12),
        color: AdminTheme.royalBlue.withValues(alpha: 0.05),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 20, color: AdminTheme.royalBlue),
          SizedBox(width: 8),
          Text("Add Doc", style: TextStyle(color: AdminTheme.royalBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Reservation?"),
        content: const Text("Are you sure you want to cancel this booking? This action cannot be undone and a notification will be sent to the customer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO, KEEP IT")),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("YES, CANCEL BOOKING"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$name x$qty", style: const TextStyle(fontSize: 13)),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDocCard(String name, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEditableInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.royalBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.royalBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AdminTheme.royalBlue),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow("Room Charges (${booking.scheduledCheckOut.difference(booking.scheduledCheckIn).inDays} Nights)", "NPR ${booking.totalRoomCharges.toStringAsFixed(0)}"),
          _buildSummaryRow("Extra Services", "NPR ${booking.totalOrderCharges.toStringAsFixed(0)}"),
          _buildSummaryRow("Taxes (13%)", "NPR ${( (booking.totalRoomCharges + booking.totalOrderCharges) * 0.13).toStringAsFixed(0)}"),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("GRAND TOTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              Text("NPR ${booking.grandTotal.toStringAsFixed(0)}", style: const TextStyle(color: AdminTheme.emeraldGreen, fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, Booking booking, VoidCallback onUpdate) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Extra Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "Service (e.g. Breakfast, Laundry)")),
            const SizedBox(height: 12),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Price (NPR)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                booking.orders.add(OrderItem(name: nameController.text, qty: "1", price: "NPR ${priceController.text}"));
                onUpdate();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? color}) {
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color ?? AdminTheme.darkNavy)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAddBookingForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Guest Registration Portal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AdminTheme.darkNavy)),
                      Text("Offline Walk-in Interview • Step ${_activeCheckInStep + 1} of 4", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildStepIndicator(),
              ],
            ),
            const SizedBox(height: 32),
            
            if (isMobile) ...[
              _buildCurrentStepView(),
              const SizedBox(height: 24),
              _buildCheckInSummaryCard(),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Dynamic Form Steps
                  Expanded(
                    flex: 3,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCurrentStepView(),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right: Live Summary Card
                  Expanded(
                    flex: 2,
                    child: _buildCheckInSummaryCard(),
                  ),
                ],
              ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(4, (index) {
        bool isActive = _activeCheckInStep == index;
        bool isDone = _activeCheckInStep > index;
        return Container(
          margin: const EdgeInsets.only(left: 8),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? AdminTheme.royalBlue : (isDone ? AdminTheme.emeraldGreen : Colors.grey.shade200),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check : (index == 0 ? Icons.person : index == 1 ? Icons.hotel : index == 2 ? Icons.badge : Icons.payments),
            size: 16, color: isActive || isDone ? Colors.white : Colors.grey,
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_activeCheckInStep) {
      case 0: return _buildGuestInfoStep();
      case 1: return _buildStayStep();
      case 2: return _buildDocsStep();
      case 3: return _buildPaymentStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildGuestInfoStep() {
    return _buildStepContainer(
      title: "Primary Guest Information",
      subtitle: "Capture basic identity and contact details.",
      child: Column(
        children: [
          _buildTextField("Full Name", "Guest's legal name", controller: _nameController, icon: Icons.person_outline),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                    if (d != null) setState(() => _dob = d);
                  },
                  child: _buildReadOnlyField("Date of Birth", _dob == null ? "Select DOB" : DateFormat('MMM dd, yyyy').format(_dob!), icon: Icons.cake_outlined),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Guest Count", "How many people?", controller: _guestCountController, icon: Icons.people_outline)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField("Phone Number", "+977-XXXXXXXXXX", controller: _phoneController, icon: Icons.phone_android_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Email (Optional)", "guest@example.com", controller: _emailController, icon: Icons.alternate_email_outlined)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField("Address", "Current residence address", controller: _addressController, icon: Icons.location_on_outlined),
          const SizedBox(height: 32),
          _buildNavigationButtons(showBack: false, onNext: () => setState(() => _activeCheckInStep = 1)),
        ],
      ),
    );
  }

  Widget _buildStayStep() {
    return _buildStepContainer(
      title: "Stay & Room Allocation",
      subtitle: "Select room type and assign one or more rooms.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _checkInDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (d != null) setState(() => _checkInDate = d);
                  },
                  child: _buildReadOnlyField("Check-In", DateFormat('MMM dd, yyyy').format(_checkInDate), icon: Icons.login),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _checkOutDate, firstDate: _checkInDate.add(const Duration(days: 1)), lastDate: DateTime(2030));
                    if (d != null) setState(() => _checkOutDate = d);
                  },
                  child: _buildReadOnlyField("Check-Out", DateFormat('MMM dd, yyyy').format(_checkOutDate), icon: Icons.logout),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDropdownField("Category / Room Type", _selectedRoomType, _roomTypes, (v) => setState(() => _selectedRoomType = v!)),
          const SizedBox(height: 32),
          
          const Text("Select Room Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.darkNavy)),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _roomCategories.length,
              itemBuilder: (context, index) {
                final cat = _roomCategories[index];
                bool isSelected = _selectedCategory == cat['title'];
                return InkWell(
                  onTap: () => setState(() {
                    _selectedCategory = cat['title'];
                  }),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AdminTheme.royalBlue : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AdminTheme.royalBlue : Colors.grey.shade200),
                      boxShadow: isSelected ? [BoxShadow(color: AdminTheme.royalBlue.withValues(alpha: 0.2), blurRadius: 8)] : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.white : AdminTheme.darkNavy)),
                        const SizedBox(height: 4),
                        Text(cat['desc']!, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_selectedCategory != null) ...[
            const SizedBox(height: 24),
            Text("Available Rooms in $_selectedCategory (Select multiple)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.darkNavy)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: (_roomsByCategory[_selectedCategory] ?? []).map((room) {
                bool isSelected = _selectedRooms.contains(room);
                return InkWell(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedRooms.remove(room);
                    } else {
                      _selectedRooms.add(room);
                    }
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? AdminTheme.royalBlue : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AdminTheme.royalBlue : Colors.grey.shade200, width: 2),
                      boxShadow: isSelected ? [BoxShadow(color: AdminTheme.royalBlue.withValues(alpha: 0.2), blurRadius: 10)] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bedroom_child, size: 20, color: isSelected ? Colors.white : Colors.grey),
                        const SizedBox(height: 4),
                        Text(room, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : AdminTheme.darkNavy)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 32),
          _buildNavigationButtons(onBack: () => setState(() => _activeCheckInStep = 0), onNext: () => setState(() => _activeCheckInStep = 2)),
        ],
      ),
    );
  }

  Widget _buildDocsStep() {
    return _buildStepContainer(
      title: "Identity & Verification",
      subtitle: "Collect and verify guest documents.",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownField("ID Type", _idType, ["Citizenship", "Passport", "Driving License"], (v) => setState(() => _idType = v!)),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("ID Number", "Enter document number", controller: _idNumberController, icon: Icons.numbers)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildDocumentUploader("Identity Front")),
              const SizedBox(width: 16),
              Expanded(child: _buildDocumentUploader("Identity Back")),
            ],
          ),
          const SizedBox(height: 32),
          _buildNavigationButtons(onBack: () => setState(() => _activeCheckInStep = 1), onNext: () => setState(() => _activeCheckInStep = 3)),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return _buildStepContainer(
      title: "Payment & Confirmation",
      subtitle: "Finalize bill and process check-in.",
      child: Column(
        children: [
          _buildTextField("Initial Deposit (NPR)", "5,000", icon: Icons.payments_outlined),
          const SizedBox(height: 20),
          _buildDropdownField("Payment Mode", "Cash", ["Cash", "Fonepay", "Card"], (v) {}),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AdminTheme.emeraldGreen.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminTheme.emeraldGreen.withValues(alpha: 0.1))),
            child: const Row(
              children: [
                Icon(Icons.verified_user, color: AdminTheme.emeraldGreen),
                SizedBox(width: 16),
                Expanded(child: Text("I confirm that the guest has been interviewed and all information provided is accurate.", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.emeraldGreen))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildNavigationButtons(
            onBack: () => setState(() => _activeCheckInStep = 2),
            nextLabel: "FINALIZE CHECK-IN",
            onNext: _handleCheckIn,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInSummaryCard() {
    int nights = _checkOutDate.difference(_checkInDate).inDays;
    double roomRate = 8500; // Mock
    double total = (nights <= 0 ? 1 : nights) * roomRate * (_selectedRooms.isEmpty ? 1 : _selectedRooms.length);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AdminTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Folio Summary", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSummaryRow("Guest", _nameController.text.isEmpty ? "New Walk-in" : _nameController.text),
          _buildSummaryRow("Rooms", _selectedRooms.isEmpty ? "Not Assigned" : _selectedRooms.join(", ")),
          _buildSummaryRow("Duration", "$nights Nights"),
          const Divider(color: Colors.white24, height: 32),
          _buildSummaryRow("Room Charges", "NPR ${total.toStringAsFixed(0)}", isBold: true),
          _buildSummaryRow("Taxes (13%)", "NPR ${(total * 0.13).toStringAsFixed(0)}"),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("EST. TOTAL", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("NPR ${(total * 1.13).toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text("STAFF NOTES", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          const Text("Guest preferred quiet floor. Verified ID against physical card.", style: TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStepContainer({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AdminTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 48),
          child,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons({bool showBack = true, String nextLabel = "NEXT STEP", VoidCallback? onBack, required VoidCallback onNext}) {
    return Row(
      children: [
        if (showBack) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("BACK"),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: nextLabel == "FINALIZE CHECK-IN" ? AdminTheme.emeraldGreen : AdminTheme.royalBlue,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: options.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploader(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {},
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.grey),
                SizedBox(height: 8),
                Text("Capture / Upload", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: AdminTheme.royalBlue), const SizedBox(width: 12)],
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.darkNavy)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(val, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _handleCheckIn() {
    final reason = _getUnavailableReason(_checkInDate);
    if (reason != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Date Unavailable"),
          content: Text(reason),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    // Create new booking
    final newBooking = Booking(
      id: "RES-${_bookings.length + 4521}",
      guestName: _nameController.text,
      dob: _dob,
      guestCount: int.tryParse(_guestCountController.text) ?? 1,
      address: _addressController.text,
      phoneNumber: _phoneController.text,
      roomNumbers: List.from(_selectedRooms),
      roomType: _selectedRoomType,
      scheduledCheckIn: _checkInDate,
      scheduledCheckOut: _checkOutDate,
      status: BookingStatus.Pending,
      isPaid: false,
      isIdVerified: true,
    );

    setState(() {
      _bookings.add(newBooking);
      _activeCheckInStep = 0;
      // Clear controllers
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _addressController.clear();
      _guestCountController.text = "1";
      _dob = null;
      _selectedCategory = null;
      _selectedRooms.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guest checked in successfully!"), backgroundColor: AdminTheme.emeraldGreen));
  }

  String? _getUnavailableReason(DateTime date) {
    for (var rule in _unavailableRules) {
      if (!rule.isActive) continue;
      
      // Simple date normalization for comparison
      final start = DateTime(rule.startDate.year, rule.startDate.month, rule.startDate.day);
      final end = DateTime(rule.endDate.year, rule.endDate.month, rule.endDate.day);
      final target = DateTime(date.year, date.month, date.day);

      if (target.isAfter(start.subtract(const Duration(seconds: 1))) && 
          target.isBefore(end.add(const Duration(days: 1)))) {
        
        if (rule.availabilityType == "Full Day") {
          return "Reservations are unavailable on this date (${rule.title}).";
        } else {
          return "Reservations are restricted from ${rule.startTime} to ${rule.endTime} on this date (${rule.title}).";
        }
      }
    }
    return null;
  }

  Widget _buildTextField(String label, String hint, {TextEditingController? controller, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AdminTheme.royalBlue) : null,
            hintStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Booking Policy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("Configure how customers can interact with the reservation system.", style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 24),
        _buildToggleCard("Auto-Confirm Bookings", "Accept all bookings instantly without manual review.", true),
        _buildToggleCard("SMS Notification", "Send confirmation and reminder SMS to customers.", false),
        _buildToggleCard("Room Pre-Assignment", "Automatically assign rooms based on guest preferences.", true),
        _buildToggleCard("Pre-Order Food", "Allow guests to order food while booking.", true),
        const SizedBox(height: 24),
        const Text("Occupancy Limits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField("Max Guests/Room", "04")),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField("Min Guests/Room", "01")),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField("Booking Window (Days)", "30"),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
          child: const Text("SAVE SETTINGS"),
        ),
      ],
    );
  }

  Widget _buildToggleCard(String label, String sublabel, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AdminTheme.softShadow,
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: (v) {},
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sublabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        activeTrackColor: AdminTheme.emeraldGreen,
      ),
    );
  }
}
