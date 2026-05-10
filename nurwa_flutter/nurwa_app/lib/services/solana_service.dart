import 'solana_service_stub.dart'
    if (dart.library.html) 'solana_service_web.dart'
    if (dart.library.io) 'solana_service_mobile.dart';

class SolanaService {
  static Future<String?> connectWallet() async {
    return await connectPhantom(); 
  }

  // Tambahkan parameter ke-3: sender
  static Future<String?> invest(double amount, String destination, String sender) async {
    return await sendInvestmentTransaction(amount, destination, sender);
  }
}