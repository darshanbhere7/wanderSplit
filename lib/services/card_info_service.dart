import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_info_model.dart';

class CardInfoService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<CardInfo?> getCardInfo() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).collection('card').doc('main').get();
    if (!doc.exists) return null;
    return CardInfo.fromMap(doc.data()!);
  }

  Stream<CardInfo?> cardInfoStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream<CardInfo?>.empty();
    return _firestore.collection('users').doc(user.uid).collection('card').doc('main').snapshots().map((doc) {
      if (!doc.exists) return null;
      return CardInfo.fromMap(doc.data()!);
    });
  }

  Future<void> setCardInfo(CardInfo cardInfo) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).collection('card').doc('main').set(cardInfo.toMap());
  }
} 