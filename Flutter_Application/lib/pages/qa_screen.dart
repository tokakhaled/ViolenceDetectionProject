import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QAScreen extends StatelessWidget {
  const QAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Q&A'),
      ),
      body: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages =
      []; // List of messages and images
  final TextEditingController _controller = TextEditingController();
  int _queryCount = 0;
  Stream<DocumentSnapshot>?
      _queryListener; // Stream to listen for document changes

  @override
  void initState() {
    super.initState();
    _initializeQueryCount();
    _loadMessagesFromFirestore(); // Load messages when the screen is initialized
  }

  // Load messages from Firestore when initializing the screen
  Future<void> _loadMessagesFromFirestore() async {
    try {
      // Retrieve all messages from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .orderBy('timestamp')
          .get();

      setState(() {
        // Add each message from Firestore to the local _messages list
        for (var doc in querySnapshot.docs) {
          _messages.add(doc.data() as Map<String, dynamic>);
        }
      });
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  // Initialize query count based on the number of documents in the 'queries' collection
  Future<void> _initializeQueryCount() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('queries').get();
      setState(() {
        _queryCount =
            querySnapshot.docs.isNotEmpty ? querySnapshot.docs.length : 0;
        print("Query count initialized to: $_queryCount");
      });
    } catch (e) {
      print("Error initializing query count: $e");
    }
  }

  // Function to send a message and store it in Firestore
  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      // Create a user message and add it to the chat
      final userMessage = {
        'type': 'user',
        'message': _controller.text,
        'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
      };
      setState(() {
        _messages.add(userMessage);
      });

      // Save the user's message to Firestore in the 'messages' collection
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .add(userMessage);
      } catch (e) {
        print("Error saving user message to Firestore: $e");
      }

      // Increment the query count for unique document ID
      _queryCount++;
      String documentName = "user_${_queryCount}_query";

      try {
        await FirebaseFirestore.instance
            .collection('queries')
            .doc(documentName)
            .set({
          'query': _controller.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Set up a listener to wait for the response field to be updated
        _waitForResponse(documentName, _controller.text);
      } catch (e) {
        print("Error sending message: $e");
      }

      _controller.clear(); // Clear the input field after sending the message
    }
  }

  // Function to set up a listener on the specific document until the 'response' field is found
  void _waitForResponse(String documentName, String userQuery) {
    _queryListener = FirebaseFirestore.instance
        .collection('queries')
        .doc(documentName)
        .snapshots(); // Use snapshots to listen for real-time changes

    _queryListener!.listen((documentSnapshot) async {
      if (documentSnapshot.exists) {
        Map<String, dynamic> documentData =
            documentSnapshot.data() as Map<String, dynamic>;

        if (documentData.containsKey('response')) {
          // Retrieve image names from the 'response' field and update the chat
          List<String> imageNames = List<String>.from(documentData['response']);
          List<Map<String, String>> imageUrlsAndDescriptions = [];

          for (String imageName in imageNames) {
            String imageUrl = await _getImageUrlFromStorage(imageName);
            String description =
                _extractDescriptionFromImageName(imageName, userQuery);
            imageUrlsAndDescriptions.add({
              'url': imageUrl,
              'description': description,
            });
          }

          // Create a system message containing the image descriptions and URLs
          final responseMessage = {
            'type': 'response',
            'image_data': imageUrlsAndDescriptions,
            'timestamp':
                FieldValue.serverTimestamp(), // Add a timestamp for ordering
          };

          setState(() {
            _messages.add(responseMessage);
          });

          // Save the response message to Firestore in the 'messages' collection
          try {
            await FirebaseFirestore.instance
                .collection('messages')
                .add(responseMessage);
          } catch (e) {
            print("Error saving response message to Firestore: $e");
          }

          // Cancel the listener once the response is found
          _queryListener = null;
        } else {
          print("Field 'response' not found in the document. Waiting...");
        }
      } else {
        print("Document not found in 'queries' collection.");
      }
    });
  }

  // Function to extract date, time, and violence percentage from image name and format a description
  String _extractDescriptionFromImageName(String imageName, String userQuery) {
    RegExp regex = RegExp(
        r'frame_(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2}-\d{2})_violence_([\d.]+)\.png');
    Match? match = regex.firstMatch(imageName);

    if (match != null) {
      String date = match.group(1) ?? 'Unknown date';
      String time = match.group(2)?.replaceAll('-', ':') ?? 'Unknown time';
      String violencePercentage = match.group(3) ?? '0.0';

      return '''$userQuery found on $date at $time, and the violence percentage was $violencePercentage%.''';
    } else {
      return 'Invalid image name format.';
    }
  }

  // Function to get the image URL from Firebase Storage using the image name
  Future<String> _getImageUrlFromStorage(String imageName) async {
    try {
      String filePath = 'frames/$imageName';
      String imageUrl =
          await FirebaseStorage.instance.ref(filePath).getDownloadURL();
      print("Download URL: $imageUrl");
      return imageUrl;
    } catch (e) {
      print("Error getting image URL: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display the chat messages
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        // Text field and send button for new queries
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter your question...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Function to build a chat message bubble
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isUserMessage = message['type'] == 'user';
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue[100] : Colors.grey[200],
          borderRadius: isUserMessage
              ? const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                  bottomLeft: Radius.circular(12.0),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                  bottomRight: Radius.circular(12.0),
                ),
        ),
        child: message.containsKey('image_data')
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...message['image_data'].map<Widget>((imageData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          imageData[
                              'description'], // Show the description for each image
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14.0),
                        ),
                        const SizedBox(height: 8.0),
                        Image.network(
                          imageData['url'],
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              'Error loading image: $error',
                              style: const TextStyle(color: Colors.red),
                            );
                          },
                        ),
                        const SizedBox(
                            height: 16.0), // Add spacing between each image
                      ],
                    );
                  }).toList(),
                ],
              )
            : Text(
                message['message'], // Display user message text here
                style: const TextStyle(fontSize: 16.0),
              ),
      ),
    );
  }
}
