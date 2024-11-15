import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'matrix.dart';

class ContentBanner extends StatelessWidget {
  final Uri mxContent;
  final double height;
  final IconData defaultIcon;
  final bool loading;
  final Function onEdit;
  final Client client;
  final double opacity;

  const ContentBanner(this.mxContent,
      {this.height = 400,
      this.defaultIcon = Icons.people_outline,
      this.loading = false,
      this.onEdit,
      this.client,
      this.opacity = 0.75,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = this.client ?? Matrix.of(context).client;
    final mediaQuery = MediaQuery.of(context);
    final bannerSize =
        (mediaQuery.size.width * mediaQuery.devicePixelRatio).toInt();
    final src = mxContent?.getThumbnail(
      client,
      width: bannerSize,
      height: bannerSize,
      method: ThumbnailMethod.scale,
      animated: true,
    );
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: opacity,
              child: (!loading && mxContent != null)
                  ? CachedNetworkImage(
                      imageUrl: src,
                      httpHeaders: client.headers,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                  : Icon(defaultIcon, size: 200),
            ),
          ),
          if (onEdit != null)
            Container(
              margin: EdgeInsets.all(8),
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                mini: true,
                onPressed: onEdit,
                child: Icon(Icons.camera_alt_outlined),
              ),
            ),
        ],
      ),
    );
  }
}
