import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> icons = {
    'account_balance_wallet': Icons.account_balance_wallet,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'trending_up': Icons.trending_up,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'receipt_long': Icons.receipt_long,
    'medical_services': Icons.medical_services,
    'payments': Icons.payments,
    'business': Icons.business,
    'card_giftcard': Icons.card_giftcard,
    'more_horiz': Icons.more_horiz,
  };

  static String getIconName(IconData icon) {
    return icons.entries
        .firstWhere(
          (entry) => entry.value.codePoint == icon.codePoint,
          orElse: () => const MapEntry(
            'account_balance_wallet',
            Icons.account_balance_wallet,
          ),
        )
        .key;
  }

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.account_balance_wallet;
  }
}
