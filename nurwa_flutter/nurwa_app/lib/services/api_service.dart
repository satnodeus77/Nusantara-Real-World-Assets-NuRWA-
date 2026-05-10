import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class ApiService {
  static const String baseUrl = 'https://nurwa-api.vercel.app/api';

  
  //fixing the list dynamic and add timeout
  static Future<List<dynamic>?> fetchProjects() async {
    try {

      // wait for 10 second, if no conn will throw excep
      final response = await http.get(Uri.parse('$baseUrl/projects')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null; 
    } catch (e) { 
      debugPrint("❌ FETCH FAILED (No Internet / Timeout): $e"); 
      return null; 
    }
  }

  static Future<bool> loginUser(String address) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'wallet_address': address}), 
      );
      if (response.statusCode == 200) return true;
    } catch (e) { debugPrint("❌ LOGIN FAILED: $e"); }
    return true; 
  }

  static Future<bool> recordInvestment({
    required String walletAddress, required String umkmId, required String umkmName, required double amount, required String txHash,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'wallet_address': walletAddress, 'umkm_id': umkmId, 'umkm_name': umkmName, 'amount_usdc': amount, 'tx_hash': txHash,
        }),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> fetchPortfolio(String walletAddress) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/portfolio/$walletAddress'));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) { debugPrint("❌ FETCH PORTFOLIO FAILED: $e"); }
    return {"total_balance_usdc": 0.0, "unclaimed_yield_usdc": 0.0, "lifetime_yield_usdc": 0.0, "assets":[]};
  }

  static Future<double> claimYield(String walletAddress) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/claim-yield'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'wallet_address': walletAddress}),
      );
      if (response.statusCode == 200) {
        return (json.decode(response.body)['claimed'] as num).toDouble();
      }
    } catch (e) { debugPrint("❌ CLAIM YIELD FAILED: $e"); }
    return 0.0;
  }

  static Future<bool> triggerOracleYield(String umkmId, double revenueFiat) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/oracle/distribute-yield'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'umkm_id': umkmId, 'revenue_fiat': revenueFiat}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- NEW: ESCROW REFUND TRIGGER ---
  static Future<double> triggerEscrowRefund(String walletAddress, String umkmId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refund'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'wallet_address': walletAddress, 'umkm_id': umkmId}),
      );
      if (response.statusCode == 200) {
        return (json.decode(response.body)['refunded_amount'] as num).toDouble();
      }
    } catch (e) { debugPrint("❌ ESCROW REFUND FAILED: $e"); }
    return 0.0;
  }
}