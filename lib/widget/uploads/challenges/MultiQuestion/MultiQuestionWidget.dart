import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class MultiQuestionWidget extends StatefulWidget {
  const MultiQuestionWidget({Key? key}) : super(key: key);

  @override
  _MultiQuestionWidgetState createState() => _MultiQuestionWidgetState();
}

class _MultiQuestionWidgetState extends State<MultiQuestionWidget> {
  int? _selectedOption;
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ایجاد BottomSheet برای ویرایش سوال
  void _openQuestionEditor() {
    final TextEditingController overlayController =
        TextEditingController(text: questionController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // فضای کیبورد
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF0C091A),
              border: Border.all(color: Colors.white, width: .5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: Colors.green,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      questionController.text = overlayController.text;
                    });
                    Navigator.pop(context); // بستن BottomSheet
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: overlayController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      hintText: "مثال : چند رنگ در تصویر بالا میبینید ؟",
                      hintTextDirection: TextDirection.rtl,
                      contentPadding: EdgeInsets.only(right: 16),
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ایجاد BottomSheet برای ویرایش گزینه‌ها
  void _openOptionEditor(int index) {
    final TextEditingController overlayController =
        TextEditingController(text: optionControllers[index].text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // فضای کیبورد
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF0C091A),
              border: Border.all(color: Colors.white, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      optionControllers[index].text = overlayController.text;
                    });
                    Navigator.pop(context); // بستن BottomSheet
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: overlayController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      hintText: "متن گزینه را وارد کنید",
                      hintTextDirection: TextDirection.rtl,
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.only(right: 16),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: const Text(
                "چالش چهار گزینه ای",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 29, 26, 41),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // عنوان سوال (TextField)
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 217, 217, 217),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: TextField(
                      controller: questionController,
                      textAlign: TextAlign.center,
                      readOnly: true,
                      onTap: _openQuestionEditor, // باز کردن BottomSheet برای سوال
                      decoration: const InputDecoration(
                        hintText: "مثال : چند رنگ در تصویر بالا میبینید؟",
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: TextStyle(color: Color.fromARGB(255, 45, 41, 63)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 67, 70, 75),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOption(0),
                        _buildOption(1),
                        _buildOption(2),
                        _buildOption(3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        // عملکرد تایید پاسخ
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "تمام",
                        style: TextStyle(
                          color: Color.fromARGB(255, 12, 9, 25),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    "سوال و جواب را بنویسید و گزینه درست جواب را تعیین کنید",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 67, 70, 75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.transparent,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedOption = index;
              });
            },
            child: Icon(
              HugeIcons.strokeRoundedCheckmarkCircle04,
              color: _selectedOption == index ? Colors.green : Colors.black,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: optionControllers[index],
              readOnly: true,
              onTap: () {
                _openOptionEditor(index); // باز کردن BottomSheet برای گزینه
              },
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "گزینه ${index + 1}",
                hintStyle: const TextStyle(color: Color.fromARGB(255, 12, 9, 25)),
                hintTextDirection: TextDirection.rtl,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 12, 9, 25),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
