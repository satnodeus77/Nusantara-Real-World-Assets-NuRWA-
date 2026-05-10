import 'dart:io'; // 🔥 IMPORT INI YANG MENYELESAIKAN ERROR InternetAddress
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:solana/solana.dart' as solana;
import 'package:solana/base58.dart';

String? _cachedAuthToken;


Future<String?> connectPhantom() async {
  LocalAssociationScenario? session;
  try {
    session = await LocalAssociationScenario.create();
    session.startActivityForResult(null).ignore(); 
    
    final client = await session.start();
    final result = await client.authorize(
      identityUri: Uri.parse('https://nurwa.id'),
      iconUri: Uri.parse('favicon.png'),
      identityName: 'NuRWA v2',
      cluster: 'devnet',
    );
    
    if (result != null) {
      _cachedAuthToken = result.authToken;
      final walletAddress = base58encode(result.publicKey);
      debugPrint("[NURWA DEBUG] ✅ Login Sukses (FULL ADDRESS): $walletAddress");
      return walletAddress;
    }
    return null;
  } catch (e) {
    debugPrint("[NURWA DEBUG] 🚨 ERROR LOGIN: $e");
    return null;
  } finally {
    try { await session?.close(); } catch (_) {}
  }
}


Future<String?> sendInvestmentTransaction(double amount, String destinationWallet, String senderWallet) async {
  debugPrint("\n[NURWA DEBUG] =========================================");
  debugPrint("[NURWA DEBUG] ⏳ MEMULAI TRANSAKSI: $amount USDC");
  debugPrint("[NURWA DEBUG] 🔹 DARI: $senderWallet");
  debugPrint("[NURWA DEBUG] 🔹 KE  : $destinationWallet");

  LocalAssociationScenario? session;

  try {
    final senderPubKeyObj = solana.Ed25519HDPublicKey.fromBase58(senderWallet);
    final receiverPubKeyObj = solana.Ed25519HDPublicKey.fromBase58(destinationWallet); 

    int lamports = (amount * 1000000).toInt(); 
    if (lamports < 890880) {
      lamports += 890880;
    }

    final instruction = solana.SystemInstruction.transfer(
      fundingAccount: senderPubKeyObj,
      recipientAccount: receiverPubKeyObj,
      lamports: lamports,
    );

    debugPrint("[NURWA DEBUG] Mengambil Blockhash Devnet...");
    final rpcUrl = 'https://api.devnet.solana.com';
    final rpcClient = solana.RpcClient(rpcUrl);
    
    final latestBlockhash = await rpcClient.getLatestBlockhash(
      commitment: solana.Commitment.confirmed, 
    );
    debugPrint("[NURWA DEBUG] 🔹 Blockhash didapat: ${latestBlockhash.value.blockhash}");

    final message = solana.Message(instructions: [instruction]);
    final compiledMessage = message.compile(
      recentBlockhash: latestBlockhash.value.blockhash,
      feePayer: senderPubKeyObj,
    );

    final messageBytes = compiledMessage.toByteArray().toList();
    final txBytes = Uint8List.fromList([
      1, 
      ...List.filled(64, 0), 
      ...messageBytes
    ]);

    debugPrint("[NURWA DEBUG] Membuka Tunnel ke Phantom...");
    session = await LocalAssociationScenario.create();
    session.startActivityForResult(null).ignore();
    
    final client = await session.start();
    debugPrint("[NURWA DEBUG] Tunnel MWA Terbuka");
    
    bool isAuthorized = false;
    if (_cachedAuthToken != null) {
      try {
        final reauthResult = await client.reauthorize(
          identityUri: Uri.parse('https://nurwa.id'),
          iconUri: Uri.parse('favicon.png'),
          identityName: 'NuRWA v2',
          authToken: _cachedAuthToken!,
        );
        if (reauthResult != null) {
          isAuthorized = true;
          debugPrint("[NURWA DEBUG] Re-auth sukses dengan token lama!");
        }
      } catch(e) {
        debugPrint("[NURWA DEBUG] Token lama kedaluwarsa/hilang. Meminta auth baru...");
      }
    }

    if (!isAuthorized) {
      final authResult = await client.authorize(
        identityUri: Uri.parse('https://nurwa.id'),
        iconUri: Uri.parse('favicon.ico'),
        identityName: 'NuRWA v2',
        cluster: 'devnet',
      );
      if (authResult == null) {
        debugPrint("[NURWA DEBUG] GAGAL: User menolak auth ulang di Phantom.");
        return null;
      }
      _cachedAuthToken = authResult.authToken;
      debugPrint("[NURWA DEBUG] 🔹 Otorisasi Baru Sukses!");
    }

    debugPrint("[NURWA DEBUG] ✍️ Meminta Phantom menandatangani transaksi");
    
    final result = await client.signTransactions(
      transactions: [txBytes],
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint("[NURWA DEBUG] 🚨 TIMEOUT: Phantom tidak merespons.");
        throw Exception("Phantom Timeout");
      },
    );
    
    if (result.signedPayloads.isNotEmpty) {
      final signedBytes = result.signedPayloads.first;
      debugPrint("[NURWA DEBUG] Tanda Tangan Phantom BERHASIL didapat");
      
      final base64Tx = base64.encode(signedBytes);


      debugPrint("[NURWA DEBUG] Memutuskan Tunnel Phantom agar DNS Android kembali normal");
      try { await session?.close(); session = null; } catch (_) {}

      // Pemanasan (Warm-up) DNS secara paksa sebelum mengirim data
      debugPrint("[NURWA DEBUG] Memancing jaringan OS Android ");
      for (int w = 0; w < 3; w++) {
        try {
          await InternetAddress.lookup('api.devnet.solana.com');
          debugPrint("[NURWA DEBUG] Jaringan Android siap");
          break; 
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }

      debugPrint("[NURWA DEBUG] Aplikasi Flutter Broadcasting Manual ke RPC Devnet");
      
      int maxRetries = 3;
      bool isBroadcastSuccess = false;
      String? finalTxHash;

      for (int i = 0; i < maxRetries; i++) {
        try {
          final rpcResponse = await http.post(
            Uri.parse(rpcUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "jsonrpc": "2.0",
              "id": 1,
              "method": "sendTransaction",
              "params":[
                base64Tx,
                {"encoding": "base64", "preflightCommitment": "confirmed"}
              ]
            }),
          ).timeout(const Duration(seconds: 15));
          
          final jsonResponse = json.decode(rpcResponse.body);
          
          if (jsonResponse['result'] != null) {
            finalTxHash = jsonResponse['result'];
            isBroadcastSuccess = true;
            break; 
          } else {
            debugPrint("[NURWA DEBUG] Error RPC: ${jsonResponse['error']}");
          }
        } catch (e) {
          debugPrint("[NURWA DEBUG] HTTP Error (Percobaan ${i + 1}/$maxRetries). Menunggu 2 detik...");
          if (i == maxRetries - 1) throw e; 
          await Future.delayed(const Duration(seconds: 2)); 
        }
      }

      if (isBroadcastSuccess && finalTxHash != null) {
        debugPrint("[NURWA DEBUG]  TRANSAKSI FULL SUKSES: $finalTxHash");
        debugPrint("[NURWA DEBUG] =========================================\n");
        return finalTxHash;
      } else {
        debugPrint("[NURWA DEBUG]  GAGAL BROADCAST SETELAH SEMUA PERCOBAAN.");
        debugPrint("[NURWA DEBUG] =========================================\n");
        return null;
      }

    } else {
      debugPrint("[NURWA DEBUG]  GAGAL: Payload tanda tangan kosong.");
      return null;
    }

  } catch (e, stackTrace) {
    debugPrint("[NURWA DEBUG]  CATCH ERROR: $e");
    return null;
  } finally {
    if (session != null) {
      try { await session?.close(); } catch (_) {}
    }
  }
}