
import 'package:flutter/material.dart';

import 'ListChallenges.dart';

class ChallengeSelection {
  /// نمایش modal bottom sheet برای انتخاب چالش
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: 200,
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0C091A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: const Border(
              top: BorderSide(color: Colors.white, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "انتخاب چالش",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // نمایش آیتم‌ها به صورت انعطاف‌پذیر
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: challenges.map((challenge) {
                  return SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // بستن Bottom Sheet انتخاب چالش
                        // نمایش صفحه چالش به صورت یک Bottom Sheet دیگر
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext innerCtx) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white, width: 1),
                                ),
                                color: Color(0xFF0C091A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  challenge["page"],
                                ],
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            challenge["name"],
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 153, 68, 158), // رنگ بنفش پس‌زمینه
                              borderRadius: BorderRadius.circular(10), // گوشه‌های گرد
                            ),
                            alignment: Alignment.center, // برای مرکز قرار دادن آیکون
                            height: 30, // ارتفاع مستطیل
                            width: 30, // عرض مستطیل
                            child: Icon(
                              challenge["icon"], // آیکون چالش
                              color: Colors.white, // رنگ آیکون
                              size: 20, // اندازه آیکون
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
