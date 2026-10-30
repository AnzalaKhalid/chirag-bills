import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class DashboardOverview extends StatefulWidget {
  // Callback to change the tab in MainLayout
  final Function(int) onNavigate; 

  const DashboardOverview({super.key, required this.onNavigate});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  int _normalBillsCount = 0;
  int _bowserBillsCount = 0;
  int _transportersCount = 0;
  double _totalRevenue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final bills = await DatabaseHelper().getBills();
      final bowserBills = await DatabaseHelper().getBowserBills();
      final transporters = await DatabaseHelper().getTransporters();

      double revenue = 0;
      for (var b in bills) {
        revenue += b.toPay;
      }
      for (var b in bowserBills) {
        revenue += (b.totalRent + b.primeMoverRent);
      }

      if (mounted) {
        setState(() {
          _normalBillsCount = bills.length;
          _bowserBillsCount = bowserBills.length;
          _transportersCount = transporters.length;
          _totalRevenue = revenue;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark mode colors
    const Color bgColor = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);
    const Color textColor = Colors.white;
    const Color subTextColor = Color(0xFFAAAAAA);
    const Color borderColor = Color(0xFF2C2C2C);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
                const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ==========================================
            // KPI STAT CARDS
            // ==========================================
            Row(
              children: [
                _buildStatCard(
                  title: 'Total Normal Bills',
                  value: '$_normalBillsCount',
                  icon: Icons.receipt,
                  color: Colors.blue,
                  bgColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(width: 24),
                _buildStatCard(
                  title: 'Total Bowser Bills',
                  value: '$_bowserBillsCount',
                  icon: Icons.local_shipping,
                  color: Colors.orange,
                  bgColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(width: 24),
                _buildStatCard(
                  title: 'Active Transporters',
                  value: '$_transportersCount',
                  icon: Icons.people,
                  color: Colors.teal,
                  bgColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(width: 24),
                _buildStatCard(
                  title: 'Total Revenue',
                  value: 'Rs. ${_totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  bgColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ==========================================
            // QUICK ACTIONS SECTION
            // ==========================================
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HoverActionTile(
                    title: 'Create Normal Bill',
                    subtitle: 'Manage transport trips, loading/unloading and gain/loss.',
                    icon: Icons.receipt_long,
                    color: Colors.deepPurple,
                    bgColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    onTap: () => widget.onNavigate(1), // Switch to Normal Bills tab
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _HoverActionTile(
                    title: 'Create Own Bowser Bill',
                    subtitle: 'Create direct delivery bills for your own fleet.',
                    icon: Icons.local_shipping,
                    color: Colors.orange,
                    bgColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    onTap: () => widget.onNavigate(2), // Switch to Bowser Bills tab
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _HoverActionTile(
                    title: 'Manage Transporters',
                    subtitle: 'Add transporters, view ledgers and manage accounts.',
                    icon: Icons.people_alt,
                    color: Colors.teal,
                    bgColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    onTap: () => widget.onNavigate(3), // Switch to Transporters tab
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- KPI STAT CARD WIDGET ---
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HOVER EFFECT WIDGET FOR ACTION TILES ---
class _HoverActionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onTap;

  const _HoverActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.onTap,
  });

  @override
  State<_HoverActionTile> createState() => _HoverActionTileState();
}

class _HoverActionTileState extends State<_HoverActionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.color.withValues(alpha: 0.6) : widget.borderColor,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                    ? widget.color.withValues(alpha: 0.15) 
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 32, color: widget.color),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.subTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Open Module',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(_isHovered ? 6 : 0, 0, 0),
                    child: Icon(Icons.arrow_forward, color: widget.color, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}