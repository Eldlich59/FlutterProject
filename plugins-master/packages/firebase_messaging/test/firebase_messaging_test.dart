// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

void main() {
  MockMethodChannel mockChannel;
  FirebaseMessaging firebaseMessaging;

  setUp(() {
    mockChannel = MockMethodChannel();
    firebaseMessaging = FirebaseMessaging.private(
        mockChannel, FakePlatform(operatingSystem: 'ios'));
  });

  test('requestNotificationPermissions on ios with default permissions', () {
    firebaseMessaging.requestNotificationPermissions();
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('requestNotificationPermissions',
        <String, bool>{'sound': true, 'badge': true, 'alert': true}));
  });

  test('requestNotificationPermissions on ios with custom permissions', () {
    firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: false));
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('requestNotificationPermissions',
        <String, bool>{'sound': false, 'badge': true, 'alert': true}));
  });

  test('requestNotificationPermissions on android', () {
    firebaseMessaging = FirebaseMessaging.private(
        mockChannel, FakePlatform(operatingSystem: 'android'));

    firebaseMessaging.requestNotificationPermissions();
    verifyZeroInteractions(mockChannel);
  });

  test('requestNotificationPermissions on android', () {
    firebaseMessaging = FirebaseMessaging.private(
        mockChannel, FakePlatform(operatingSystem: 'android'));

    firebaseMessaging.requestNotificationPermissions();
    verifyZeroInteractions(mockChannel);
  });

  test('configure', () {
    firebaseMessaging.configure();
    verify(mockChannel.setMethodCallHandler(any));
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('configure'));
  });

  test('incoming token', () async {
    firebaseMessaging.configure();
    final dynamic handler =
        verify(mockChannel.setMethodCallHandler(captureAny)).captured.single;
    final String token1 = 'I am a super secret token';
    final String token2 = 'I am the new token in town';
    Future<String> tokenFromStream = firebaseMessaging.onTokenRefresh.first;
    await handler(MethodCall('onToken', token1));

    expect(await tokenFromStream, token1);

    tokenFromStream = firebaseMessaging.onTokenRefresh.first;
    await handler(MethodCall('onToken', token2));

    expect(await tokenFromStream, token2);
  });

  test('incoming iOS settings', () async {
    firebaseMessaging.configure();
    final dynamic handler =
        verify(mockChannel.setMethodCallHandler(captureAny)).captured.single;
    IosNotificationSettings iosSettings = const IosNotificationSettings();

    Future<IosNotificationSettings> iosSettingsFromStream =
        firebaseMessaging.onIosSettingsRegistered.first;
    await handler(MethodCall('onIosSettingsRegistered', iosSettings.toMap()));
    expect((await iosSettingsFromStream).toMap(), iosSettings.toMap());

    iosSettings = const IosNotificationSettings(sound: false);
    iosSettingsFromStream = firebaseMessaging.onIosSettingsRegistered.first;
    await handler(MethodCall('onIosSettingsRegistered', iosSettings.toMap()));
    expect((await iosSettingsFromStream).toMap(), iosSettings.toMap());
  });

  test('incoming messages', () async {
    final Completer<dynamic> onMessage = Completer<dynamic>();
    final Completer<dynamic> onLaunch = Completer<dynamic>();
    final Completer<dynamic> onResume = Completer<dynamic>();

    firebaseMessaging.configure(onMessage: (dynamic m) async {
      onMessage.complete(m);
    }, onLaunch: (dynamic m) async {
      onLaunch.complete(m);
    }, onResume: (dynamic m) async {
      onResume.complete(m);
    });
    final dynamic handler =
        verify(mockChannel.setMethodCallHandler(captureAny)).captured.single;

    final Map<String, dynamic> onMessageMessage = <String, dynamic>{};
    final Map<String, dynamic> onLaunchMessage = <String, dynamic>{};
    final Map<String, dynamic> onResumeMessage = <String, dynamic>{};

    await handler(MethodCall('onMessage', onMessageMessage));
    expect(await onMessage.future, onMessageMessage);
    expect(onLaunch.isCompleted, isFalse);
    expect(onResume.isCompleted, isFalse);

    await handler(MethodCall('onLaunch', onLaunchMessage));
    expect(await onLaunch.future, onLaunchMessage);
    expect(onResume.isCompleted, isFalse);

    await handler(MethodCall('onResume', onResumeMessage));
    expect(await onResume.future, onResumeMessage);
  });

  const String myTopic = 'Flutter';

  test('subscribe to topic', () {
    firebaseMessaging.subscribeToTopic(myTopic);
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('subscribeToTopic', myTopic));
  });

  test('unsubscribe from topic', () {
    firebaseMessaging.unsubscribeFromTopic(myTopic);
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('unsubscribeFromTopic', myTopic));
  });

  test('getToken', () {
    firebaseMessaging.getToken();
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('getToken'));
  });

  test('deleteInstanceID', () {
    firebaseMessaging.deleteInstanceID();
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('deleteInstanceID'));
  });

  test('autoInitEnabled', () {
    firebaseMessaging.autoInitEnabled();
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('autoInitEnabled'));
  });

  test('setAutoInitEnabled', () {
    // assert that we havent called the method yet
    verifyNever(firebaseMessaging.setAutoInitEnabled(true));

    firebaseMessaging.setAutoInitEnabled(true);

    // assert we called the method with enabled = true
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('setAutoInitEnabled', true));

    // assert that enabled = false was not yet called
    verifyNever(firebaseMessaging.setAutoInitEnabled(false));

    firebaseMessaging.setAutoInitEnabled(false);

    // assert call with enabled = false was properly done
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    verify(mockChannel.invokeMethod('setAutoInitEnabled', false));
  });
}

class MockMethodChannel extends Mock implements MethodChannel {}
