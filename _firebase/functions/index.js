
'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');


const axios = require('axios');
const axiosCookieJarSupport = require('axios-cookiejar-support').default;
const { getAPIWrapperWithAxiosInstance } = require('presto-card-js-isomorphic');
const moment = require('moment-timezone');

admin.initializeApp();
admin.firestore().settings({timestampsInSnapshots:true});


exports.createUser = functions.auth.user().onCreate((user, context) => {
    const uid = user.uid;

    return admin.firestore().collection('users').doc(user.uid).create({
        'uid': uid,
    });
});

exports.handleRequest = functions.firestore.document('requests/{request}').onCreate((snapshot, context) => {
    const axiosInstance = axiosCookieJarSupport(axios);
    axiosInstance.defaults.jar = true;
    
    if(snapshot.get('request') === 'update_cards') {
        return updateCards(axiosInstance, snapshot.get('uid')).then((cards) => {
            console.log('success');
            return snapshot.ref.update({success: true});
        }).catch((reason) => {
            console.log('failed', reason.message, reason.stack);
            return snapshot.ref.update({success: false, message: reason.message});
        });
    } else if(snapshot.get('request') === 'login') {
        const uid = snapshot.get('uid');

        return login(axiosInstance, uid).then((response) => {
            console.log('login response: ', response);
            return snapshot.ref.update({success: response});
        }).catch((reason) => {
            console.log('failure:', reason.message);
            return snapshot.ref.update({success: false, message: reason.message});
        });
    }

    return Promise.resolve();
});

function loginWithUsernameAndPassword(axiosInstance, username, password) {
    console.log('logging in: ', username, password);
    const prestoCard = getAPIWrapperWithAxiosInstance(axiosInstance);

    return prestoCard.login.call(axiosInstance, username, password).then((response) => {
        console.log(response);
        return Promise.resolve(response);
    });
}

function loginWithCardNumber(axiosInstance, cardNumber) {
    const prestoCard = getAPIWrapperWithAxiosInstance(axiosInstance);

    return prestoCard.loginWithCardNumber.call(axiosInstance, cardNumber).then((response) => {
        return Promise.resolve(response);
    });
}

function login(axiosInstance, uid) {
    return getUserDocument(uid).then((doc) => {
        let promise = null;
        if(doc.get('presto_username') === 'test' && doc.get('presto_password') === 'test') {
            promise = loginWithUsernameAndPassword(axiosInstance, '', '');
        } else if(doc.get('presto_username') !== null) {
            promise = loginWithUsernameAndPassword(axiosInstance, doc.get('presto_username'), doc.get('presto_password'));
        } else {
            promise = loginWithCardNumber(axiosInstance, doc.get('presto_card_number'));
        }

        return Promise.all([doc.ref.path, promise]);
    }).then(([path, response]) => {
        return Promise.all([response, admin.firestore().doc(path).update({
            presto_valid_login: response.success,
        })]);
    }).then(([response, writeResult]) => {
        if(response.success) {
            return Promise.resolve(response.success);
        }

        return Promise.reject(new Error(response.errorCode));
    });
}

function getUserDocument(uid) {
    return admin.firestore().collection('users').where('uid', '==', uid).get().then((querySnapshot) => {
        if(querySnapshot.empty) return Promise.reject(new Error('User does not exist'));
        return querySnapshot.docs[0];
    });
}

function updateCards(axiosInstance, uid) {
    const prestoCard = getAPIWrapperWithAxiosInstance(axiosInstance);

    return login(axiosInstance, uid).then((success) => {
        if(!success) return Promise.reject(new Error('Could not log in.'));
        
        return prestoCard.getCards.call(axiosInstance);
    }).then((cards) => {
        return Promise.all(cards.map((card) => {
            return fetchCardInfo(axiosInstance, card);
        }));
    }).then((cardsData) => {
        return Promise.all(cardsData.map((cardInfo) => storeCardInfo(axiosInstance, cardInfo, uid)));
    }).then((cards) => {
        console.log('cards:', cards);
        return Promise.all([Promise.resolve(cards), getUserDocument(uid)]);
    }).then((arrayWithCardsAndDoc) => {
        
        return arrayWithCardsAndDoc[1].ref.update({
            presto_num_cards: arrayWithCardsAndDoc[0].length,
        });
    });
}

/**
 * Must be logged in
 */
