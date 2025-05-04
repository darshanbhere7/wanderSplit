import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'trips';

  // ... existing code ...

  // Delete a trip and all its associated expenses
  Future<void> deleteTrip(String tripId) async {
    try {
      final tripRef = _firestore.collection(_collection).doc(tripId);
      
      // Get all expenses for this trip
      final expensesSnapshot = await tripRef.collection('expenses').get();
      
      // Delete all expenses in a batch
      final batch = _firestore.batch();
      for (var doc in expensesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the trip
      batch.delete(tripRef);
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting trip: $e');
      rethrow;
    }
  }
} 