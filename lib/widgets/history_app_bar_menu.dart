import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';

import 'package:presto/widgets/app_bar_menu.dart';
import 'package:presto/blocs/auth_bloc_provider.dart';
import 'package:presto/models/card_transaction_model.dart';
import 'package:presto/constants.dart' as constants;
import 'package:presto/utils.dart' as utils;

class HistoryAppBarMenu extends StatefulWidget {
  @override
  _HistoryAppBarMenuState createState() => _HistoryAppBarMenuState();
}

class _HistoryAppBarMenuState extends State<HistoryAppBarMenu> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CardTransactionModel>>(
        stream: AuthBlocProvider.of(context).selectedCardHistory,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          Map<DateTime, List<CardTransactionModel>> transactionsOnMonths = Map<DateTime, List<CardTransactionModel>>();
          snapshot.data.forEach((transaction) {
            DateTime month = utils.dateToMonth(transaction.date);

            if (transactionsOnMonths[month] == null) {
              transactionsOnMonths[month] = List<CardTransactionModel>();
            }

            transactionsOnMonths[month].add(transaction);
          });

          transactionsOnMonths
              .forEach((month, transactions) => transactions.sort((a, b) => a.date.isBefore(b.date) ? 1 : -1));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: transactionsOnMonths.keys.map((month) {
              return StickyHeader(
                header: Container(
                  height: 50.0,
                  color: Theme.of(context).primaryColor,
                  padding: new EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerLeft,
                  child: new Text(
                    constants.kMonths[month.month - 1],
                    style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
                  ),
                ),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: transactionsOnMonths[month]
                        .map((transaction) => _buildTransactionWidget(context, transaction))
                        .toList(),
                  ),
                ),
              );
            }).toList(),
          );
        });
  }

  Widget _buildTransactionWidget(BuildContext context, CardTransactionModel transaction) {
    Widget locationColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          transaction.location,
          style: Theme.of(context).textTheme.body2.copyWith(fontSize: 16.0),
        ),
        Divider(
          height: 4.0,
          color: Colors.transparent,
        ),
        Text(
          utils.dateToShortStringWithTime(transaction.date),
          style: Theme.of(context).textTheme.body1.copyWith(fontSize: 12.0),
        )
      ],
    );

    Widget balanceColumn = Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          _buildTransactionDescriptionText(transaction),
          Divider(
            height: 4.0,
            color: Colors.transparent,
          ),
          Text(
            transaction.balance,
            style: Theme.of(context).textTheme.body1.copyWith(fontSize: 12.0),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              locationColumn,
              Expanded(child: balanceColumn),
            ],
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildTransactionDescriptionText(CardTransactionModel transaction) {
    if (transaction.type == "Fare Payment") {
      return Text(
        '-${transaction.amount}',
        style: Theme.of(context).textTheme.body2.copyWith(fontSize: 15.0, color: Colors.red),
      );
    } else if (transaction.type == "Load Amount") {
      return Text(
        '+${transaction.amount}',
        style: Theme.of(context).textTheme.body2.copyWith(fontSize: 15.0, color: Colors.green),
      );
    } else {
      return Text(
        '${transaction.type}',
        style: Theme.of(context).textTheme.body2.copyWith(fontSize: 15.0),
      );
    }
  }
}
