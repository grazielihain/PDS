import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/datasources/admin_remote_data_source.dart';

// Fonte única do datasource admin — injetado nas tabs via ref.read/watch
final adminDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
    auth: FirebaseAuth.instance,
  );
});
