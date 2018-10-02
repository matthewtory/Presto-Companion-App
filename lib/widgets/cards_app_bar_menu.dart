import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'package:presto/widgets/app_bar_menu.dart';
import 'package:presto/blocs/auth_bloc_provider.dart';
import 'package:presto/blocs/auth_bloc.dart';
import 'package:presto/models/auth_model.dart';
import 'package:presto/models/card_model.dart';

class CardsBottomAppBarMenu extends StatefulWidget {
  @override
  _MainBottomAppBarMenuState createState() => _MainBottomAppBarMenuState();
}

class _MainBottomAppBarMenuState extends State<CardsBottomAppBarMenu> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthModel>(
      stream: AuthBlocProvider.of(context).auth,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data.isLoggedIn()) return CircularProgressIndicator();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildTopRow(context, snapshot.data),
            Divider(),
            _buildCardsListHeader(context),
            _buildCardsList(context),
          ],
        );
      },
    );
  }

  Widget _buildTopRow(BuildContext context, AuthModel authModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            child: Text(
              'P',
              style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(authModel.username ?? authModel.cardNumber, style: Theme.of(context).textTheme.subhead),
          ),
          Expanded(
              child: Container(
            child: IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () async {
                await AppBarMenuController.of(context).hideAppBarMenu();

                await AuthBlocProvider.of(context).signOut();
              },
            ),
            alignment: Alignment.centerRight,
          )),
        ],
      ),
    );
  }

  Widget _buildCardsListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Text(
        'Cards',
        style: Theme.of(context).textTheme.title,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildCardsList(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: Observable.combineLatest2(AuthBlocProvider.of(context).selectedCard, AuthBlocProvider.of(context).cards,
          (selected, cards) {
        return [selected, cards];
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data[1].length == 0) return Center(child: CircularProgressIndicator());

        CardModel selectedCard = snapshot.data[0];
        List<CardModel> cards = snapshot.data[1];

        return Padding(
          padding: const EdgeInsets.only(left: 32.0, bottom: 32.0, top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards.map((card) {
              return FlatButton(
                  onPressed: () {
                    AuthBlocProvider.of(context).setSelectedCard.add(card.ref);
                    AppBarMenuController.of(context).hideAppBarMenu();
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(21.0), bottomLeft: Radius.circular(21.0))),
                  color: selectedCard == card ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                  splashColor: Theme.of(context).accentColor.withOpacity(0.4),
                  child: Container(
                    child: Text(
                      card.name ?? card.number,
                      textAlign: TextAlign.left,
                    ),
                    alignment: Alignment.centerLeft,
                  ));
            }).toList(),
          ),
        );
      },
    );
  }
}
