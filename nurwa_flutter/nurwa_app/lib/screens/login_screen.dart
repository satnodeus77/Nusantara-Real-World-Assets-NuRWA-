import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  // --- NEW: Auto-Redirect if already logged in ---
  Future<void> _checkExistingSession() async {
    final provider = context.read<AppProvider>();
    await provider.initSession();
    
    if (provider.isWalletConnected && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  void _handleLogin(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final success = await provider.connectAndLogin();
    
    if (success && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } else if (context.mounted && !provider.isWalletConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const[
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Oops! We do not find Phantom Wallet. Make sure the extension or apps is installed and try again.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _requestApkEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'developer@nurwa.id',
      query: 'subject=Request NuRWA Android APK&body=Halo NuRWA Team, mohon kirimkan file APK-nya ya. Terima kasih!',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint("Could not launch email client");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650), 
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:[Color(0xFF050505), Color(0xFF0A0A0A)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children:[
                  const SizedBox(height: 20),
                  
                  // 1. HERO SECTION 
                  Center(
                    child: Column(
                      children:[
                        // 🔥 GANTI BAGIAN INI DENGAN LOGO ANDA
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow:[BoxShadow(color: const Color(0xFF14F195).withOpacity(0.15), blurRadius: 40, spreadRadius: 10)],
                          ),
                          // Gunakan Image.asset memanggil logo Anda
                          child: Image.asset(
                            'assets/images/logo_icon.png', 
                            width: 100, 
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text("NuRWA", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        const Text("Nusantara Real World Assets", style: TextStyle(color: Color(0xFF14F195), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // 2. APA ITU NURWA & TUJUAN
                  const Text("About Platform", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.storefront_rounded,
                    title: "What is NuRWA?",
                    description: "NuRWA is a Web3 investment platform democratizing funding access for Indonesian MSMEs (Micro, Small, and Medium Enterprises) through Revenue-Sharing Tokens.",
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.rocket_launch_rounded,
                    title: "Our Mission",
                    description: "Bridging the \$150 Billion credit gap for local MSMEs while providing retail investors with stable, transparent USDC yields.",
                  ),
                  const SizedBox(height: 40),

                  // 3. FEATURED OPPORTUNITIES 
                  const Text("Featured Opportunities", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:[
                        _buildMiniProjectCard("Kedai Kopi Senja", "Yogyakarta", "500 USDC", "12%", 0.6),
                        const SizedBox(width: 16),
                        _buildMiniProjectCard("Bakmi Jawa Sleman", "Sleman", "1,000 USDC", "14%", 1.0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 4. CARA KERJA 
                  const Text("How It Works", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStepItem("1", "Connect & Fund", "Connect your Phantom Wallet and fund it with Devnet USDC."),
                  _buildStepItem("2", "Choose UMKM", "Buy Revenue-Share Tokens (RST) from strictly curated local businesses."),
                  _buildStepItem("3", "Claim Returns", "Receive automatic profit sharing from the Smart Contract directly to your wallet."),
                  const SizedBox(height: 40),

                  // 5. TRUST SIGNALS
                  _buildInfoCard(
                    icon: Icons.security_rounded,
                    title: "Security & Transparency",
                    description: "All ownership records are immutably stored on Solana. Profit distribution runs automatically via Smart Contracts, without any third-party interference.",
                  ),
                  const SizedBox(height: 40),

                  // 6. CONNECT WALLET BUTTON 
                  Center(
                    child: SizedBox(
                      width: 350, 
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9945FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 10,
                          shadowColor: const Color(0xFF9945FF).withOpacity(0.5),
                        ),
                        onPressed: isLoading ? null : () => _handleLogin(context),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:[
                                  Icon(Icons.account_balance_wallet, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text("Connect Phantom Wallet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 7. FRICTIONLESS MOBILE BRIDGE
                  if (kIsWeb) ...[
                    const Divider(color: Color(0xFF1E1E1E), thickness: 2),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF1E1E1E)),
                      ),
                      child: Row(
                        children:[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: QrImageView(
                              data: "https://github.com/satnodeus77/Nusantara-Real-World-Assets-NuRWA-/tree/main/APK", 
                              version: QrVersions.auto,
                              size: 90.0,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                const Text("NuRWA is Built for Mobile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                const SizedBox(height: 6),
                                const Text("Scan QR code for native deep-linking in Android. (For iOS, coming soon)", style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)),
                                const SizedBox(height: 12),
                    
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFF14F195).withOpacity(0.2), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(number, style: const TextStyle(color: Color(0xFF14F195), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniProjectCard(String title, String location, String target, String apy, double progress) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF14F195).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(location, style: const TextStyle(color: Color(0xFF14F195), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Row(
                children:[
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(apy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text("Target: $target", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFF2A2A2A), color: const Color(0xFF9945FF), minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 8),
          Text("${(progress * 100).toInt()}% Funded", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Row(
            children:[
              Icon(icon, color: const Color(0xFF14F195), size: 28),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}