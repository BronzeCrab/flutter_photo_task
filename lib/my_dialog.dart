import 'package:flutter/material.dart';

Future<void> dialogBuilder(
    BuildContext context, String respText, int respStatus) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Response results:'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(respText),
              Text("code: ${respStatus.toString()}"),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
