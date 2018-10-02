import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url;

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

class _MyHomePageState extends State<MainPage> {



  @override
  void initState() {
    super.initState();

    AuthBloc.updateCards();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
                      child: new Text(
                        '${selectedCard.balance}',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 85.0),
                      ),
                    ),
                  ),
                  Divider(height: 8.0, color: Colors.transparent),
                  Opacity(
                      opacity: 0.6,
                      child: Text(
                        'As of ${utils.dateToShortStringWithTime(selectedCard.lastUpdatedOn)}',
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
}
