import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> readNotification(documentId) async {
  bool newValue = true;

  // Specify your collection and document ID
  String collectionName = 'report';

  // Update specific fields using the update method
  try {
    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(documentId)
        .update({
      'read': newValue,
    });
    // print('Document updated successfully!');
  } catch (error) {
    // print('Failed to update document: $error');
  }
}
