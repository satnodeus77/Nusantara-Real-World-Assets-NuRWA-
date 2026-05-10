import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'marketplace_screen.dart';
import 'portfolio_screen.dart';
import 'login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final List<Widget> _screens = const[MarketplaceScreen(), PortfolioScreen()];

  void _handleLogout(BuildContext context) {
    context.read<AppProvider>().logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final walletAddress = context.watch<AppProvider>().walletAddress;
    
    // 🔥 PERBAIKAN: Kita potong stringnya di sini khusus untuk UI Header saja!
    final displayAddress = walletAddress.length > 8 
        ? "${walletAddress.substring(0, 4)}...${walletAddress.substring(walletAddress.length - 4)}"
        : walletAddress;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            appBar: AppBar(
              centerTitle: false,
              backgroundColor: const Color(0xFF0A0A0A),
              elevation: 0,
              title: const Text('NuRWA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
              actions:[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF14F195).withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children:[
                      const Icon(Icons.circle, color: Color(0xFF14F195), size: 10),
                      const SizedBox(width: 8),
                      // Tampilkan string yang sudah dipotong
                      Text(displayAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  tooltip: 'Log Out',
                  onPressed: () => _handleLogout(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _screens[_currentIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              backgroundColor: const Color(0xFF0A0A0A),
              indicatorColor: const Color(0xFF14F195).withOpacity(0.2),
              destinations: const[
                NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore, color: Color(0xFF14F195)), label: 'Discover'),
                NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart, color: Color(0xFF14F195)), label: 'Portfolio'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}