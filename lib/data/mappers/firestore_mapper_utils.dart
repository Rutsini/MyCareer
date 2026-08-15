import 'package:cloud_firestore/cloud_firestore.dart';

DateTime dateFromFirestore(Object? value, [DateTime? fallback]) =>
    value is Timestamp
        ? value.toDate()
        : fallback ?? DateTime.fromMillisecondsSinceEpoch(0);

double numberToDouble(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : fallback;
