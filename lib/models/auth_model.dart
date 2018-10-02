import 'package:firebase_auth/firebase_auth.dart';

class AuthModel {
  FirebaseUser user;

  String username;
  String password;

  String cardNumber;

  bool validLogin;

  int numCards;

  AuthModel(this.user, this.validLogin, this.numCards, {this.username, this.password, this.cardNumber});

  bool isLoggedIn() {
    return user != null && ((username != null && password != null) || cardNumber != null)  && validLogin;
  }
}