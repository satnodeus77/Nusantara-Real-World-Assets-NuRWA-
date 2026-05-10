import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/solana_service.dart';

class AppProvider with ChangeNotifier {
  String _walletAddress = "";
  bool _isWalletConnected = false;
  bool _isLoading = false;
  bool _hasError = false; // 🔥 STATE BARU UNTUK DETEKSI INTERNET MATI
  List<dynamic> _projects =[];

  String get walletAddress => _walletAddress;
  bool get isWalletConnected => _isWalletConnected;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError; // 🔥 GETTER BARU
  List<dynamic> get projects => _projects;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWallet = prefs.getString('wallet_address');
    
    if (savedWallet != null && savedWallet.isNotEmpty) {
      _walletAddress = savedWallet;
      _isWalletConnected = true;
      notifyListeners();
    }
  }

  Future<bool> connectAndLogin() async {
    _isLoading = true;
    notifyListeners();

    final address = await SolanaService.connectWallet();
    
    if (address != null) {
      final success = await ApiService.loginUser(address);
      if (success) {
        _walletAddress = address;
        _isWalletConnected = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wallet_address', address);
      }
    }

    _isLoading = false;
    notifyListeners();
    return _isWalletConnected;
  }

  Future<void> loadProjects() async {
    _isLoading = true;
    _hasError = false; // Reset error state
    notifyListeners();

    final result = await ApiService.fetchProjects();

    if (result == null) {
      // 🔥 JIKA NULL (TIDAK ADA INTERNET), SET ERROR JADI TRUE
      _hasError = true;
      _projects =[];
    } else {
      _hasError = false;
      _projects = result;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _walletAddress = "";
    _isWalletConnected = false;
    _projects =[];
    _hasError = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wallet_address');
    
    notifyListeners();
  }
}