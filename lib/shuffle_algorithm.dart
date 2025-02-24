// import 'dart:math';
// import 'package:mellowde/models/song.dart';

// class ShuffleAlgorithm {
//   final int playcount = 1; // visur kur playcount tai tures but song.playcount

//   static List<Song> autoShuffle(List<Song> songs) {
//     if (shouldShuffleByPlaycount(songs) && shouldShuffleWithoutRepeatingArtists(songs)) {
//       return shuffleByPlaycountAndWithoutRepeatingArtists(songs);
//     } else if (shouldShuffleByPlaycount(songs)) {
//       return shuffleByPlaycount(songs);
//     } else if (shouldShuffleWithoutRepeatingArtists(songs)) {
//       return shuffleWithoutRepeatingArtists(songs);
//     } else {
//       return shuffleRandomly(songs);
//     }
//   }

//   static bool shouldShuffleByPlaycount(List<Song> songs) {
//     return songs.every((song) => song.playcount != 0);
//   }

//   static bool shouldShuffleWithoutRepeatingArtists(List<Song> songs) {
//     return songs.map((song) => song.artistName).toSet().length >= 2;
//   }

//   static List<Song> shuffleByPlaycountAndWithoutRepeatingArtists(List<Song> songs) {
//     songs.sort((a, b) {
//       if (a.playcount != b.playcount) {
//         return b.playcount.compareTo(a.playcount);
//       } else {
//         return a.artistName.compareTo(b.artistName);
//       }
//     });
//     return songs;
//   }

//   static List<Song> shuffleByPlaycount(List<Song> songs) {
//     songs.sort((a, b) {
//       return b.playcount.compareTo(a.playcount);
//     });
//     return songs;
//   }

//   static List<Song> shuffleWithoutRepeatingArtists(List<Song> songs) {
//     songs.sort((a, b) {
//       return a.artistName.compareTo(b.artistName);
//     });
//     return songs;
//   }

//   static List<Song> shuffleRandomly(List<Song> songs) {
//     songs.shuffle();
//     return songs;
//   }
// }