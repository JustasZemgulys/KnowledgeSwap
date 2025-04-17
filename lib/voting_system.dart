import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'user_info_provider.dart';

class Vote {
  final int id;
  final int direction; // 1 for upvote, -1 for downvote
  final int userId;
  final int itemId;
  final String itemType;

  Vote({
    required this.id,
    required this.direction,
    required this.userId,
    required this.itemId,
    required this.itemType,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      direction: json['direction'],
      userId: json['fk_user'],
      itemId: json['fk_item'],
      itemType: json['fk_type'],
    );
  }
}

class VotingController {
  final BuildContext context;
  final String itemType;
  final int itemId;
  final int currentScore;
  final Function(int) onScoreUpdated;

  VotingController({
    required this.context,
    required this.itemType,
    required this.itemId,
    required this.currentScore,
    required this.onScoreUpdated,
  });

  Future<void> _sendVote(int direction) async {
    final userInfo = Provider.of<UserInfoProvider>(context, listen: false).userInfo;
    if (userInfo == null) return;

    try {
      //final serverIP = await getUserIP();
      final url = Uri.parse('https://juszem1-1.stud.if.ktu.lt/vote.php');

      final response = await http.post(
        url,
        body: {
          'direction': direction.toString(),
          'fk_user': userInfo.id.toString(),
          'fk_item': itemId.toString(),
          'fk_type': itemType,
        },
      );

      final responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        final newScore = responseData['new_score'] ?? currentScore;
        onScoreUpdated(newScore);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Voting failed')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting vote: $e')),
      );
    }
  }

  Future<void> upvote() async {
    await _sendVote(1);
  }

  Future<void> downvote() async {
    await _sendVote(-1);
  }
}

class VotingWidget extends StatelessWidget {
  final int score;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final int? userVote; // 1 for upvote, -1 for downvote, null for no vote

  const VotingWidget({
    super.key,
    required this.score,
    required this.onUpvote,
    required this.onDownvote,
    this.userVote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_upward,
            color: userVote == 1 ? Colors.orange : Colors.grey,
          ),
          onPressed: onUpvote,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text(
          score.toString(),
          style: const TextStyle(fontSize: 16),
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_downward,
            color: userVote == -1 ? Colors.blue : Colors.grey,
          ),
          onPressed: onDownvote,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}