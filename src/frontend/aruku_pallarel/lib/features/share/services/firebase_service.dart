import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
