import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/screens/order_details.dart';
import 'package:afriomarkets_cust_app/screens/login.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/repositories/profile_repository.dart';
import 'package:one_context/one_context.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

final FirebaseMessaging _fcm = FirebaseMessaging.instance;

class PushNotificationService {
  Future initialise() async {
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    String? fcmToken = await _fcm.getToken();

    print("--fcm token--");
    print(fcmToken);
    if (is_logged_in.$ == true) {
      // update device token
      if (fcmToken != null) {
        var deviceTokenUpdateResponse =
            await ProfileRepository().getDeviceTokenUpdateResponse(fcmToken);
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: " + message.toString());
      _showMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onResume: $message");
      _serialiseAndNavigate(message);
    });
  }

  void _showMessage(RemoteMessage message) {
    print("onMessage: ${message.data}");

    OneContext().showDialog(
      // barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: ListTile(
          title: Text(message.notification?.title ?? ""),
          subtitle: Text(message.notification?.body ?? ""),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('GO'),
            onPressed: () {
              if (is_logged_in.$ == false) {
                ToastComponent.showDialog("You are not logged in", context,
                    gravity: ToastComponent.top,
                    duration: ToastComponent.lengthLong);
                return;
              }
              // print(message);
              Navigator.of(context).pop();
              if (message.data['item_type'] == 'order') {
                OneContext().push(MaterialPageRoute(builder: (_) {
                  return OrderDetails(
                      id: int.parse(message.data['item_type_id']),
                      from_notification: true);
                }));
              }
            },
          ),
        ],
      ),
    );
  }

  void _serialiseAndNavigate(RemoteMessage message) {
    print(message.toString());
    if (is_logged_in.$ == false) {
      OneContext().showDialog(
          // barrierDismissible: false,
          builder: (context) => AlertDialog(
                title: new Text("You are not logged in"),
                content: new Text("Please log in"),
                actions: <Widget>[
                  TextButton(
                    child: Text('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                      child: Text('Login'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        OneContext().push(MaterialPageRoute(builder: (_) {
                          return Login();
                        }));
                      }),
                ],
              ));
      return;
    }
    if (message.data['item_type'] == 'order') {
      OneContext().push(MaterialPageRoute(builder: (_) {
        return OrderDetails(
            id: int.parse(message.data['item_type_id']),
            from_notification: true);
      }));
    } // If there's no view it'll just open the app on the first view    }
  }
}
