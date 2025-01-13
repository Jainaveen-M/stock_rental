import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Colors.green;
  static const Color secondaryColor = Color(0xFF2A2D3E);
  static const Color backgroundColor = Color(0xFF212332);
  static const Color surfaceColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textLight = Colors.white;

  // Status Colors
  static const Color statusActive = Colors.green;
  static const Color statusPending = Colors.orange;
  static const Color statusExpired = Colors.red;
  static const Color statusClosed = Colors.grey;

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeTitle = 20.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeRegular = 20.0;
  static const double iconSizeLarge = 24.0;

  // Spacing
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingRegular = 16.0;
  static const double spacingLarge = 24.0;

  // Widget Sizes
  static const double buttonHeight = 36.0;
  static const double inputHeight = 40.0;
  static const double cardPadding = 16.0;
  static const double dialogWidth = 400.0;
  static const double tableRowHeight = 48.0;

  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusRegular = 8.0;
  static const double borderRadiusLarge = 12.0;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: fontSizeRegular,
    color: textPrimary,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: fontSizeSmall,
    color: textSecondary,
  );
}
