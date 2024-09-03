import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicListTile extends ConsumerStatefulWidget {
  final SongModel recommendation;
  final Function()? leadingOnTap;
  final Function()? trailingOnTap;
  final bool isPlaying;
  final Function(bool isPlaying)? onPlaybackStateChanged;
  final bool isSelected;
  final bool isFromSpotifyPlaylistCard;
  final Function()? onTap;
  final Function()? onDismissed;

  const MusicListTile({
    Key? key,
    required this.recommendation,
    this.leadingOnTap,
    this.trailingOnTap,
    required this.isPlaying,
    this.onPlaybackStateChanged,
    required this.isSelected,
    this.onTap,
    this.onDismissed,
    this.isFromSpotifyPlaylistCard = false,
  }) : super(key: key);

  @override
  _MusicListTileState createState() => _MusicListTileState();
}

class _MusicListTileState extends ConsumerState<MusicListTile> {
  @override
  Widget build(BuildContext context) {
    return widget.isFromSpotifyPlaylistCard
        ? ListTile(
            leading: GestureDetector(
              onTap: widget.leadingOnTap,
              child: Stack(
                children: [
                  CachedNetworkImage(
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
                  if (widget.isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              (widget.recommendation.title?.length ?? 0) >= 26
                  ? "${widget.recommendation.title?.substring(0, 24)}..."
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
                            ? "${widget.recommendation.artist!.substring(0, 22)}..."
                            : widget.recommendation.artist ?? "",
                        style: subtitleTextStyle,
                      ),
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
                          style: const TextStyle(
                            color: Color(0xffFF581A),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    final url = widget.recommendation.trackUrl;
                    if (url != null && await canLaunch(url)) {
                      await launch(url);
                    } else {
                      // Handle the error if the URL cannot be launched
                    }
                  },
                  icon: SvgPicture.asset(
                    "assets/spotifylogo.svg",
                    width: 20,
                  ),
                ),
                CircleAvatar(
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
              ],
            ),
            onTap: widget.onTap,
          )
        : Dismissible(
            key: Key(widget.recommendation.id ?? ''),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => widget.onDismissed?.call(),
            background: Container(
              color: const Color.fromARGB(255, 199, 50, 40),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(
                CupertinoIcons.delete,
                color: Colors.white,
                size: 18,
              ),
            ),
            child: ListTile(
              leading: GestureDetector(
                onTap: widget.leadingOnTap,
                child: Stack(
                  children: [
                    CachedNetworkImage(
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
                    if (widget.isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              title: Text(
                (widget.recommendation.title?.length ?? 0) >= 26
                    ? "${widget.recommendation.title?.substring(0, 24)}..."
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
                          text: (widget.recommendation.artist?.length ?? 0) >=
                                  24
                              ? "${widget.recommendation.artist!.substring(0, 22)}..."
                              : widget.recommendation.artist ?? "",
                          style: subtitleTextStyle,
                        ),
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
                            style: const TextStyle(
                              color: Color(0xffFF581A),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      final url = widget.recommendation.trackUrl;
                      if (url != null && await canLaunch(url)) {
                        await launch(url);
                      } else {
                        // Handle the error if the URL cannot be launched
                      }
                    },
                    icon: SvgPicture.asset(
                      "assets/spotifylogo.svg",
                      width: 20,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: const Color(0xff191919),
                    child: IconButton(
                      icon: Icon(
                        widget.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: widget.recommendation.previewUrl != null
                          ? () => widget.trailingOnTap?.call()
                          : null,
                    ),
                  ),
                ],
              ),
              onTap: widget.onTap,
            ),
          );
  }
}
