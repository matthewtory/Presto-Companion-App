import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:presto/constants.dart' as constants;
import 'package:presto/models/auth_model.dart';
import 'package:presto/models/card_model.dart';
import 'package:presto/models/card_transaction_model.dart';

class AuthBloc {
  BehaviorSubject<AuthModel> _authSubject;
  BehaviorSubject<List<CardModel>> _cardsSubject;
  BehaviorSubject<List<CardTransactionModel>> _historySubject;
  BehaviorSubject<CardModel> _selectedCardSubject;

  Sink<DocumentReference> get setSelectedCard => _activeCardStreamController.sink;

  Observable<AuthModel> get auth => _authSubject.stream;
  Observable<List<CardModel>> get cards => _cardsSubject.stream;
  Observable<List<CardTransactionModel>> get selectedCardHistory => _historySubject.stream;
  Observable<CardModel> get selectedCard => _selectedCardSubject.stream;

  StreamController<DocumentReference> _activeCardStreamController;
  StreamController<DocumentSnapshot> _userDocumentStreamController;

  StreamSubscription<QuerySnapshot> _cardsSubscription;
  StreamSubscription<QuerySnapshot> _historySubscription;
  StreamSubscription<DocumentSnapshot> _selectedCardSubscription;
  StreamSubscription<DocumentSnapshot> _userDocumentSubscription;

