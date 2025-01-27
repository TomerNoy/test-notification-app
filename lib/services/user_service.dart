import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_notification_app/core/form_validators.dart';
import 'package:test_notification_app/global_providers/user_auth_provider.dart';
import 'package:test_notification_app/models/app_user.dart';

import 'package:test_notification_app/models/result.dart';
import 'package:test_notification_app/services/services.dart';

// this service is responsible for user authentication and user data management
class UserService {
  UserService() {
    _authStateChanges.add(UserAuthState.loading);
    _authChangesSub = _auth
        .authStateChanges()
        .map((user) => user == null
            ? UserAuthState.unauthenticated
            : UserAuthState.authenticated)
        .distinct()
        .listen(_authStateChanges.add);

    _userChangesSub = _auth
        .userChanges()
        .map((user) => user == null ? null : AppUser.fromFirebaseUser(user))
        .distinct()
        .listen(_userChanges.add);

    _authStateChanges.listen(
      (value) {
        loggerService.debug('Auth state changed: $value');
      },
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _userChanges = BehaviorSubject<AppUser?>();
  final _authStateChanges = BehaviorSubject<UserAuthState>();

  late final StreamSubscription<AppUser?> _userChangesSub;
  late final StreamSubscription<UserAuthState> _authChangesSub;

  Stream<AppUser?> get userChanges => _userChanges.stream;
  Stream<UserAuthState> get authStateChanges => _authStateChanges.stream;

  AppUser get currentUser => AppUser.fromFirebaseUser(_auth.currentUser!);

  Future<Result<User>> registerUser(
    String email,
    String firstName,
    String lastName,
    GenderEnum gender,
  ) async {
    try {
      final password = dotenv.env['USER_PASSWORD'];

      _authStateChanges.add(UserAuthState.loading);
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password ?? 'password',
      );
      await userCredential.user!.updateProfile(
        displayName: '$firstName $lastName',
      );

      await _saveUserData(
        firstName: firstName,
        lastName: lastName,
        gender: gender.name,
      );

      await userCredential.user!.reload();
      final updatedUser = _auth.currentUser;
      loggerService.info(
        'User registered with name: ${updatedUser?.displayName}',
      );

      loggerService.info('User registered ${userCredential.user}');

      setAppLifecycleState('user registered resume');

      return Result.success(updatedUser!);
    } on FirebaseAuthException catch (e) {
      loggerService.error('Registration failed', e);
      switch (e.code) {
        case 'email-already-in-use':
          return Result.failure('Email is already in use.');
        case 'invalid-email':
          return Result.failure('Invalid email address.');
        default:
          return Result.failure('Registration failed. Please try again.');
      }
    } catch (e, st) {
      loggerService.error('Registration failed', e, st);
      return Result.failure('Registration failed. Please try again.');
    }
  }

  Future<void> _saveUserData({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      loggerService.error('User is null');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
      });
    } catch (e) {
      loggerService.error('Failed to save user data', e);
    }
  }

  Future<void> signOut() async {
    _authStateChanges.add(UserAuthState.loading);
    final user = _auth.currentUser;
    if (user == null) {
      _authStateChanges.add(UserAuthState.unauthenticated);
      return;
    }

    try {
      final password = dotenv.env['USER_PASSWORD'];

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password ?? 'password',
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      loggerService.error('Reauthentication failed', e);
      _authStateChanges.add(UserAuthState.unauthenticated);
      return;
    }

    await _deleteUserData(user.uid);

    try {
      await user.delete();
    } catch (e, st) {
      loggerService.error('Failed to delete user from Firebase Auth', e, st);
    }
    await _auth.signOut();
  }

  Future<void> _deleteUserData(String userId) async {
    loggerService.info('Deleting user data for userId: $userId');

    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e, st) {
      loggerService.error('Failed to delete user data', e, st);
    }
  }

  Future<void> setAppLifecycleState(String state) async {
    final user = _auth.currentUser;
    if (user == null) {
      loggerService.warning('User is probably not registered');
      return;
    }

    loggerService.debug('Setting app lifecycle state to: $state');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'appLifecycleState': state,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      loggerService.debug("User lifecycle state updated to: $state");
    } catch (error) {
      loggerService.error("Error updating lifecycle state: $error");
    }
  }

  void dispose() {
    _userChangesSub.cancel();
    _authChangesSub.cancel();
  }
}
