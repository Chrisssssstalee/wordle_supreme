// handles game state of the application
import 'dart:math';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordle_supreme/app/app_colors.dart';
import 'package:wordle_supreme/wordle/data/word_list.dart';
import 'package:wordle_supreme/wordle/models/letter_model.dart';
import 'package:wordle_supreme/wordle/models/word_model.dart';
import 'package:wordle_supreme/wordle/widgets/board.dart';
import 'package:wordle_supreme/wordle/widgets/keyboard.dart';

enum GameStatus {playing, submitting, lost, won}

class WordleScreen extends StatefulWidget{
  const WordleScreen({ Key? key }) : super(key: key);

  @override
  _WordleScreenState createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  GameStatus _gameStatus = GameStatus.playing;
  final FocusNode _focusNode = FocusNode();
  List<String> _fiveLetterWords = [];
  late Word _solution;

  @override
  void initState() {
    super.initState();
    // raw keyboard listener is automatically focused
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _initWords();
  }

  Future<void> _initWords() async {
    // load
    final words = await WordList.loadWords();
    words.shuffle();
    setState(() {
      _fiveLetterWords = words;
      _solution = Word.fromString(_fiveLetterWords.first);
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    // only act on key down
    if (event is RawKeyDownEvent) {
      final logicalKey = event.logicalKey;

      if (logicalKey == LogicalKeyboardKey.enter) {
        _onEnterTapped();
      } else if (logicalKey == LogicalKeyboardKey.backspace || logicalKey == LogicalKeyboardKey.delete) {
        _onDeleteTapped();
      } else {
        final String keyLabel = logicalKey.keyLabel.toUpperCase();
        if (keyLabel.length == 1 &&
            keyLabel.codeUnitAt(0) >= 65 &&
            keyLabel.codeUnitAt(0) <= 90) {
          _onKeyTapped(keyLabel);
        }
      }
    }
  }

  // generate six guesses
  final List<Word>_board = List.generate(
    6,
    (_) => Word(letters: List.generate(5, (_) => Letter.empty())),
  );

  // list of lists of global key flip card states
  final List<List<GlobalKey<FlipCardState>>> _flipCardKeys = List.generate(
    6, 
    (_) => List.generate(5, (_) => GlobalKey<FlipCardState>()),
  );

  // keeps track of current guess
  int _currentWordIndex = 0;

  // getter returns current word or null if out of range
  Word? get _currentWord =>
      _currentWordIndex < _board.length ? _board[_currentWordIndex] : null;
  
  /*
  // solution word thats randomixed from word_list.dart
  Word _solution = Word.fromString(
  fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),
  );
  */

  // keeps track of the letters
  final Set<Letter> _keyboardLetters = {};

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode, 
      onKey: _handleKeyEvent,
    child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'WORDLE SUPREME',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Board(board: _board, flipCardKeys: _flipCardKeys),
            const SizedBox(height: 80),
            Keyboard(
              onKeyTapped: _onKeyTapped, 
              onDeleteTapped: _onDeleteTapped, 
              onEnterTapped: _onEnterTapped,
              letters: _keyboardLetters,
            ),
          ],
        ),
      ),
    )
    );
  }

  // adding letter
  void _onKeyTapped(String val) {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.addLetter(val.toUpperCase()));
    }
  }

  // removing letter
  void _onDeleteTapped() {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.removeLetter());
    }
  }

  Future<void> _onEnterTapped() async {
    // if playing status & word has no empty letters
    if (_gameStatus == GameStatus.playing && _currentWord != null && !_currentWord!.letters.contains(Letter.empty())) {
      // prevents users from spamming enter button
      _gameStatus = GameStatus.submitting;

      // if words havent loaded yet, do nothing
      if (_fiveLetterWords.isEmpty) {
        _gameStatus = GameStatus.playing;
        return;
      }

      final guessString = _currentWord!.wordString.toUpperCase();
      
      // check if word is valid
      if (!_fiveLetterWords.contains(guessString)) {
        // shake row
        Board.rowShakeKeys[_currentWordIndex].currentState?.shake();

        // error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not a valid word!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.redAccent,
          ),
        );

        // reset the letters for this row
        setState(() {
          _board[_currentWordIndex] = Word(
            letters: List.generate(5, (_) => Letter.empty()),
          );
        });

        // let them keep guessing
        _gameStatus = GameStatus.playing;
        return; // don't go to the next row
      }

      // compares word to the solution
      for (var i = 0; i < _currentWord!.letters.length; i++) {
        final currentWordLetter = _currentWord!.letters[i];
        final currentSolutionLetter = _solution.letters[i];
      
        setState(() {
          if (currentWordLetter == currentSolutionLetter) {
            _currentWord!.letters[i] = currentWordLetter.copyWith(status: LetterStatus.correct);
          } else if (_solution.letters.contains(currentWordLetter)) {
            _currentWord!.letters[i] = currentWordLetter.copyWith(status: LetterStatus.inWord);
          } else {
            _currentWord!.letters[i] = currentWordLetter.copyWith(status: LetterStatus.notInWord);
          }
        });

        // if existing letter in keyboard letters
        final letter = _keyboardLetters.firstWhere(
          (e) => e.val == currentWordLetter.val,
          orElse: () => Letter.empty(),
        );
        // isn't correct
        if (letter.status != LetterStatus.correct) {
          // update keyboard state
          _keyboardLetters.removeWhere((e) => e.val == currentWordLetter.val);
          _keyboardLetters.add(_currentWord!.letters[i]);
        }

        // after each word's letter status is updated, flip the card after 150 seconds
        await Future.delayed(
          const Duration(milliseconds: 150),
          () => _flipCardKeys[_currentWordIndex][i].currentState?.toggleCard(),
        );
      }

      _checkIfWinOrLoss();
    }
  }

