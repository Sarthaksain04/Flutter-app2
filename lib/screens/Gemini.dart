import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import the image picker package
import 'dart:io'; // For handling file types
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For JSON encoding and decoding

class Gemini extends StatefulWidget {
  const Gemini({super.key});

  @override
  State<Gemini> createState() => _GeminiState();
}

class _GeminiState extends State<Gemini> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // List to store the messages and images
  File? _image; // Variable to hold the picked image
  final String apiKey = 'AIzaSyC3LsPAj4TEhIcv6IXwPPvnFXH_KnsCTpU'; 
  // Function to interact with the Gemini API
  Future<String> _callGeminiAPI(String prompt) async {
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key={apiKey}'; // Replace with your Gemini API endpoint
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey', // Use the stored API key here
      },
      body: json.encode({
        'prompt': prompt,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Assuming the response contains a 'response' field with the bot's reply
      return responseData['response'] ?? 'No response from Gemini';
    } else {
      throw Exception('Failed to communicate with Gemini API');
    }
  }

  // Function to add the typed message and image to the list and clear the text field
  void _sendMessage() async {
    if (_controller.text.isNotEmpty || _image != null) {
      setState(() {
        // Add the message and image to the list as a map
        _messages.add({
          'text': _controller.text,
          'image': _image,
        });
      });

      // Call the Gemini API with the input text
      try {
        String geminiResponse = await _callGeminiAPI(_controller.text);
        // Add the response from the API to the messages list
        setState(() {
          _messages.add({
            'text': geminiResponse,
            'image': null,
          });
        });
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

      _controller.clear(); // Clear the text field after sending
      _image = null; // Clear the image after sending
    }
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path); // Set the image file
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Bar with Echoes Bot text
          const Padding(
            padding: EdgeInsets.only(top: 40.0), // Adjust the top padding as needed
            child: Center(
              child: Text(
                'Echoes Bot',
                style: TextStyle(
                  fontSize: 24.0, // Adjust text size
                  fontWeight: FontWeight.bold, // Bold text style
                  color: Colors.black, // Black color for the text
                ),
              ),
            ),
          ),

          // Expanded content area to display the messages
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length, // Count only the messages
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end, // Align messages to the right
                    children: [
                      // Display text message
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent, // Background color for the messages
                          borderRadius: BorderRadius.circular(20), // Rounded corners
                        ),
                        child: Text(
                          _messages[index]['text'] ?? '', // Display the message text
                          style: const TextStyle(color: Colors.white), // White text color for messages
                        ),
                      ),
                      const SizedBox(height: 8), // Space between text and image
                      // Display image if available
                      if (_messages[index]['image'] != null) 
                        Container(
                          width: 200, // Set a fixed width for the image
                          height: 200, // Set a fixed height for the image
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8), // Rounded corners for the image
                            image: DecorationImage(
                              image: FileImage(_messages[index]['image']), // Display the selected image
                              fit: BoxFit.cover, // Cover the entire area
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Text input box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Image Icon on the left (with image picking functionality)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800], // Background color for the icon
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _pickImage, // Call the image picker function
                    icon: const Icon(Icons.image),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),

                // Expanded Text Field with fixed size
                Expanded(
                  child: Container(
                    height: 50, // Fixed height for the text field
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Background color of the text box
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                    child: Row(
                      children: [
                        // Display selected image inside the text box if available
                        if (_image != null)
                          Container(
                            width: 40, // Width of the image inside the text field
                            height: 40, // Height of the image inside the text field
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8), // Rounded corners for the image
                              image: DecorationImage(
                                image: FileImage(_image!), // Display the selected image
                                fit: BoxFit.cover, // Cover the entire area
                              ),
                            ),
                          ),
                        const SizedBox(width: 8), // Space between image and text field
                        // Text Field
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.black), // Black text color
                            decoration: const InputDecoration(
                              hintText: 'Enter a prompt...',
                              hintStyle: TextStyle(color: Colors.grey), // Grey hint text
                              border: InputBorder.none, // No border line
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send Button
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.purple, // Purple background for the button
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage, // Call send message function
                    icon: const Icon(Icons.arrow_upward),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // White background
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: Gemini(),
  ));
}
