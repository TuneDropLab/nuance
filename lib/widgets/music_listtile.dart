import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_animated_icon_button/flutter_animated_icon_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/utils/constants.dart';

class MusicListTile extends ConsumerStatefulWidget {
  final SongModel recommendation;
  final Function()? leadingOnTap;
  final Function()? trailingOnTap;
  final bool isPlaying;

  const MusicListTile({
    Key? key,
    required this.recommendation,
    this.leadingOnTap,
    this.trailingOnTap,
    required this.isPlaying,
  }) : super(key: key);

  @override
  _MusicListTileState createState() => _MusicListTileState();
}

class _MusicListTileState extends ConsumerState<MusicListTile> {
  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: widget.leadingOnTap,
        child: CachedNetworkImage(
          height: 48,
          width: 48,
          imageUrl: widget.recommendation.artworkUrl ?? "",
          imageBuilder: (context, imageProvider) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                image: DecorationImage(
                  image: imageProvider,
                ),
              ),
            );
          },
          placeholder: (context, url) {
            return Container(
              alignment: Alignment.center,
              child: const CupertinoActivityIndicator(),
            );
          },
          errorWidget: (context, url, error) {
            return Container(
              alignment: Alignment.center,
              child: const CupertinoActivityIndicator(),
            );
          },
        ),
      ),
      title: Text(
        (widget.recommendation.title?.length ?? 0) >= 17
            ? "${widget.recommendation.title?.substring(0, 17)}..."
            : widget.recommendation.title ?? "",
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      subtitle: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: (widget.recommendation.artist?.length ?? 0) >= 24
                      ? "${widget.recommendation.artist!.substring(0, 24)}..."
                      : widget.recommendation.artist ?? "",
                  style: subtitleTextStyle,
                ),
                // if (widget.recommendation.popularity! >= 70)
                TextSpan(
                  text: (widget.recommendation.popularity ?? 0) >= 70
                      ? " 🔥"
                      : "",
                  style: const TextStyle(
                    color: Color(0xffFF581A),
                  ),
                ),
                if (widget.recommendation.popularity! >= 70)
                  TextSpan(
                      text: "${widget.recommendation.popularity}%",
                      style: widget.recommendation.popularity! >= 70
                          ? const TextStyle(
                              color: Color(0xffFF581A),
                            )
                          : subtitleTextStyle),
              ],
            ),
          ),
        ],
      ),
      trailing: CircleAvatar(
        backgroundColor: const Color(0xff191919),
        child: IconButton(
          icon: Icon(
            widget.isPlaying ? Icons.pause : Icons.play_arrow_rounded,
            color: Colors.white,
          ),
          onPressed: widget.recommendation.previewUrl != null
              ? () => widget.trailingOnTap?.call()
              : null,
        ),
      ),
      // onTap: () => widget.trailingOnTap?.call(),
    );
  }
}
