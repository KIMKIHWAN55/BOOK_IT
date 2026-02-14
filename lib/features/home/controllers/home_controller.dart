import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeController extends ChangeNotifier {
  String userName = "";
  bool isLoading = false;

  HomeController() {
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    isLoading = true;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      userName = doc.data()?['name'] ?? "사용자";
    }

    isLoading = false;
    notifyListeners();
  }
}