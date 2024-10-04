import 'package:echoes2/screens/post_screen.dart';
import 'package:echoes2/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'favorite_screen.dart';
import 'feed.dart';
import 'search.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;

  List<Widget> pages = [];
  PanelController panelController = PanelController();

  @override
  void initState() {
    super.initState();
    pages = [
      const FeedScreen(),
      const SearchScreen(),
      PostScreen(panelController: panelController),
      const FavoriteScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 224, 224), // Set background color to light grey
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 0,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        panelBuilder: (ScrollController sc) {
          return PostScreen(panelController: panelController);
        },
        body: pages[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Set the background color here
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Adjust the shadow color
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, -3), // Change the offset as needed
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            if (index == 2) {
              panelController.isPanelOpen
                  ? panelController.close()
                  : panelController.open();
            } else {
              panelController.close();
              setState(() {
                selectedIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, color: selectedIndex == 0 ? Colors.black : Colors.grey),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, color: selectedIndex == 1 ? Colors.black : Colors.grey),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 56, // Adjust the width as needed
                height: 56, // Adjust the height as needed
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28), // Circular border radius
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white), // Add icon with white color
                ),
              ),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite, color: selectedIndex == 3 ? const Color.fromARGB(255, 255, 17, 0) : Colors.grey),
              label: 'Favorite',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, color: selectedIndex == 4 ? Colors.black : Colors.grey),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
