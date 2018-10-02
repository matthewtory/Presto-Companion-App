import 'package:flutter/material.dart';
import 'auth_bloc.dart';

class AuthBlocProvider extends InheritedWidget {
  final AuthBloc bloc;

  AuthBlocProvider({Key key, @required this.bloc, Widget child})
      : super(key: key, child: child);

  bool updateShouldNotify(_) => true;

  static AuthBloc of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(AuthBlocProvider) as AuthBlocProvider).bloc;
  }
}