/*  void _checkIfWinOrLoss() {
    if (_currentWord!.wordString == _solution.wordString) {
      _gameStatus = GameStatus.won;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.none,
          duration: const Duration(days: 1),
          backgroundColor: correctColor,
          content: const Text(
            'You won!',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'New Game', 
            onPressed: _restart,
            textColor: Colors.white,
          ),
        )
      );
    } else if (_currentWordIndex + 1 >= _board.length) {
      _gameStatus = GameStatus.lost;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.none,
          duration: const Duration(days: 1),
          backgroundColor: Colors.redAccent,
          content: Text(
            'You Lost! The word was: ${_solution.wordString}',
            style: const TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'New Game', 
            onPressed: _restart,
            textColor: Colors.white,  
          ),
        ),
      );
    } // if the user hasn't won or lost
    else {
      _gameStatus = GameStatus.playing;
    }
    _currentWordIndex += 1;
  }

*/

  void _checkIfWinOrLoss() async{
  if (_currentWord!.wordString == _solution.wordString) {
    _gameStatus = GameStatus.won;
    // wait
    await Future.delayed(const Duration(milliseconds: 1000));
    showDialog(
      context: context,
      barrierDismissible: false, // user must hit "New Game"
      builder: (_) => AlertDialog(
        title: const Text('You won!'),
        content: const Text('Congratulations!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              _restart();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  } else if (_currentWordIndex + 1 >= _board.length) {
    _gameStatus = GameStatus.lost;
    // wait
    await Future.delayed(const Duration(milliseconds: 1000));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('You Lost!'),
        content: Text('The word was: ${_solution.wordString}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restart();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  } else {
    _gameStatus = GameStatus.playing;
  }

  _currentWordIndex += 1;
  }

  void _restart() {
    setState(() {
      _gameStatus = GameStatus.playing;
      _currentWordIndex = 0;

      // reset the board
      _board
        ..clear()
        ..addAll(
          List.generate(
            6,
            (_) => Word(letters: List.generate(5, (_) => Letter.empty())),
          ),
        );
      
      // pick a new random solution
      if (_fiveLetterWords.isNotEmpty) {
        final randomIndex = Random().nextInt(_fiveLetterWords.length);
        _solution = Word.fromString(_fiveLetterWords[randomIndex]);
      }

      // reset flipCardKeys to initial state
      _flipCardKeys
        ..clear()
        ..addAll(
          List.generate(
            6, 
            (_) => List.generate(5, (_) => GlobalKey<FlipCardState>()),
          ),
        );

      _keyboardLetters.clear();
    });
  }
}