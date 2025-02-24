import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Controls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Controls({
    Key? key,
    required this.audioPlayer,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (!(playing ?? false)) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPrevious,
                iconSize: 60,
                color: Colors.black,
                icon: const Icon(Icons.fast_rewind_rounded),
              ),
              IconButton(
                onPressed: audioPlayer.play,
                iconSize: 80,
                color: Colors.black,
                icon: Image.asset("assets/Play.png"),
              ),
              IconButton(
                onPressed: onNext,
                iconSize: 60,
                color: Colors.black,
                icon: const Icon(Icons.fast_forward_rounded),
              ),
            ],
          );
        } else if (processingState != ProcessingState.completed) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPrevious,
                iconSize: 60,
                color: Colors.black,
                icon: const Icon(Icons.fast_rewind_rounded),
              ),
              IconButton(
                onPressed: audioPlayer.pause,
                iconSize: 80,
                color: Colors.black,
                icon: Image.asset("assets/Pause.png"),
              ),
              IconButton(
                onPressed: onNext,
                iconSize: 60,
                color: Colors.black,
                icon: const Icon(Icons.fast_forward_rounded),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onPrevious,
              iconSize: 60,
              color: Colors.black,
              icon: const Icon(Icons.fast_rewind_rounded),
            ),
            const Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Colors.black,
            ),
            IconButton(
              onPressed: onNext,
              iconSize: 60,
              color: Colors.black,
              icon: const Icon(Icons.fast_forward_rounded),
            ),
          ],
        );
      },
    );
  }
}
