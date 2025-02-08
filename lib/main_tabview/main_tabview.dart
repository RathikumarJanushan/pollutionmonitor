import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pollutionmonitor/common/color_extension.dart';
import 'package:pollutionmonitor/common_widget/tab_button.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pollutionmonitor/wellcome/home.dart'; // Ensure Notification API is set up

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selctTab = 2;
  PageStorageBucket storageBucket = PageStorageBucket();
  Widget selectPageView = WelcomeView();

  @override
  void initState() {
    super.initState();
    _listenToFirestoreUpdates();
  }

  void _listenToFirestoreUpdates() {
    // Replace this with the actual method to get the logged-in user's ID
    final loggedInUserId = FirebaseAuth.instance.currentUser?.uid;
    // e.g., FirebaseAuth.instance.currentUser?.uid;

    FirebaseFirestore.instance
        .collection('updates') // Firestore collection name
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final updatedData = change.doc.data();

          // Compare the userId in Firestore with the logged-in user's ID
          if (updatedData?['userid'] == loggedInUserId) {
            final title = updatedData?['title'] ?? 'Update';
            final body = updatedData?['body'] ?? 'Data has been updated.';
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(bucket: storageBucket, child: selectPageView),
      backgroundColor: const Color.fromARGB(255, 61, 60, 60),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            if (selctTab != 2) {
              selctTab = 2;
              selectPageView = WelcomeView();
            }
            if (mounted) {
              setState(() {});
            }
          },
          shape: const CircleBorder(),
          backgroundColor: selctTab == 2 ? TColor.primary : TColor.placeholder,
          child: Image.asset(
            "assets/img/tab_home.png",
            width: 30,
            height: 30,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 21, 14, 14),
        surfaceTintColor: Colors.black,
        shadowColor: Colors.black54,
        elevation: 2,
        notchMargin: 12,
        height: 64,
        shape: const CircularNotchedRectangle(),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [],
          ),
        ),
      ),
    );
  }
}
