import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardModel {
  String balance;
  String name;
  String number;
  DateTime lastUpdatedOn;
  DocumentReference ref;

  CardModel(
      {@required this.balance,
      @required this.name,
      @required this.number,
      @required this.lastUpdatedOn,
      @required this.ref});

  operator ==(Object other) {
    if (other is CardModel) {
      return other.balance == balance &&
          other.name == name &&
          other.number == number &&
          other.lastUpdatedOn == lastUpdatedOn &&
          other.ref.path == ref.path;
    }

    return false;
  }
}
