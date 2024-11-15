import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:fluffychat/components/avatar.dart';
import 'package:fluffychat/components/matrix.dart';
import 'package:flutter/material.dart';
import '../utils/client_presence_extension.dart';
import '../utils/presence_extension.dart';
import 'package:adaptive_page_layout/adaptive_page_layout.dart';

class ContactsList extends StatefulWidget {
  final TextEditingController searchController;

  const ContactsList({
    Key key,
    @required this.searchController,
  }) : super(key: key);
  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<ContactsList> {
  StreamSubscription _onSync;

  @override
  void dispose() {
    _onSync?.cancel();
    super.dispose();
  }

  DateTime _lastSetState = DateTime.now();
  Timer _coolDown;

  void _updateView() {
    _lastSetState = DateTime.now();
    setState(() => null);
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    _onSync ??= client.onSync.stream.listen((_) {
      if (DateTime.now().millisecondsSinceEpoch -
              _lastSetState.millisecondsSinceEpoch <
          1000) {
        _coolDown?.cancel();
        _coolDown = Timer(Duration(seconds: 1), _updateView);
      } else {
        _updateView();
      }
    });
    final contactList = Matrix.of(context)
        .client
        .contactList
        .where((p) => p.senderId
            .toLowerCase()
            .contains(widget.searchController.text.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: contactList.length,
      itemBuilder: (_, i) => _ContactListTile(contact: contactList[i]),
    );
  }
}

class _ContactListTile extends StatelessWidget {
  final Presence contact;

  const _ContactListTile({Key key, @required this.contact}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
        future:
            Matrix.of(context).client.getProfileFromUserId(contact.senderId),
        builder: (context, snapshot) {
          final displayname =
              snapshot.data?.displayname ?? contact.senderId.localpart;
          final avatarUrl = snapshot.data?.avatarUrl;
          return ListTile(
            leading: Container(
              width: Avatar.defaultSize,
              height: Avatar.defaultSize,
              child: Stack(
                children: [
                  Center(child: Avatar(avatarUrl, displayname)),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.circle,
                      color: contact.color,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
            title: Text(displayname),
            subtitle: Text(contact.getLocalizedStatusMessage(context),
                style: contact.presence.statusMsg?.isNotEmpty ?? false
                    ? TextStyle(
                        color: Theme.of(context).accentColor,
                        fontWeight: FontWeight.bold,
                      )
                    : null),
            onTap: () => AdaptivePageLayout.of(context)
                .pushNamedAndRemoveUntilIsFirst(
                    '/rooms/${Matrix.of(context).client.getDirectChatFromUserId(contact.senderId)}'),
          );
        });
  }
}
