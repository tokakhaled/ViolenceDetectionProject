import 'package:flutter/material.dart';
import 'package:tessst/pages/notification_screen.dart';
import '../consts.dart';
import '../functions/date_string.dart';
import '../widgets/back_btn.dart';

class ReportScreen extends StatelessWidget {
  final int index;
  const ReportScreen({required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: backBTN(
          context: context,
          pageRoute: const NotificationScreen(),
        ),
        title:
            Text("Violence Detection Report #${allDocuments.length - index}"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    date2string(
                      allDocuments[index]["date"],
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                allDocuments[index]["report"],
                softWrap: true,
                style: const TextStyle(
                  fontSize: 25,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
