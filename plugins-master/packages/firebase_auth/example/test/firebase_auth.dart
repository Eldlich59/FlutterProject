// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Completer<String> completer = Completer<String>();
  enableFlutterDriverExtension(handler: (_) => completer.future);
  tearDownAll(() => completer.complete(null));

  group('$FirebaseAuth', () {
    final FirebaseAuth auth = FirebaseAuth.instance;

    test('signInAnonymously', () async {
      final FirebaseUser user = await auth.signInAnonymously();
      expect(user.uid, isNotNull);
      expect(user.isAnonymous, isTrue);
    });
  });
}
