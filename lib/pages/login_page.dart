import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:presto/blocs/auth_bloc.dart';
import 'package:presto/blocs/auth_bloc_provider.dart';
import 'package:presto/constants.dart' as constants;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

enum LoginState { none, card, account }

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _usernameController;
  TextEditingController _cardController;
  TextEditingController _passwordController;

  StreamSubscription<DocumentSnapshot> _loginRequestStream;

  bool loggingIn = false;

  String errorText;

  AnimationController _entranceController;

  LoginState _loginState = LoginState.none;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _cardController = TextEditingController();

    _entranceController = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _entranceController.forward();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    Widget buttonContent;

    if (_loginState == LoginState.none) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: RaisedButton(
              child: Text('PRESTO Account'),
              onPressed: () => setState(() => _loginState = LoginState.account),
            ),
          ),
          Divider(color: Colors.transparent,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: RaisedButton(
              child: Text('PRESTO Card Number'),
              onPressed: () => setState(() => _loginState = LoginState.card),
            ),
          ),
        ],
      );
      buttonContent = Text(
        'P',
        style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
      );
    } else {
      buttonContent = Icon(Icons.arrow_back);

      if(_loginState == LoginState.account) {
        content = _buildLoginAccountForm();
      } else if(_loginState == LoginState.card){
        content = _buildLoginCardForm();
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
              child: AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(Curves.ease.transform(_entranceController.value)),
                child: child,
              );
            },
            child: Container(),
          )),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21.0)),
                elevation: 10.0,
                child: AnimatedSize(
                  alignment: Alignment.topCenter,
                  vsync: this,
                  duration: Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 200),
                            child: buttonContent,
                          ),
                          onPressed: _loginState != LoginState.none
                              ? () {
                                  switch (_loginState) {
                                    case LoginState.account:
                                    case LoginState.card:
                                      setState(() => _loginState = LoginState.none);
                                      break;
                                    case LoginState.none:
                                      break;
                                  }
                                }
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: content,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void doLogin(BuildContext context) async {
    errorText = null;

    if (Form.of(context).validate()) {
      setState(() {
        loggingIn = true;
      });

      Stream<DocumentSnapshot> documentStream;

      if(_usernameController.text.length > 0) {
        documentStream = await AuthBloc.loginWithUsernameAndPassword(_usernameController.text, _passwordController.text);
      } else {
        documentStream = await AuthBloc.loginWithCardNumber(_cardController.text);
      }

      setState(() {
        _loginRequestStream = documentStream.listen((snapshot) {
          if (snapshot.data['success'] == false) {
            setState(() {
              loggingIn = false;
              _loginRequestStream.cancel();
              switch(snapshot['message']) {
                case 'INVALID_CARD_NUMBER':
                  errorText = 'Invalid card number';
                  break;
                case 'ALREADY_LINKED':
                  errorText = 'Card already linked to an account';
                  break;
                default:
                  errorText = 'Invalid credentials';
              }

              _passwordController.clear();
              Form.of(context).validate();
            });
          } else if(snapshot.data['success'] == true){
            _loginRequestStream.cancel();
          }
        });
      });
    }
  }

  Widget _buildLoginAccountForm() {
    return Form(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'PRESTO username'),
              maxLines: 1,
              validator: (value) {
                if (errorText != null) {
                  return errorText;
                }

                if (value.length == 0) {
                  return 'Enter a username';
                }
              },
            ),
            Divider(
              color: Colors.transparent,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              keyboardType: TextInputType.text,
              maxLines: 1,
              decoration: InputDecoration(labelText: 'password'),
              validator: (value) {
                if (errorText != null) {
                  return errorText;
                }

                if (value.length == 0) {
                  return 'Enter a password';
                }
              },
            ),
            Divider(
              color: Colors.transparent,
            ),
            StreamBuilder(
              stream: Observable.just(loggingIn),
              builder: (context, snapshot) {
                if (!loggingIn) {
                  return RaisedButton(
                    child: Text('Log In'),
                    onPressed: () => doLogin(context),
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCardForm() {
    return Form(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _cardController,
              decoration: InputDecoration(labelText: 'PRESTO Card Number'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (errorText != null) {
                  return errorText;
                }

                if (value.length == 0) {
                  return 'Enter a card number';
                }
              },
            ),
            Divider(
              color: Colors.transparent,
            ),
            StreamBuilder(
              stream: Observable.just(loggingIn),
              builder: (context, snapshot) {
                if (!loggingIn) {
                  return RaisedButton(
                    child: Text('Log In'),
                    onPressed: () => doLogin(context),
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _usernameController.dispose();
    _entranceController.dispose();

    _loginRequestStream.cancel();
    super.dispose();
  }
}

class BackgroundPainter extends CustomPainter {
  final double t;

  BackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidthThin = 20.0;
    double strokeWidthThick = 30.0;
    double strokeCompensation = -100.0;

    double extentSmall = 150.0;
    double extentLarge = 200.0;

    Offset offset = Tween<Offset>(begin: Offset(extentLarge, extentLarge), end: Offset.zero).transform(t);

    canvas.drawLine(
        Offset(strokeCompensation, extentSmall) - offset,
        Offset(extentSmall, strokeCompensation) - offset,
        Paint()
          ..color = Colors.lightGreenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidthThin);
    canvas.drawLine(
        Offset(strokeCompensation, extentLarge) - offset,
        Offset(extentLarge, strokeCompensation) - offset,
        Paint()
          ..color = Colors.lightGreenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidthThick);

    canvas.drawLine(
        Offset(size.width - extentSmall, size.height - strokeCompensation) + offset,
        Offset(size.width - strokeCompensation, size.height - extentSmall) + offset,
        Paint()
          ..color = Colors.lightGreenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidthThin);
    canvas.drawLine(
        Offset(size.width - extentLarge, size.height - strokeCompensation) + offset,
        Offset(size.width - strokeCompensation, size.height - extentLarge) + offset,
        Paint()
          ..color = Colors.lightGreenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidthThick);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