  AuthBloc() {
    _authSubject = BehaviorSubject<AuthModel>();
    _cardsSubject = BehaviorSubject<List<CardModel>>();
    _historySubject = BehaviorSubject<List<CardTransactionModel>>();
    _selectedCardSubject = BehaviorSubject<CardModel>();

    _activeCardStreamController = StreamController<DocumentReference>();

    BehaviorSubject<FirebaseUser> firebaseUserSubject = BehaviorSubject<FirebaseUser>();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) => firebaseUserSubject.add(user));

    Observable<DocumentSnapshot> _userInfoStream = firebaseUserSubject.flatMap((user) {
      if (user == null) return Observable.just(null);
      if (_userDocumentStreamController != null) {
        _userDocumentStreamController.close();
      }

      _userDocumentStreamController = StreamController<DocumentSnapshot>();

      return _documentStream(_userDocumentStreamController, user);
    });

    Observable<AuthModel> _authModel = Observable.combineLatest2(
      firebaseUserSubject,
      _userInfoStream,
      (user, userDocument) {
        String username, password, cardNumber;
        bool validLogin;
        int numCards;

        if (userDocument != null && user != null) {
          username = userDocument[constants.kUsernameKey];
          password = userDocument[constants.kPasswordKey];
          validLogin = userDocument[constants.kValidLoginKey];
          numCards = userDocument[constants.kNumCardsKey];
          cardNumber = userDocument[constants.kCardNumberKey];
        } else {
          username = null;
          password = null;
        }

        return AuthModel(user, validLogin, numCards, username: username, password: password, cardNumber: cardNumber);
      },
    );

    _authModel.listen((model) {
      _authSubject.add(model);

      if (model.user == null || !model.isLoggedIn()) return;

      if (_cardsSubscription != null) {
        _cardsSubscription.cancel();
        _cardsSubscription = null;
      }

      if (model.numCards == 0) {
        _cardsSubject.add([CardModel(balance: null, name: null, number: null, lastUpdatedOn: null, ref: null)]);
      } else {
        _cardsSubscription =
            Firestore.instance.collection('cards').where('uid', isEqualTo: model.user.uid).snapshots()
                .listen((querySnapshot) {
          _cardsSubject.add(querySnapshot.documents.map((document) {
            return CardModel(
                balance: document['balance'],
                name: document['card_name'],
                lastUpdatedOn: document['last_updated_on'],
                number: document['card_number'],
                ref: document.reference);
          }).toList());

          if (querySnapshot.documents.length > 0) {
            setSelectedCard.add(querySnapshot.documents.first.reference);
          }
        });
      }
    });

    _activeCardStreamController.stream.listen((cardRef) {
      if (_historySubscription != null) {
        _historySubscription.cancel();
      }

      if (_selectedCardSubscription != null) {
        _selectedCardSubscription.cancel();
        _selectedCardSubscription = null;
      }

      _selectedCardSubscription = cardRef.snapshots().listen((card) {
        _selectedCardSubject.add(CardModel(
            balance: card['balance'],
            name: card['card_name'],
            number: card['card_number'],
            lastUpdatedOn: card['last_updated_on'],
            ref: card.reference));
      });

      _historySubscription = cardRef.collection('history').snapshots().listen((historySnapshot) {
        _historySubject.add(historySnapshot.documents.map((item) {
          return new CardTransactionModel(
              amount: item['amount'],
              agency: item['agency'],
              location: item['location'],
              type: item['type'],
              balance: item['balance'],
              date: item['date']);
        }).toList());
      });
    });
  }

  Future<void> signOut() async {
    if(_cardsSubscription != null) {
      await _cardsSubscription.cancel();
    }

    if(_historySubscription != null) {
      await _historySubscription.cancel();
    }

    if(_userDocumentStreamController != null) {
      await _userDocumentStreamController.close();
    }

    if(_selectedCardSubscription != null) {
      await _selectedCardSubscription.cancel();
    }

    if(_userDocumentSubscription != null) {
      await _userDocumentSubscription.cancel();
    }

    return FirebaseAuth.instance.signOut();
  }

  static Future<Stream<DocumentSnapshot>> loginWithUsernameAndPassword(String username, String password) async {
    FirebaseUser user = await FirebaseAuth.instance.signInAnonymously();
    DocumentSnapshot userDocument = await _getUserDocumentStreamRetry(user);

    await userDocument.reference.updateData({
      constants.kUsernameKey: username,
      constants.kPasswordKey: password,
      constants.kCardNumberKey: null,
      constants.kValidLoginKey: false,
    });

    return Firestore.instance
        .collection('requests')
        .add({'request': 'login', 'uid': user.uid}).then((reference) => reference.snapshots());
  }

  static Future<Stream<DocumentSnapshot>> loginWithCardNumber(String number) async {
    FirebaseUser user = await FirebaseAuth.instance.signInAnonymously();
    DocumentSnapshot userDocument = await _getUserDocumentStreamRetry(user);

    await userDocument.reference.updateData({
      constants.kCardNumberKey: number,
      constants.kValidLoginKey: false,
      constants.kUsernameKey: null,
      constants.kPasswordKey: null,
    });

    return Firestore.instance
        .collection('requests')
        .add({'request': 'login', 'uid': user.uid}).then((reference) => reference.snapshots());
  }

  static Future<Stream<DocumentSnapshot>> updateCards() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();

    return Firestore.instance
        .collection('requests')
        .add({'request': 'update_cards', 'uid': user.uid}).then((reference) => reference.snapshots());
  }

  static Future<DocumentSnapshot> _getUserDocumentStreamRetry(FirebaseUser user) {
    return Firestore.instance
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .firstWhere((querySnapshot) {
          return querySnapshot.documents.length > 0;
        })
        .then((querySnapshot) {
          return querySnapshot.documents.first;
        });
  }

  Observable<DocumentSnapshot> _documentStream(StreamController<DocumentSnapshot> streamController, FirebaseUser user) {
    Future<Stream<DocumentSnapshot>> documentStreamFuture = _getUserDocumentStream(user);
    documentStreamFuture.then((documentStream) {
      if(_userDocumentSubscription != null) {
        _userDocumentSubscription.cancel();
      }

      _userDocumentSubscription = documentStream.listen((snapshot) => streamController.add(snapshot));
    });

    return Observable(streamController.stream);
  }

  Future<Stream<DocumentSnapshot>> _getUserDocumentStream(FirebaseUser user) {
    return _getUserDocumentStreamRetry(user).then((snapshot) => snapshot.reference.snapshots());
  }
}
