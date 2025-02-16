
import 'package:flutter/material.dart';

import 'MultiQuestion/MultiQuestionWidget.dart';
import 'Puzzle/PuzzleWidget.dart';

final List<Map<String, dynamic>> challenges = [
  {
    "name": "پازل",
    "icon": Icons.extension,
    "page": const PuzzleBottomSheet(),
  },
  {
    "name": "چهار گزینه ای",
    "icon": Icons.list_alt_rounded,
    "page": const MultiQuestionWidget(),
  },

  // در صورت نیاز موارد بیشتری را اضافه کنید...
];
