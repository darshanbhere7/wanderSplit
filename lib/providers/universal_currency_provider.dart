import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniversalCurrencyProvider extends ChangeNotifier {
  String _currency = 'INR';
  String get currency => _currency;

  UniversalCurrencyProvider() {
    _fetchCurrency();
  }

  Future<void> _fetchCurrency() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      _currency = doc.data()?['universalCurrency'] ?? 'INR';
      notifyListeners();
    }
  }

  Future<void> setCurrency(String currency) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'universalCurrency': currency});
      _currency = currency;
      notifyListeners();
    }
  }
} 