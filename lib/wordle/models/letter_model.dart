import 'package:equatable/equatable.dart';
import 'package:wordle_supreme/app/app_colors.dart';
import 'package:flutter/material.dart';

enum LetterStatus {initial, notInWord, inWord, correct}

class Letter extends Equatable {
  const Letter({
    required this.val,
    this.status = LetterStatus.initial,
  });

  // empty letter to pupulate the initial state of the board
  factory Letter.empty() => const Letter(val: '');

  final String val;

  final LetterStatus status;

  Color get BackgroundColor {
    switch (status) {
      case LetterStatus.initial:
        return Colors.transparent;
      case LetterStatus.notInWord:
        return notInWordColor;
      case LetterStatus.inWord:
        return inWordColor;
      case LetterStatus.correct:
        return correctColor;
    }
  }

  // shows proper color based on letter status
  Color get borderColor {
    switch (status) {
      case LetterStatus.initial:
        return Colors.grey;
      default:
        return Colors.transparent;
    }
  }

  // returns a copy of a letter 
  Letter copyWith ({
    String? val,
    LetterStatus? status,
  }) {
    return Letter(
    val: val ?? this.val,
    status: status ?? this.status,);
  }

  // compares val and status during equality checks
  @override
  List<Object?> get props => [val, status];
}