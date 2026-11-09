import 'package:intl/intl.dart';

/// Utility functions for date/time formatting
class DateTimeUtils {
  /// Format timestamp to readable date string
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Format timestamp to readable time string
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format timestamp to full date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  /// Format timestamp for chat messages (relative or absolute)
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time only
      return formatTime(dateTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // Within a week - show day name
      return DateFormat('EEEE').format(dateTime);
    } else {
      // Older - show date
      return formatDate(dateTime);
    }
  }

  /// Calculate days remaining until a deadline
  static int daysUntil(DateTime deadline) {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  /// Check if date is in the past
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// Check if date is in the future
  static bool isFuture(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }
}
