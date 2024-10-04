import 'package:flutter/material.dart';

class ViewScreen extends StatelessWidget {
  const ViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate responsive font sizes based on screen width
    double screenWidth = MediaQuery.of(context).size.width;
    double titleFontSize = screenWidth * 0.06; // 6% of screen width
    double bodyFontSize = screenWidth * 0.045; // 4.5% of screen width for better readability

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: Text(
          'Schedule',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Center the title within the AppBar
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 50),
            const Text(
              'No scheduled posts yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'When you schedule the post, it automatically posts at the date and time you choose',
              style: TextStyle(
                fontSize: 19,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            OutlinedButton(
              onPressed: () {
                // Navigating back to the PostScreen page
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text(
                'Schedule',
                style: TextStyle(color: Colors.blue), // Blue text for 'Schedule'
              ),
            ),
          ],
        ),
      ),
    );
  }
}
