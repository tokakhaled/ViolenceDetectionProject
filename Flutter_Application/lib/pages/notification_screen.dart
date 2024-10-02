import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tessst/functions/date_string.dart';
import 'package:tessst/functions/retrive_data.dart';
import '../consts.dart';
import 'report_screen.dart';
import 'home_screen.dart';
import 'wating_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Stream<DocumentSnapshot> _reportFlagStream;

  @override
  void initState() {
    super.initState();
    _initializeReportFlagListener();
    getAllDocuments();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Function to initialize the listener for 'reportFlag/flag' document changes
  void _initializeReportFlagListener() {
    _reportFlagStream = FirebaseFirestore.instance
        .collection('reportFlag')
        .doc('flag')
        .snapshots();

    _reportFlagStream.listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        bool updatedFlag =
            (snapshot.data() as Map<String, dynamic>)['flag'] ?? false;
        globalNewReportNotifier.value = updatedFlag;
        print(
            "Updated globalNewReportNotifier value in NotificationScreen: ${globalNewReportNotifier.value}");
      } else {
        print("No data found for 'reportFlag/flag' document.");
      }
    });
  }

  // Function to retrieve all documents from 'report' collection
  Future<void> getAllDocuments() async {
    try {
      String collectionName = 'report';

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('date', descending: true)
          .get();

      allDocuments.clear();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> documentData = doc.data() as Map<String, dynamic>;
        documentData['id'] = doc.id;
        allDocuments.add(documentData);
      }

      setState(() {
        dataRetriveFlag = true;
      });

      print(
          "Documents retrieved successfully. Total documents: ${allDocuments.length}");
    } catch (e) {
      print("Error retrieving documents: $e");
    }
  }

  // Function to reset the 'flag' value in Firestore to false when notification is clicked
  Future<void> resetReportFlag() async {
    try {
      await FirebaseFirestore.instance
          .collection('reportFlag')
          .doc('flag')
          .update({'flag': false});
      globalNewReportNotifier.value = false;
      print("Report flag reset to false.");
    } catch (e) {
      print("Error resetting report flag: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            dataRetriveFlag = true;
            globalNewReportNotifier.value = false;
            resetReportFlag(); // Reset the flag in Firestore
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Notifications'),
        actions: [
          // Listen to globalNewReportNotifier and update the notification icon color
          ValueListenableBuilder(
            valueListenable: globalNewReportNotifier,
            builder: (context, bool newReportValue, _) {
              return IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: newReportValue ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  globalNewReportNotifier.value = false;
                  resetReportFlag(); // Reset the flag in Firestore
                },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: globalNewReportNotifier,
        builder: (context, bool newReportValue, _) {
          return dataRetriveFlag
              ? Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: allDocuments.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.grey[200],
                            child: ListTile(
                              onTap: () {
                                dataRetriveFlag = false;
                                readNotification(allDocuments[index]["id"]);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportScreen(
                                      index: index,
                                    ),
                                  ),
                                );
                              },
                              leading: const Icon(Icons.report),
                              title: Text(
                                  "Violence Detection Report #${allDocuments.length - index}"),
                              subtitle: Text(
                                date2string(
                                  allDocuments[index]["date"],
                                ),
                              ),
                              trailing: allDocuments[index]["read"]
                                  ? null
                                  : const Icon(
                                      Icons.new_releases_outlined,
                                      color: Colors.red,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const WatingScreen();
        },
      ),
    );
  }
}
