import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _replyController = TextEditingController();
  final _searchController = TextEditingController();
  
  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _isChatLoading = false;
  
  // View States: 0: Help Hub, 1: Ticket Center, 2: New Ticket
  int _currentView = 0; 
  
  // --- DEMO STATE DATA ---
  List<Map<String, dynamic>> _myTickets = [
    {'id': '1001', 'subject': 'POS Printer Not Responding', 'description': 'The thermal printer is not printing receipts even though it is connected via USB.', 'status': 'Open', 'created_at': '18 Sep 2026, 10:30 AM', 'priority': 'High'},
    {'id': '1002', 'subject': 'Add New Staff Seat', 'description': 'I want to upgrade my plan to allow 5 more staff members.', 'status': 'Resolved', 'created_at': '15 Sep 2026, 02:15 PM', 'priority': 'Medium'},
    {'id': '1003', 'subject': 'Sync Error on Offline Node', 'description': 'Local database is not syncing with the cloud since morning.', 'status': 'Urgent', 'created_at': 'Today, 09:00 AM', 'priority': 'High'},
  ];

  List<Map<String, dynamic>> _allMessages = [
    {'ticketId': '1001', 'message': 'Hello, have you tried restarting the printer hub?', 'sender_type': 'Admin', 'created_at': '18 Sep 2026, 11:00 AM'},
    {'ticketId': '1001', 'message': 'Yes, I did that. Still not working.', 'sender_type': 'Tenant', 'created_at': '18 Sep 2026, 11:05 AM'},
    {'ticketId': '1002', 'message': 'Your request has been processed. You can now add more staff.', 'sender_type': 'Admin', 'created_at': '16 Sep 2026, 10:00 AM'},
  ];

  Map<String, dynamic>? _selectedTicket;
  List<Map<String, dynamic>> _activeChatHistory = [];

  @override
  void initState() {
    super.initState();
    // No async loading needed for demo
  }

  void _loadChatHistory(String ticketId) async {
    setState(() => _isChatLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _activeChatHistory = _allMessages.where((m) => m['ticketId'] == ticketId).toList();
      _isChatLoading = false;
    });
  }

  Future<void> _submitTicket() async {
    if (_subjectController.text.isEmpty || _descController.text.isEmpty) {
      _showFeedback("Error", "Please fill all required fields.", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API

    final newId = (1004 + _myTickets.length).toString();
    final newTicket = {
      'id': newId,
      'subject': _subjectController.text.trim(),
      'description': _descController.text.trim(),
      'status': 'Open',
      'created_at': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      'priority': _selectedPriority,
    };

    setState(() {
      _myTickets.insert(0, newTicket);
      _isSubmitting = false;
      _currentView = 1;
      _selectedTicket = newTicket;
      _activeChatHistory = [];
      _subjectController.clear();
      _descController.clear();
    });
    _showFeedback("Success", "Support ticket #$newId has been created.");
  }

  void _handleSendReply() async {
    if (_replyController.text.isEmpty || _selectedTicket == null) return;

    final msgText = _replyController.text.trim();
    final ticketId = _selectedTicket!['id'];

    setState(() {
      final newMsg = {
        'ticketId': ticketId,
        'message': msgText,
        'sender_type': 'Tenant',
        'created_at': 'Just now',
      };
      _allMessages.add(newMsg);
      _activeChatHistory.add(newMsg);
      _replyController.clear();
    });

    // Simulate Admin Auto-Response for demo
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _selectedTicket?['id'] == ticketId) {
      setState(() {
        final autoResponse = {
          'ticketId': ticketId,
          'message': "Thank you for the update. Our technician has been assigned to ticket #$ticketId. We will get back to you shortly.",
          'sender_type': 'Admin',
          'created_at': 'Just now',
        };
        _allMessages.add(autoResponse);
        _activeChatHistory.add(autoResponse);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildNavigationHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentView == 0) _buildHelpHubView()
                  else if (_currentView == 1) _buildTicketCenterView()
                  else if (_currentView == 2) _buildNewTicketView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
          _buildNavItem("HELP HUB", 0),
          _buildNavItem("TICKET CENTER", 1),
          _buildNavItem("NEW REQUEST", 2),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AdminTheme.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.support_agent_rounded, size: 16, color: AdminTheme.royalBlue),
                SizedBox(width: 8),
                Text("Support Status: Active", style: TextStyle(color: AdminTheme.royalBlue, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, int index) {
    bool isSel = _currentView == index;
    return InkWell(
      onTap: () => setState(() => _currentView = index),
      child: Container(
        margin: const EdgeInsets.only(right: 32),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSel ? AdminTheme.royalBlue : Colors.transparent, width: 3))),
        child: Text(label, style: TextStyle(color: isSel ? AdminTheme.royalBlue : Colors.grey, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
      ),
    );
  }

  // --- VIEW 0: HELP HUB ---
  Widget _buildHelpHubView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(),
        const SizedBox(height: 48),
        const Text("DIRECT CHANNELS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2, color: AdminTheme.darkNavy)),
        const SizedBox(height: 24),
        _buildContactChannels(),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AdminTheme.royalBlue, AdminTheme.darkNavy], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AdminTheme.royalBlue.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          const Text("Hello! How can we help you?", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text("Access our 24/7 dedicated support desk and comprehensive knowledge base.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for documentation or troubleshooting guides...", 
                border: InputBorder.none, 
                icon: const Icon(Icons.search, color: AdminTheme.royalBlue),
                suffixIcon: IconButton(onPressed: () => _showFeedback("Search", "Finding articles related to: ${_searchController.text}"), icon: const Icon(Icons.send_rounded, size: 18, color: AdminTheme.royalBlue)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChannels() {
    return Wrap(
      spacing: 24, runSpacing: 24,
      children: [
        _buildChannelCard("24/7 Live Chat", "Chat with AI Specialist", Icons.auto_awesome_rounded, AdminTheme.royalBlue),
        _buildChannelCard("Ticket Portal", "Official support requests", Icons.confirmation_num_rounded, const Color(0xFFFF5C00), onTap: () => setState(() => _currentView = 1)),
        _buildChannelCard("Phone Support", "+977-9800000000", Icons.phone_in_talk_rounded, AdminTheme.emeraldGreen),
        _buildChannelCard("WhatsApp Business", "Quick text support", Icons.message_rounded, const Color(0xFF25D366)),
      ],
    );
  }

  Widget _buildChannelCard(String name, String sub, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _showFeedback("Connecting", "Initializing connection to $name..."),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AdminTheme.softShadow),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[600]))])),
          ],
        ),
      ),
    );
  }

  // --- VIEW 1: TICKET CENTER ---
  Widget _buildTicketCenterView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildTicketListPanel()),
        const SizedBox(width: 32),
        Expanded(flex: 7, child: _selectedTicket == null ? _buildNoSelectionPlaceholder() : _buildChatPanel()),
      ],
    );
  }

  Widget _buildNoSelectionPlaceholder() {
    return Container(
      height: 700,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: AdminTheme.softShadow),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 24),
            const Text("No Ticket Selected", style: TextStyle(color: AdminTheme.darkNavy, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Select a conversation from the left to view history.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => setState(() => _currentView = 2), child: const Text("CREATE NEW REQUEST")),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketListPanel() {
    return Container(
      height: 700,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: AdminTheme.softShadow),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ticket Inbox", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                IconButton(onPressed: () => _showFeedback("Refresh", "Updating ticket list..."), icon: const Icon(Icons.refresh, size: 20, color: AdminTheme.royalBlue)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _myTickets.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 24, endIndent: 24),
              itemBuilder: (ctx, i) {
                final t = _myTickets[i];
                bool isSel = _selectedTicket?['id'] == t['id'];
                return ListTile(
                  onTap: () { setState(() => _selectedTicket = t); _loadChatHistory(t['id']); },
                  selected: isSel,
                  selectedTileColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: CircleAvatar(backgroundColor: _getStatusColor(t['status']).withValues(alpha: 0.1), child: Icon(Icons.confirmation_num_outlined, color: _getStatusColor(t['status']), size: 18)),
                  title: Text(t['subject'], style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
                  subtitle: Text("ID: #${t['id']} • ${t['created_at']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      height: 700,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: AdminTheme.softShadow),
      child: Column(
        children: [
          _buildChatHeader(),
          const Divider(height: 1),
          Expanded(
            child: _isChatLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      _buildMessageBubble(text: _selectedTicket!['description'], isMe: true, subtitle: "Original Issue", isInitial: true),
                      if (_activeChatHistory.isNotEmpty) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text("CHAT HISTORY", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)))),
                        ..._activeChatHistory.map((m) => _buildMessageBubble(text: m['message'], isMe: m['sender_type'] == 'Tenant', subtitle: m['created_at'])),
                      ],
                    ],
                  ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: _getStatusColor(_selectedTicket!['status']).withValues(alpha: 0.1), child: Icon(Icons.shield_outlined, color: _getStatusColor(_selectedTicket!['status']), size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selectedTicket!['subject'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("STATUS: ${_selectedTicket!['status'].toString().toUpperCase()}", style: TextStyle(color: _getStatusColor(_selectedTicket!['status']), fontSize: 11, fontWeight: FontWeight.w900))])),
          IconButton(onPressed: () => _loadChatHistory(_selectedTicket!['id']), icon: const Icon(Icons.refresh, color: AdminTheme.royalBlue)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isMe, required String subtitle, bool isInitial = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isMe ? (isInitial ? const Color(0xFFF1F5F9) : const Color(0xFFFF5C00)) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isMe ? Colors.transparent : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(text, style: TextStyle(fontSize: 15, color: isMe && !isInitial ? Colors.white : AdminTheme.darkNavy, height: 1.5)),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _replyController, onSubmitted: (_) => _handleSendReply(), decoration: InputDecoration(hintText: "Type your message here...", filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)))),
          const SizedBox(width: 16),
          FloatingActionButton(onPressed: _handleSendReply, backgroundColor: const Color(0xFFFF5C00), elevation: 0, child: const Icon(Icons.send_rounded, color: Colors.white)),
        ],
      ),
    );
  }

  // --- VIEW 2: NEW TICKET ---
  Widget _buildNewTicketView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: AdminTheme.softShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Submit Support Request", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AdminTheme.darkNavy)),
            const Text("Our technical team typically responds within 2 business hours.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 48),
            _buildTextField("Issue Subject", _subjectController, "e.g. Printer not printing, Sync error, etc."),
            const SizedBox(height: 24),
            const Text("Priority Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _selectedPriority = v!),
            ),
            const SizedBox(height: 24),
            _buildTextField("Issue Details", _descController, "Provide as much detail as possible to help us solve it faster...", maxLines: 6),
            const SizedBox(height: 48),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSubmitting ? null : _submitTicket, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5C00), padding: const EdgeInsets.symmetric(vertical: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT TICKET NOW", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)))),
          ],
        ),
      ),
    );
  }

  // --- UTILS ---
  Color _getStatusColor(String? status) {
    if (status == 'Open') return Colors.blue;
    if (status == 'Resolved') return Colors.green;
    if (status == 'Urgent') return Colors.red;
    return Colors.orange;
  }

  void _showFeedback(String title, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title: $msg"), backgroundColor: isError ? Colors.red : AdminTheme.royalBlue));
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18))),
      ],
    );
  }
}