function fetchCardInfo(axiosInstance, card) {
    const prestoCard = getAPIWrapperWithAxiosInstance(axiosInstance);

    return prestoCard.setCurrentCard.call(axiosInstance, card).then((response) => {
        if(!response.success) return Promise.resolve(false);

        return Promise.resolve(response.currentBalanceData);
    });
}

function fetchCardActivity(axiosInstance, from) {
    const prestoCard = getAPIWrapperWithAxiosInstance(axiosInstance);

    return prestoCard.getActivityByDateRange.call(axiosInstance, '1970-01-01', Date.now()).then((history) => {
        history = history.map((historyItem) => {
            historyItem.date = moment.tz(historyItem.date, 'M/D/YYYY h:mm:ss a', "America/Toronto").utc();
            console.log('moment: ', historyItem.date);
            historyItem.date = admin.firestore.Timestamp.fromDate(historyItem.date.toDate());
            console.log('Set date to: ', historyItem.date);
            return historyItem;
        });

        return history;
    });
}

function storeCardInfo(axiosInstance, cardInfo, uid) {
    return admin.firestore().collection('cards').where('uid', '==', uid).where('card_number', '==', cardInfo.cardNumber).get().then((querySnapshot) => {
        if(!querySnapshot.empty) {
            return storeCardInfoDoesExist(axiosInstance, querySnapshot.docs[0], cardInfo, uid);
        } else {
            return storeCardInfoDoesNotExist(axiosInstance, cardInfo, uid);
        }
    });
}

function storeCardInfoDoesExist(axiosInstance, doc, cardInfo, uid) {
    const cardDocument = getCardInfoDocument(cardInfo, uid);

    return doc.ref.update(cardDocument).then((writeResult) => {
        let latestDate = doc.get('latest_date');
        
        return fetchCardActivity(axiosInstance, latestDate);
    }).then((history) => {
        let lastLatestTimestamp = doc.get('latest_date');
        let lastLatestDate = lastLatestTimestamp.toDate();
        console.log(lastLatestDate.getFullYear(), lastLatestDate.getMonth(), lastLatestDate.getDate());

        let lastLatestDay = new Date(lastLatestDate.getFullYear(), lastLatestDate.getMonth(), lastLatestDate.getDate(), 0, 0, 0, 0);
        return Promise.all([history, doc.ref.collection('history').where('date', '>=', lastLatestDay).get()]);
    }).then(([history, querySnapshot]) => {
        if(!querySnapshot.empty) {
            querySnapshot.docs.forEach((existingItem) => {
                const index = history.findIndex((element) => {

                    return element.date.toMillis() === existingItem.get('date').toMillis() && 
                        element.amount === existingItem.get('amount') && 
                        element.type === existingItem.get("type");
                });

                if(index >= 0) {
                    history.splice(index, 1);
                }
            });
        }
        let latestDate = null;

        history.forEach((historyItem) => {
            if(latestDate === null || historyItem > latestDate) {
                latestDate = historyItem.date;
            }
        });

        return Promise.all([latestDate, history.map((historyItem) => {
            return doc.ref.collection('history').add(historyItem);
        })]);
    }).then(([latestDate, writes]) => {
        if(latestDate !== null) {
            return doc.ref.set({latest_date: latestDate}, {merge: true});
        } else {
            return Promise.resolve(latestDate);
        }
    });
}

function storeCardInfoDoesNotExist(axiosInstance, cardInfo, uid) {

    const cardDocument = getCardInfoDocument(cardInfo, uid);

    return admin.firestore().collection('cards').add(cardDocument).then((ref) => {
        return Promise.all([ref, fetchCardActivity(axiosInstance, '1970-01-01')]);
    }).then(([ref, history]) => {
        console.log(ref.path, history);
        let latestDate = null;
        history.forEach((historyItem) => {
            if(latestDate === null || historyItem.date > latestDate) {
                latestDate = historyItem.date;
            } 
        });

        console.log('history: ', history);
        return Promise.all([Promise.resolve(ref), Promise.resolve(latestDate), Promise.all(history.map((historyItem) => {
            console.log('item: ', historyItem);
            return ref.collection('history').add(historyItem);
        }))]);
    }).then(([ref, latestDate, writes]) => {
        return ref.set({latest_date: latestDate}, {merge: true});
    });
}

function getCardInfoDocument(cardInfo, uid) {
    return {
        'uid': uid,
        'balance': cardInfo.balance,
        'card_name': cardInfo.cardName,
        'card_number': cardInfo.cardNumber,
        'last_updated_on': cardInfo.lastUpdatedOn,
    }
}