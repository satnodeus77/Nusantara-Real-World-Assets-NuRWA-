import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

@JS('window')
external JSObject get window;

@JS('executeSolanaTransfer')
external JSPromise<JSString> _executeSolanaTransferJS(JSString destination, JSNumber amount);

Future<String?> connectPhantom() async {
  try {
    final JSObject global = window;
    JSObject? solana;

    if (global.hasProperty('solana'.toJS).toDart) {
      solana = global.getProperty('solana'.toJS) as JSObject;
    } else if (global.hasProperty('phantom'.toJS).toDart) {
      final phantom = global.getProperty('phantom'.toJS) as JSObject;
      if (phantom.hasProperty('solana'.toJS).toDart) {
        solana = phantom.getProperty('solana'.toJS) as JSObject;
      }
    }

    if (solana != null) {
      final promise = solana.callMethod('connect'.toJS) as JSPromise;
      final response = await promise.toDart as JSObject;
      
      final pubKeyObj = response.getProperty('publicKey'.toJS) as JSObject;
      final address = pubKeyObj.callMethod('toString'.toJS) as JSString;
      
      final String walletAddress = address.toDart;
      
   
      return walletAddress;
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<String?> sendInvestmentTransaction(double amount, String destination, String sender) async {
  try {
    debugPrint("⏳ Memulai eksekusi transaksi Web ke: $destination");
    
    final jsResult = await _executeSolanaTransferJS(destination.toJS, amount.toJS).toDart;
    final signature = jsResult.toDart;
    
    if (signature == "CANCELLED") {
      debugPrint("Transaksi dibatalkan oleh user atau error.");
      return null;
    }
    
    debugPrint("Transaksi Berhasil! TxHash: $signature");
    return signature; 
    
  } catch (e) {
    debugPrint(" System Error: $e");
    return null;
  }
}