// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:nuance/providers/add_tracks_provider.dart';

// Future<dynamic> newMethod(BuildContext context, List<SongModel> recommendations) {
//     return showModalBottomSheet(
//                   context: context,
//                   isScrollControlled: true,
//                   builder: (context) {
//                     return Container(
//                       height: MediaQuery.of(context).size.height * 0.93,
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(25.0),
//                           topRight: Radius.circular(25.0),
//                         ),
//                       ),
//                       child: Column(
//                         // mainAxisSize: MainAxisSize.max,
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           Container(
//                             width: Get.width,
//                             alignment: Alignment.bottomCenter,
//                             color: AppTheme.textColor.withOpacity(0.011),
//                             padding: const EdgeInsets.only(top: 35, bottom: 30),
//                             child: const Text(
//                               "Add to Playlist",
//                               style: TextStyle(color: AppTheme.textColor, fontSize: 14),
//                             ),
//                           ),
//                           Expanded(
//                             child: Consumer(
//                               builder: (context, ref, child) {
//                                 final playlistsState = ref.watch(playlistProvider);
//                                 final addTracksState = ref.watch(addTracksProvider);
                
//                                 return playlistsState.when(
//                                   data: (playlists) {
//                                     return ListView.builder(
//                                       shrinkWrap: true,
//                                       itemCount: playlists.length,
//                                       itemBuilder: (context, index) {
//                                         final playlist = playlists[index];
//                                         final isCurrentLoading =
//                                             _loadingPlaylistId == playlist.id;
                
//                                         return ListTile(
//                                           // leading: Image.network(
//                                           //   playlist.imageUrl,
//                                           //   width: 50,
//                                           //   height: 50,
//                                           //   fit: BoxFit.cover,
//                                           // ),
//                                           leading: CachedNetworkImage(
//                                             height: 40,
//                                             width: 40,
//                                             imageUrl: playlist.imageUrl,
//                                             placeholder: (context, url) {
//                                               return Container(
//                                                   alignment: Alignment.center,
//                                                   child:
//                                                       const CupertinoActivityIndicator());
//                                             },
//                                           ),
//                                           title: Text(playlist.name),
//                                           subtitle: Text(
//                                               "${playlist.totalTracks} ${playlist.totalTracks >= 2 ? "songs" : "song"} "),
//                                           enabled: !isCurrentLoading &&
//                                               addTracksState.maybeWhen(
//                                                 loading: () => false,
//                                                 orElse: () => true,
//                                               ),
//                                           onTap: () {
//                                             if (sessionState?.value?.accessToken != null) {
//                                               final trackIds = recommendations
//                                                   .map((song) => song.trackUri)
//                                                   .toList();
                
//                                               final params = AddTracksParams(
//                                                 accessToken:
//                                                     sessionState!.value!.accessToken,
//                                                 playlistId: playlist.id,
//                                                 trackIds: trackIds,
//                                               );
                
//                                               setState(() {
//                                                 _loadingPlaylistId = playlist.id;
//                                               });
                
//                                               ref
//                                                   .read(addTracksProvider.notifier)
//                                                   .addTracksToPlaylist(params)
//                                                   .then((_) {
//                                                 setState(() {
//                                                   _loadingPlaylistId = null;
//                                                 });
//                                                 Navigator.pop(context); // Close modal
//                                                 // Navigator.pop(context); // Navigate back to home screen
//                                               }).catchError((error) {
//                                                 setState(() {
//                                                   _loadingPlaylistId = null;
//                                                 });
//                                                 ScaffoldMessenger.of(context).showSnackBar(
//                                                   const SnackBar(
//                                                       content: Text(
//                                                           'Failed to add tracks to playlist.')),
//                                                 );
//                                               });
//                                             } else {
//                                               ScaffoldMessenger.of(context).showSnackBar(
//                                                 const SnackBar(
//                                                     content:
//                                                         Text('No access token found.')),
//                                               );
//                                             }
//                                           },
//                                           trailing: isCurrentLoading
//                                               ? const SizedBox(
//                                                   width: 20,
//                                                   height: 20,
//                                                   child: CupertinoActivityIndicator(
//                                                       // strokeWidth: 2,
//                                                       ),
//                                                 )
//                                               : null,
//                                         );
//                                       },
//                                     );
//                                   },
//                                   loading: () => const Center(
//                                     child: CupertinoActivityIndicator(),
//                                   ),
//                                   error: (error, stack) => Center(
//                                     child: Text('Error: $error'),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//   }