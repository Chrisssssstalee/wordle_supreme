// maps each word into a row of board tiles
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:wordle_supreme/wordle/widgets/shake.dart';
import 'package:wordle_supreme/wordle/models/letter_model.dart';
import 'package:wordle_supreme/wordle/models/word_model.dart';
import 'package:wordle_supreme/wordle/widgets/board_tile.dart';

class Board extends StatelessWidget {
  const Board({
    Key? key,
    required this.board,
    required this.flipCardKeys,
  }) : super(key: key);

  final List<Word> board;

  final List<List<GlobalKey<FlipCardState>>> flipCardKeys;

  static final rowShakeKeys = List.generate(
    6, 
    (_) => GlobalKey<ShakeWidgetState>(),  
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: board.asMap().map((i, word) {
        return MapEntry(
          i,
          ShakeWidget(
            key: rowShakeKeys[i],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: word.letters.asMap().map((j, letter) {
                return MapEntry(
                  j,
                  FlipCard(
                    key: flipCardKeys[i][j],
                    flipOnTouch: false,
                    direction: FlipDirection.VERTICAL,
                    front: BoardTile(
                      letter: Letter(
                        val: letter.val,
                        status: LetterStatus.initial,
                      ),
                    ),
                    back: BoardTile(letter: letter),
                  ),
                );
              }).values.toList(),
            ),
          ),
        );
      }).values.toList(),
    );
  }
}