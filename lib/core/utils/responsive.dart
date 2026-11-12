import 'package:flutter/material.dart';

/// Breakpoints from the documentation (section 14).
class Responsive {
  static double width(BuildContext c) => MediaQuery.sizeOf(c).width;
  static bool isMobile(BuildContext c) => width(c) < 600;
  static bool isTablet(BuildContext c) => width(c) >= 600 && width(c) < 1000;
  static bool isDesktop(BuildContext c) => width(c) >= 1000;
}
