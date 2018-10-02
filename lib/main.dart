import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';


import 'package:presto/blocs/auth_bloc_provider.dart';
import 'package:presto/models/auth_model.dart';
import 'package:presto/models/card_model.dart';
import 'package:presto/blocs/auth_bloc.dart';
import 'package:presto/pages/login_page.dart';
import 'package:presto/pages/entry_page.dart';
import 'package:presto/pages/main_page.dart';


void main() => runApp(new MyApp(
      authBloc: new AuthBloc(),
    ));

class MyApp extends StatelessWidget {
  AuthBloc authBloc;

  MyApp({@required this.authBloc});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AuthBlocProvider(
      bloc: authBloc,
      child: new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.green,
            accentColor: Colors.lightGreenAccent,
            buttonColor: Colors.lightGreenAccent,
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.normal,
              height: 42.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21.0)),
            )),
        home: AuthController(),
      ),
    );
  }
}

class AuthController extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new StreamBuilder<AuthModel>(
      stream: AuthBlocProvider.of(context).auth,
      builder: (context, snapshot) {
        Widget child = null;

        if (!snapshot.hasData) {
          child = EntryPage();
        } else if(!snapshot.data.isLoggedIn()) {
          child = LoginPage();
        }else {
          child = MainPage();
        }

        return AnimatedSwitcher(
          child: child,
          duration: Duration(milliseconds: 500),
        );
      },
    );
  }
}
