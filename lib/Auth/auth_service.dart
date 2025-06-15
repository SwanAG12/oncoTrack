import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailandPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      
      await _firestore.collection('patients').doc(cred.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return cred.user;
    } catch (e, stacktrace) {
      log("Failed to create user: $e");
      log("Stacktrace: $stacktrace");
      return null;
    }
  }

  



  Future<User?> loginWithEmailandPassword(String email, String password) async {
  try {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  } catch (e, stacktrace) {
    log("Failed to login: $e");
    log("Stacktrace: $stacktrace");
    return null;
  }
}


  Future<void> signout()async{
    try{_auth.signOut();}
    catch(e){
      log("Something went wrong");}
  }
  
}