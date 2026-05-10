import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool isLoading = true;
  double totalBalance = 0.0;
  double unclaimedYield = 0.0;
  double lifetimeYield = 0.0; 
  List<dynamic> activeAssets =[];

  @override
  void initState() {
    super.initState();
    _loadPortfolioData();
  }

  Future<void> _loadPortfolioData() async {
    final walletAddress = context.read<AppProvider>().walletAddress;
    final data = await ApiService.fetchPortfolio(walletAddress);
    
    if (mounted) {
      setState(() {
        totalBalance = (data['total_balance_usdc'] ?? 0).toDouble();
        unclaimedYield = (data['unclaimed_yield_usdc'] ?? 0).toDouble();
        lifetimeYield = (data['lifetime_yield_usdc'] ?? 0).toDouble(); 
        activeAssets = data['assets'] ??[];
        isLoading = false;
      });
    }
  }


  Future<void> _handleClaimYield() async {
    if (unclaimedYield <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No Yield available. Scroll down and press "Simulate UMKM Revenue" for a demo!'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 3),
        )
      );
      return;
    }

    setState(() => isLoading = true);
    
    final walletAddress = context.read<AppProvider>().walletAddress;
    final claimed = await ApiService.claimYield(walletAddress);
    
    if (mounted) {
      await _loadPortfolioData(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 \$${claimed.toStringAsFixed(2)} USDC Yield Claimed to Wallet!'),
          backgroundColor: const Color(0xFF14F195),
          duration: const Duration(seconds: 4),
        )
      );
    }
  }

  Future<void> _handleEscrowRefund(String umkmId, String umkmName) async {
    setState(() => isLoading = true);
    final walletAddress = context.read<AppProvider>().walletAddress;
    
    final refundedAmount = await ApiService.triggerEscrowRefund(walletAddress, umkmId);
    
    if (mounted) {
      await _loadPortfolioData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🛡️ ESCROW: \$${refundedAmount.toStringAsFixed(2)} USDC from $umkmName returned to your wallet!'),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 5),
        )
      );
      context.read<AppProvider>().loadProjects(); 
    }
  }

  Future<void> _simulateUmkmRevenue() async {
    if (activeAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ You must invest in at least 1 asset first!')));
      return;
    }

    setState(() => isLoading = true);
    final targetUmkmId = activeAssets.first['umkm_id'];
    final targetUmkmName = activeAssets.first['umkm_name'];
    
    final success = await ApiService.triggerOracleYield(targetUmkmId, 500.0);

    if (success) {
      await _loadPortfolioData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🔮 ORACLE: $targetUmkmName is sharing monthly profits!'), backgroundColor: Colors.blueAccent)
        );
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14F195)));
    }

    return RefreshIndicator(
      onRefresh: _loadPortfolioData,
      color: const Color(0xFF14F195),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children:[
          const Text("Portfolio", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors:[Color(0xFF9945FF), Color(0xFF14F195)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow:[BoxShadow(color: const Color(0xFF14F195).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          const Text("Total Invested", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("\$${totalBalance.toStringAsFixed(2)} USDC", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:[
                        const Text("Historical Yield", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("+\$${lifetimeYield.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children:[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          const Text("Unclaimed Yield", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("\$${unclaimedYield.toStringAsFixed(2)} USDC", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: unclaimedYield > 0 ? Colors.white : Colors.white54,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      // 🔥 PERBAIKAN: Tombol selalu bisa dipencet (tidak lagi diset null)
                      onPressed: _handleClaimYield,
                      child: const Text("Claim Yield", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          const Text("Active Assets", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          if (activeAssets.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: Text("No active investments yet. Explore the Marketplace to start funding!", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...activeAssets.map((asset) {
              bool isRefundable = asset['is_refundable'] ?? false;
              return Column(
                children:[
                  _buildAssetItem(
                    asset['umkm_name'] ?? "Unknown", 
                    "${asset['tokens']?.toStringAsFixed(0) ?? 0} RST", 
                    "\$${asset['amount_usdc']?.toStringAsFixed(2) ?? 0}",
                    isRefundable: isRefundable,
                    umkmId: asset['umkm_id']
                  ),
                  const Divider(color: Color(0xFF2A2A2A)),
                ],
              );
            }).toList(),

          const SizedBox(height: 60),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children:[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Icon(Icons.build_circle, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text("Hackathon Demo Tools", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _simulateUmkmRevenue,
                    child: const Text("Simulate UMKM Revenue (Oracle)"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAssetItem(String title, String tokens, String investedAmount, {bool isRefundable = false, String umkmId = ""}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Expanded(
                child: Row(
                  children:[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isRefundable ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF2A2A2A), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Icon(isRefundable ? Icons.warning_amber_rounded : Icons.storefront, 
                        color: isRefundable ? Colors.redAccent : const Color(0xFF14F195)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(isRefundable ? "Campaign Failed" : tokens, 
                            style: TextStyle(color: isRefundable ? Colors.redAccent : Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(investedAmount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (isRefundable) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.shield_rounded, size: 16),
                label: const Text("Claim Refund (Escrow Vault)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _handleEscrowRefund(umkmId, title),
              ),
            ),
          ]
        ],
      ),
    );
  }
}