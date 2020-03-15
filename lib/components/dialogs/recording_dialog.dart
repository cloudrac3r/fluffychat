import 'dart:async';

import 'package:fluffychat/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';

class RecordingDialog extends StatefulWidget {
  final Function onFinished;

  const RecordingDialog({this.onFinished, Key key}) : super(key: key);

  @override
  _RecordingDialogState createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<RecordingDialog> {
  FlutterSound flutterSound = FlutterSound();
  String time = "00:00:00";

  StreamSubscription _recorderSubscription;

  void startRecording() async {
    await flutterSound.startRecorder(
      codec: t_CODEC.CODEC_AAC,
    );
    _recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
      DateTime date =
          DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
      setState(() => time = DateFormat('mm:ss:SS', 'en_US').format(date));
    });
  }

  @override
  void initState() {
    super.initState();
    startRecording();
  }

  @override
  void dispose() {
    if (flutterSound.isRecording) flutterSound.stopRecorder();
    _recorderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: 8,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "${I18n.of(context).recording}: $time",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(
            I18n.of(context).cancel.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).textTheme.body1.color.withAlpha(150),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FlatButton(
          child: Row(
            children: <Widget>[
              Text(I18n.of(context).send.toUpperCase()),
              SizedBox(width: 4),
              Icon(Icons.send, size: 15),
            ],
          ),
          onPressed: () async {
            await _recorderSubscription?.cancel();
            final String result = await flutterSound.stopRecorder();
            if (widget.onFinished != null) {
              widget.onFinished(result);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}