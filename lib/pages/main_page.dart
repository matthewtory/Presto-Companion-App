import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart' as url;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:presto/blocs/auth_bloc_provider.dart';
import 'package:presto/blocs/auth_bloc.dart';
import 'package:presto/models/card_model.dart';
import 'package:presto/widgets/app_bar_menu.dart';
import 'package:presto/widgets/cards_app_bar_menu.dart';
import 'package:presto/widgets/history_app_bar_menu.dart';
import 'package:presto/utils.dart' as utils;
import 'package:presto/constants.dart' as constants;

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MainPage> with SingleTickerProviderStateMixin {
  bool updating = true;
  String updateMessage;

  StreamSubscription<DocumentSnapshot> updateCardsSubscription;

  AnimationController balanceController;
  Animation<double> balanceAnimation;

  @override
  void initState() {
    super.initState();

    AuthBloc.updateCards().then((stream) {
      if (updateCardsSubscription != null) {
        updateCardsSubscription.cancel();
      }

      updateCardsSubscription = stream.listen(_onUpdateCardStatusReceived);
    });
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    balanceController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    balanceController.forward();
    balanceAnimation = CurvedAnimation(parent: Tween<double>(begin: 0.1, end: 1.0).animate(balanceController), curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    balanceController.addStatusListener((status) {
      if (updating) {
        switch (status) {
          case (AnimationStatus.completed):
            balanceController.reverse();
            break;
          case (AnimationStatus.dismissed):
            balanceController.forward();
            break;
          default:
        }
      } else {
        balanceController.forward();
      }
    });
  }

  void _onUpdateCardStatusReceived(DocumentSnapshot snapshot) {
    if (snapshot['success'] != null) {
      bool success = snapshot['success'];

      if (!success) {
        updateMessage = snapshot['message'] ?? 'Error Updating Card';
      } else {
        updateMessage = null;
      }
      setState(() {
        updating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: StreamBuilder<CardModel>(
        stream: AuthBlocProvider.of(context).selectedCard,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: _buildCardPage(context, snapshot.data),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingActionButton(context),
      bottomNavigationBar: _buildBottomAppBar(context),
    );
  }

  Widget _buildCardPage(BuildContext context, CardModel selectedCard) {
    String statusText;

    if (updating) {
      statusText = 'Updating Card...';
    } else {
      statusText = updateMessage ?? 'As of ${utils.dateToShortStringWithTime(selectedCard.lastUpdatedOn)}';
    }

    return SafeArea(
      key: ValueKey<String>(selectedCard.number),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DefaultTextStyle(
              style: Theme.of(context).textTheme.title,
              child: Text(
                '${selectedCard.name}',
                style: TextStyle(fontSize: 32.0),
              ),
            ),
            Divider(color: Colors.transparent),
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 5.0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18.0)),
              ),
              child: Stack(
                fit: StackFit.loose,
                children: <Widget>[
                  Image.asset("assets/presto-card.png"),
                  Positioned(
                      left: 16.0,
                      bottom: 16.0,
                      child: Text(
                        selectedCard.number,
                        style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white),
                      ))
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.display4,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: balanceController,
                        builder: (context, widget) {
                          return Opacity(
                            opacity: balanceController.value,
                            child: widget,
                          );
                        },
                        child: Text(
                          '${selectedCard.balance}',
                          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 85.0),
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 8.0, color: Colors.transparent),
                  Opacity(
                      opacity: 0.6,
                      child: Text(
                        statusText,
                        textAlign: TextAlign.center,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return new FloatingActionButton.extended(
      onPressed: () {
        url.launch(constants.kPrestoCardReloadPage, forceSafariVC: true);
      },
      tooltip: 'Reload',
      icon: Icon(Icons.add),
      label: Text('Reload Card'),
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => utils.showAppBarMenu(
                  context,
                  (context, value) {
                    return BottomAppBarMenuCard(
                      child: CardsBottomAppBarMenu(),
                      value: value,
                    );
                  },
                ),
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => utils.showAppBarMenu(
                  context,
                  (context, value) {
                    return BottomAppBarMenuCard(
                      child: HistoryAppBarMenu(),
                      value: value,
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    updateCardsSubscription.cancel();
    super.dispose();
  }
}
