import 'package:equatable/equatable.dart';
import 'package:wordle_supreme/wordle/models/letter_model.dart';

class Word extends Equatable {
  const Word({required this.letters});

  // splits strings into a list and maps each element to a letter to convert list of letters into a word
  factory Word.fromString(String word) =>
    Word(letters: word.split('').map((e) => Letter(val: e)).toList());

  // List of letters
  final List<Letter> letters;

  // gets string version of a word
  String get wordString => letters.map((e) => e.val).join();
  
  // adding a letter to our word
  void addLetter(String val) {
    // first index of an empty string
    final currentIndex = letters.indexWhere((e) => e.val.isEmpty);
    if (currentIndex != -1){
      letters[currentIndex] = Letter(val: val);
    }
  }

  // removing a letter from our word
  void removeLetter(){
    // checks that the index contains a letter
    final recentLetterIndex = letters.lastIndexWhere((e) => e.val.isNotEmpty);
    if (recentLetterIndex != -1){
      // set the letter at the position to an empty letter
      letters[recentLetterIndex] = Letter.empty();
    }
  }

  @override
  List<Object?> get props => [letters];
}
