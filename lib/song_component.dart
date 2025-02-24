import 'package:flutter/material.dart';
import 'package:knowledgeswap/add_to_playlsit_ui.dart';
import 'package:knowledgeswap/models/song.dart';
import 'package:knowledgeswap/song_creation_namebio_ui.dart';
import 'package:knowledgeswap/song_playing_ui.dart';

class SongComponent extends StatefulWidget {
  final Song song;
  final String type;
  final VoidCallback? onRemove;
  const SongComponent(
      {Key? key, required this.song, required this.type, this.onRemove})
      : super(key: key);

  @override
  _SongComponentState createState() => _SongComponentState();
}

class _SongComponentState extends State<SongComponent> {
  List<Song> songs = [];

  void onRemove() {
    // Implement the logic to remove the song from the playlist here
    // You can call the API or update the local state to remove the song
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      onLongPress: () {
        // Handle long press here, navigate to AddPlaylist()
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddPlaylist(song: widget.song)),
        );
      },
      child: InkWell(
        onTap: () {
          if (widget.type == "play") {
            songs.add(widget.song);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SongPlaying(songs: songs)),
            );
          } else if (widget.type == "edit") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SongCreation()));
          }
        },
        splashColor: Colors.grey,
        child: Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.type == "play") {
                      songs.add(widget.song);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SongPlaying(songs: songs)),
                      );
                    } else if (widget.type == "edit") {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SongCreation()));
                    }
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(widget.song.imagePath),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.song.songName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: "Karla",
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.song.artistName,
                            style: const TextStyle(color: Colors.black38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // if (widget.type == 'remove' && widget.onRemove != null)
                // IconButton(
                //   icon: const Icon(Icons.remove),
                //   onPressed: widget.onRemove,
                // ),
              ],
            )),
      ),
    );
  }
}
