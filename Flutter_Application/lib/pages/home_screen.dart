import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'notification_screen.dart';
import 'qa_screen.dart';
import 'wating_screen.dart';
import '../consts.dart'; // Import the global notifier for report flag

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late final PlatformWebViewController _controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Delay initialization until after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebViewController(); // Initialize the WebView controller
      _initializeReportFlagListener(); // Initialize report flag listener
      _getAllDocuments(); // Retrieve Firestore documents on initialization
      setState(() {
        isInitialized = true;
      });
    });
  }

  // Function to initialize the WebView controller
  void _initializeWebViewController() {
    _controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    )..loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
              'http://192.168.1.108:5000/'), // Replace with your live stream URL
        ),
      );
  }

  // Function to initialize the listener for 'reportFlag/flag' document changes
  void _initializeReportFlagListener() {
    FirebaseFirestore.instance
        .collection('reportFlag')
        .doc('flag')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        bool updatedFlag =
            (snapshot.data() as Map<String, dynamic>)['flag'] ?? false;
        if (mounted) {
          setState(() {
            globalNewReportNotifier.value =
                updatedFlag; // Update the global notifier
          });
        }
        print(
            "Updated globalNewReportNotifier value in MainScreen: ${globalNewReportNotifier.value}");
      }
    });
  }

  // Function to retrieve all documents from 'report' collection
  Future<void> _getAllDocuments() async {
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

      if (mounted) {
        setState(() {
          dataRetriveFlag = true;
        });
      }
    } catch (e) {
      print("Error retrieving documents: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const WatingScreen();
    }

    return dataRetriveFlag
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Violence Detection'),
              centerTitle: true,
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.question_answer),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QAScreen(),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: globalNewReportNotifier,
                  builder: (context, bool newReportValue, _) {
                    return IconButton(
                      icon: Icon(
                        newReportValue
                            ? Icons.notifications_active
                            : Icons.notifications,
                        color: newReportValue ? Colors.red : Colors.black,
                      ),
                      onPressed: () {
                        dataRetriveFlag = false;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center content vertically
                children: [
                  const Text(
                    'Camera Livestream',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth:
                              800, // Optional: Limit the width for better alignment
                          maxHeight:
                              600, // Optional: Limit the height for better alignment
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors
                              .black, // Background color for the livestream widget
                          borderRadius:
                              BorderRadius.circular(12.0), // Rounded corners
                          border: Border.all(
                              color: Colors
                                  .blueAccent), // Border for visual separation
                        ),
                        child: PlatformWebViewWidget(
                          PlatformWebViewWidgetCreationParams(
                            controller: _controller,
                          ),
                        ).build(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const WatingScreen();
  }
}
