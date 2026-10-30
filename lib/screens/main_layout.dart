import 'package:flutter/material.dart';
import 'dashboard_overview.dart';
import 'home.dart';
import 'own_bowser_bill.dart';
import 'transporters_screen.dart';
import 'login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // IMPORTANT: This cannot be 'const' because we pass a callback closure.
  late final List<Widget> _screens = [
    // Pass the callback to switch tabs from the Dashboard Quick Actions
    DashboardOverview(
      onNavigate: (index) {
        setState(() => _selectedIndex = index);
      },
    ),
    const BillMakingApp(),
    const OwnBowserBillScreen(),
    const TransportersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF121212);

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // ==========================================
          // PERMANENT SIDEBAR
          // ==========================================
          Container(
            width: 260,
            color: const Color(0xFF181818),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // LOGO SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        width: 40,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.local_gas_station, color: Colors.deepPurple, size: 40),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'CHIRAG GAS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // NAVIGATION MENU
                _buildSidebarItem(0, Icons.dashboard, 'Dashboard'),
                _buildSidebarItem(1, Icons.receipt_long, 'Normal Bills'),
                _buildSidebarItem(2, Icons.local_shipping, 'Bowser Bills'),
                _buildSidebarItem(3, Icons.people_alt, 'Transporters'),
                
                const Spacer(),
                
                // LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // DYNAMIC CONTENT AREA
          // ==========================================
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isActive = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: isActive ? Colors.deepPurple.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: isActive ? Colors.deepPurple.shade300 : const Color(0xFF888888), size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF888888),
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}