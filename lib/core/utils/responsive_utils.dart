import 'package:flutter/material.dart';

class ResponsiveUtils {
  const ResponsiveUtils._();

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }
}
