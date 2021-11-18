
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';




enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }


class authService with ChangeNotifier{
  FirebaseAuth _auth;
  FirebaseFirestore _store;
  User? _user;
  Status _status = Status.Uninitialized;
  Set<WordPair> _favorites = Set<WordPair>();
  firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  Set<WordPair> get favorites => _favorites;

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;


  authService.instance(): _auth = FirebaseAuth.instance, _store = FirebaseFirestore.instance{
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }



  Future<Set<WordPair>> getUserFavs() async{
    //get the set
    Set<WordPair> favs = Set<WordPair>();

    await _store.collection("users").doc(_user!.uid).collection('favorites').get().then((QuerySnapshot) {
      QuerySnapshot.docs.forEach((entry) {
        String _firstWord = entry.data().entries.first.value.toString();
        String _secondWord = entry.data().entries.last.value.toString();
        favs.add(WordPair(_firstWord, _secondWord));
      });
    });

    //build the future
    return Future<Set<WordPair>>.value(favs);
  }



  Future<void> removePair(WordPair wordPair) async{
    if(_status == Status.Authenticated) {
      _store.collection('users').doc(_user!.uid).collection('favorites').doc(wordPair.asPascalCase).delete();
    }
    _favorites = await getUserFavs();
    notifyListeners();
  }

  Future<void> insertPair(WordPair wordPair) async{
    if(_status == Status.Authenticated) {
      _store.collection('users').doc(_user!.uid).collection('favorites').doc(wordPair.asPascalCase)
        .set({'first' : wordPair.first, 'second':wordPair.second});
    }
    _favorites = await getUserFavs();
    notifyListeners();
  }





  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _favorites = await getUserFavs();
      notifyListeners();
      _status = Status.Authenticated;
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }


  Future signOut() async {
    _auth.signOut();
    //_user = null; //TODO: should i delete this?
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

 Future<void> uploadImg(File f) async{
   await _storage.ref('images').child(_user!.uid).putFile(f);
   notifyListeners();
 }

 Future<String> getImage() async {
   return await _storage.ref('images').child(_user!.uid).getDownloadURL();
 }

 Future<UserCredential?> signUp(String email,String passWord ) async{
   try{
     _status = Status.Authenticating;
     notifyListeners();
     //sign up and return user credential:
     return await _auth.createUserWithEmailAndPassword(email: email, password: passWord);
   } catch(e){
     print(e);
     _status = Status.Unauthenticated;
     notifyListeners();
     return null;
   }
 }
  getMail(){
    return _user!.email;
  }


}