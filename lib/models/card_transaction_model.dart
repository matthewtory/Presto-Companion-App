import 'package:flutter/material.dart';

class CardTransactionModel {
  String amount;
  String agency;
  String location;
  String type;
  String balance;
  DateTime date;

  CardTransactionModel({@required this.amount, @required this.agency, @required this.location, @required this.type, @required this.balance, @required this.date});
}