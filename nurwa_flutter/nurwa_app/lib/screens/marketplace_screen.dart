import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:solana/solana.dart' as solana;
import '../providers/app_provider.dart';
import '../services/solana_service.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14F195)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.projects.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text("Fund Local Growth.", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Text("Earn Real Yield.", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF14F195))),
              ],
            ),
          );
        }
        return _buildPremiumCard(context, provider.projects[index - 1]);
      },
    );
  }

  Widget _buildPremiumCard(BuildContext context, dynamic project) {
    double progress = (project['funded_usdc'] ?? 0) / (project['funding_goal_usdc'] ?? 1);
    bool isFunded = progress >= 1.0;
    
    int daysRemaining = project['days_remaining'] ?? 0;
    bool isExpired = daysRemaining <= 0;
    
    String statusText;
    Color buttonColor;
    bool canInvest = false;

    if (isFunded) {
      statusText = 'Funding Closed (Target Reached)';
      buttonColor = const Color(0xFF2A2A2A);
    } else if (isExpired) {
      statusText = 'Campaign Ended (Goal Missed)';
      buttonColor = Colors.redAccent.withOpacity(0.5);
    } else {
      statusText = 'Invest Now';
      buttonColor = const Color(0xFF14F195);
      canInvest = true;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children:[
              Image.network(project['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children:[
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('${project['apy_percent']}% APY', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.redAccent : const Color(0xFF14F195), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    children:[
                      Icon(Icons.timer, size: 14, color: isExpired ? Colors.white : Colors.black),
                      const SizedBox(width: 4),
                      Text(isExpired ? 'Expired' : '$daysRemaining Days Left', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: isExpired ? Colors.white : Colors.black, fontSize: 12)),
                    ],
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    Expanded(child: Text(project['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(project['description'], style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4)),
                const SizedBox(height: 24),
                LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFF2A2A2A), color: const Color(0xFF9945FF), minHeight: 8, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    Text("\$${project['funded_usdc']} USDC Raised", style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text("${(progress * 100).toInt()}% of Goal", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: canInvest ? Colors.black : Colors.white70,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: canInvest ? () => _showInvestSheet(context, project) : null,
                    child: Text(statusText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showInvestSheet(BuildContext context, dynamic project) {
    final TextEditingController amountController = TextEditingController();
    final String projectId = project['id'].toString(); 
    final String projectName = project['name'];
    final walletAddress = context.read<AppProvider>().walletAddress;

    // 🔥 PROGRAM ID SMART CONTRACT ANDA
    final String programIdString = 'QcoV1YM24NYoWvBeqDgh1AKq3oQXM3ncAnvcVFdW96E';

    Future<String> calculatePDA() async {
      try {
        final programId = solana.Ed25519HDPublicKey.fromBase58(programIdString);
        
        String safeId = projectId;
        if (safeId.length > 8) safeId = safeId.substring(0, 8);
        
        final seeds = <List<int>>[
          utf8.encode("escrow"),
          utf8.encode(safeId),
        ];
        
        final pda = await solana.Ed25519HDPublicKey.findProgramAddress(
          seeds: seeds,
          programId: programId,
        );
        return pda.toBase58();
      } catch (e) {
        debugPrint("[NURWA DEBUG] PDA Calculation Error: $e");
        return project['umkm_wallet_address'] ?? "GQEwybFECdCW6vjRSFMgZhMGu3LZJEvdEejcucaKQ548";
      }
    }

    final Future<String> pdaFuture = calculatePDA();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder( 
        builder: (BuildContext context, StateSetter setModalState) {
          bool isProcessing = false;

          return FutureBuilder<String>(
            future: pdaFuture,
            builder: (context, snapshot) {
              final pdaVaultAddress = snapshot.data ?? "Calculating Vault...";
              final isPdaReady = snapshot.hasData; 

              return Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20, 
                      left: 24, right: 24, top: 24
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF121212),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        // 🔥 UX FIX 1: DITAMBAHKAN TOMBOL CLOSE (X) DI POJOK KANAN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  Text("Invest in $projectName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  const Text("Enter the amount of USDC you wish to invest. Transactions will be processed via Solana Devnet.", style: TextStyle(color: Colors.grey, height: 1.4)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                              onPressed: isProcessing ? null : () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9945FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF9945FF).withOpacity(0.3)),
                          ),
                          child: Row(
                            children:[
                              const Icon(Icons.lock_outline, color: Color(0xFF9945FF), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:[
                                    const Text("Smart Contract Vault (PDA)", style: TextStyle(color: Color(0xFF9945FF), fontSize: 12, fontWeight: FontWeight.bold)),
                                    isPdaReady 
                                      ? InkWell(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: pdaVaultAddress));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✅ PDA Address copied to clipboard!'),
                                                backgroundColor: Color(0xFF9945FF),
                                                duration: Duration(seconds: 2),
                                              )
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              children:[
                                                // 🔥 FIX OVERFLOW: Bungkus Text dengan Expanded & Ellipsis
                                                Expanded(
                                                  child: Text(
                                                    pdaVaultAddress, 
                                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                                                    overflow: TextOverflow.ellipsis, // Menambahkan "..." jika layar sempit
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF14F195)), 
                                              ],
                                            ),
                                          ),
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.only(top: 4.0),
                                          child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9945FF))),
                                        ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          readOnly: isProcessing || !isPdaReady, 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            // 🔥 UX FIX 2: MENGUBAH PREFIXTEXT JADI PREFIXICON AGAR SELALU TAMPIL
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children:[
                                  Text("USDC", style: TextStyle(color: Color(0xFF14F195), fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0A0A0A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9945FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: (isProcessing || !isPdaReady) ? null : () async {
                              if (amountController.text.isEmpty) return;
                              
                              setModalState(() => isProcessing = true);
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              
                              final signature = await SolanaService.invest(amount, pdaVaultAddress, walletAddress);

                              if (signature != null && signature != "CANCELLED") {
                                await ApiService.recordInvestment(
                                  walletAddress: walletAddress,
                                  umkmId: projectId,
                                  umkmName: projectName,
                                  amount: amount,
                                  txHash: signature,
                                );
                                
                                if (mounted) context.read<AppProvider>().loadProjects();
                              }

                              setModalState(() => isProcessing = false);
                              if (sheetContext.mounted) Navigator.pop(sheetContext);

                              if (signature != null && signature != "CANCELLED") {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Success! Funds locked in Escrow.\nSig: ${signature.substring(0, 8)}...'),
                                    backgroundColor: const Color(0xFF14F195),
                                    duration: const Duration(seconds: 5),
                                  )
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('❌ Transaction Failed / Cancelled'), backgroundColor: Colors.redAccent)
                                );
                              }
                            },
                            child: isProcessing 
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:[
                                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                    SizedBox(width: 12),
                                    Text('Processing on Blockchain...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : Text(isPdaReady ? 'Sign & Submit (Phantom)' : 'Loading Vault...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            }
          );
        }
      ),
    );
  }
}