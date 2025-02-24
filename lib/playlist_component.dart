import 'package:flutter/material.dart';
import 'package:knowledgeswap/playlist_edit_ui.dart';
import 'package:knowledgeswap/playlist_ui.dart';
import 'package:knowledgeswap/models/playlist.dart';

class PlaylistComponent extends StatefulWidget {
  final Playlist playlist;
  final String type;
  const PlaylistComponent(
      {super.key, required this.playlist, required this.type});

  @override
  State<PlaylistComponent> createState() => _PlaylistComponentState();
}

class _PlaylistComponentState extends State<PlaylistComponent> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: InkWell(
        onTap: () {
          if (widget.type == "edit") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PlaylistEdit(idPlaylist: widget.playlist.idPlaylist)),
            );
          } else if (widget.type == "play") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PlaylistUi(playlist: widget.playlist)),
            );
          }
        },
        splashColor: Colors.grey,
        child: Container(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(widget.playlist.coverURL),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.playlist.name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: "Karla",
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.playlist.description,
                          style: const TextStyle(color: Colors.black38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add the delete IconButton
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                        Icons.mode_edit), // Customize the icon as needed
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlaylistEdit(
                                idPlaylist: widget.playlist.idPlaylist)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
