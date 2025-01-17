import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_page_layout/adaptive_page_layout.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'matrix.dart';

class EncryptionButton extends StatefulWidget {
  final Room room;
  const EncryptionButton(this.room, {Key key}) : super(key: key);
  @override
  _EncryptionButtonState createState() => _EncryptionButtonState();
}

class _EncryptionButtonState extends State<EncryptionButton> {
  StreamSubscription _onSyncSub;

  void _enableEncryptionAction() async {
    if (widget.room.encrypted) {
      await AdaptivePageLayout.of(context)
          .pushNamed('/rooms/${widget.room.id}/encryption');
      return;
    }
    if (widget.room.joinRules == JoinRules.public) {
      await showOkAlertDialog(
        context: context,
        useRootNavigator: false,
        okLabel: L10n.of(context).ok,
        message: L10n.of(context).noEncryptionForPublicRooms,
      );
      return;
    }
    await showOkAlertDialog(
      context: context,
      useRootNavigator: false,
      okLabel: L10n.of(context).ok,
      message: L10n.of(context).unknownEncryptionAlgorithm,
    );
    return;
  }

  @override
  void dispose() {
    _onSyncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.room.encrypted) {
      _onSyncSub ??= Matrix.of(context)
          .client
          .onSync
          .stream
          .where((s) => s.deviceLists != null)
          .listen((s) => setState(() => null));
    }
    return FutureBuilder<List<User>>(
        future:
            widget.room.encrypted ? widget.room.requestParticipants() : null,
        builder: (BuildContext context, snapshot) {
          Color color;
          if (widget.room.encrypted && snapshot.hasData) {
            final users = snapshot.data;
            users.removeWhere((u) =>
                !{Membership.invite, Membership.join}.contains(u.membership) ||
                !widget.room.client.userDeviceKeys.containsKey(u.id));
            var allUsersValid = true;
            var oneUserInvalid = false;
            for (final u in users) {
              final status = widget.room.client.userDeviceKeys[u.id].verified;
              if (status != UserVerifiedStatus.verified) {
                allUsersValid = false;
              }
              if (status == UserVerifiedStatus.unknownDevice) {
                oneUserInvalid = true;
              }
            }
            color = oneUserInvalid
                ? Colors.red
                : (allUsersValid ? Colors.green : Colors.orange);
          } else if (!widget.room.encrypted &&
              widget.room.joinRules != JoinRules.public) {
            color = null;
          }
          return IconButton(
            tooltip: widget.room.encrypted
                ? L10n.of(context).encrypted
                : L10n.of(context).encryptionNotEnabled,
            icon: Icon(
                widget.room.encrypted
                    ? Icons.lock_outlined
                    : Icons.lock_open_outlined,
                size: 20,
                color: color),
            onPressed: _enableEncryptionAction,
          );
        });
  }
}
