import 'package:flutter/material.dart';

import '../consts.dart';

Widget backBTN({required BuildContext context, required Widget pageRoute}) {
  return IconButton(
    onPressed: () {
      dataRetriveFlag = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => pageRoute,
        ),
      );
    },
    icon: const Icon(Icons.arrow_back),
  );
}
