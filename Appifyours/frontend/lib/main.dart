import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class AdminConfig {
  static const String adminId = '68e11e2d22ab170f82f6f6cc';
  static const String shopName = 'kjkugugkyjfjh';
  static const String backendUrl = 'https://appifyours-backend.onrender.com';
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'shopName': shopName,
          'userData': userData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error storing user data: $e');
    }
  }
  static Future<void> storeUserOrder({
    required String userId,
    required String orderId,
    required List<Map<String, dynamic>> products,
    required double totalOrderValue,
    required int totalQuantity,
    String? paymentMethod,
    String? paymentStatus,
    Map<String, dynamic>? shippingAddress,
    String? notes,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'userId': userId,
          'orderData': {
            'orderId': orderId,
            'products': products,
            'totalOrderValue': totalOrderValue,
            'totalQuantity': totalQuantity,
            'paymentMethod': paymentMethod,
            'paymentStatus': paymentStatus,
            'shippingAddress': shippingAddress,
            'notes': notes,
          },
        }),
      );
    } catch (e) {
      print('Error storing user order: $e');
    }
  }
  static Future<void> updateUserCart({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/update-user-cart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'userId': userId,
          'cartItems': cartItems,
        }),
      );
    } catch (e) {
      print('Error updating user cart: $e');
    }
  }
  static Future<void> trackUserInteraction({
    required String userId,
    required String interactionType,
    String? target,
    Map<String, dynamic>? details,
  }) async {
    try {
      await storeUserData({
        'userId': userId,
        'interactions': [{
          'type': interactionType,
          'target': target,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        }],
      });
    } catch (e) {
      print('Error tracking user interaction: $e');
    }
  }
  static Future<void> registerUser({
    required String userId,
    required String name,
    required String email,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'shopName': shopName,
          'userData': {
            'userId': userId,
            'userInfo': {
              'name': name,
              'email': email,
              'phone': phone ?? '',
              'address': address ?? {},
              'preferences': {}
            },
            'orders': [],
            'cartItems': [],
            'wishlistItems': [],
            'interactions': [],
          },
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error registering user: $e');
    }
  }
  static Future<Map<String, dynamic>?> getDynamicConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/get-admin-config/$adminId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting dynamic config: $e');
    }
    return null;
  }
}
class PriceUtils {
  static String formatPrice(double price, {String currency = '$'}) {
    return '$currency${price.toStringAsFixed(2)}';
  }
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    String numericString = priceString.replaceAll(RegExp(r'[^d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('$')) return '$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '$'; // Default to dollar
  }
  static double calculateDiscountPrice(double originalPrice, double discountPercentage) {
    return originalPrice * (1 - discountPercentage / 100);
  }
  static double calculateTotal(List<double> prices) {
    return prices.fold(0.0, (sum, price) => sum + price);
  }
  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }
  static double applyShipping(double total, double shippingFee, {double freeShippingThreshold = 100.0}) {
    return total >= freeShippingThreshold ? total : total + shippingFee;
  }
}
class CartItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  int quantity;
  final String? image;
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.quantity = 1,
    this.image,
  });
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
  double get totalPrice => effectivePrice * quantity;
}
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  void updateQuantity(String id, int quantity) {
    final item = _items.firstWhere((i) => i.id == id);
    item.quantity = quantity;
    notifyListeners();
  }
  void clear() {
    _items.clear();
    notifyListeners();
  }
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  double get totalWithTax {
    final tax = PriceUtils.calculateTax(subtotal, 8.0); // 8% tax
    return subtotal + tax;
  }
  double get finalTotal {
    return PriceUtils.applyShipping(totalWithTax, 5.99); // $5.99 shipping
  }
}
class WishlistItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  final String? image;
  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.image,
  });
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
}
class WishlistManager extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  List<WishlistItem> get items => List.unmodifiable(_items);
  void addItem(WishlistItem item) {
    if (!_items.any((i) => i.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  void clear() {
    _items.clear();
    notifyListeners();
  }
  bool isInWishlist(String id) {
    return _items.any((item) => item.id == id);
  }
}
final List<Map<String, dynamic>> productCards = [
  {
    'productName': 'Charger',
    'imageAsset': 'data:image/png;base64,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',
    'price': '$299',
    'discountPrice': '$199',
  },
  {
    'productName': 'Laptop',
    'imageAsset': 'data:image/png;base64,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cdyBx3IHHcgcdyBx3IHHcgcdyBx3IHHcgUXZEUhHOQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/8QAMxAAAQIDBwMEAAYCAwEAAAAAAAIDAQQRBhASExQVMxYyUAUwMUAgITRBUWAjUiIkQsD/2gAI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zDMMwzDMMwzDMMwzDMMwzDMMwzDMMwzDGZhmGYZhmGaZpF+EBKor7UenzLg3Z9UeRj0hhrwbkkyvuX6VKi/R5f8AZfoqf2j6JE2VZszhszhszhszhszhszhszhszhszhszhszhszhszhszhszhszpszhszhszhszpszpszhszhszhszhszhszhszhszhszhszpszhszpszhszhszhszhszhszhszhszhszhszhszpszpszhszpszhszhszhszpszhszhszhszhszhszhszhszhszhszhszhszhszhszhszhszhszhszhszhszpszhszhszhszhsqyHokRHoqf3R6PL/uj0qVESbLfb4ihhMJggYDCYDAYDAYDAYDAYDAYDAYDAYDAYDCYTAYDCYTCYTCYTCYDCYTCYTAYTCYTAYTCYTCYDAYTCYTCYDCYDAYDAYDAYDAYDAYDAYDAYDAYDAYDAYDCYDBAwlCn/wWH//EAC4RAAEEAQIFAwQCAgMAAAAAAAABAgMREgQUBRATMkAgITEGIjAzI0FRoBUkUv/aAAgBAgEBCAD/AEf0Yq/G2kNrIbWU2sptJTaSm0lNpKbSU2kptJTaSm0lNnKbOU2cps5jZzGzmNnMbKY2UxspjZTGymNjMbGY2MxsZjYzGxmF0cqJa+S59HWOsdU6hmN1b29rONyt7o+OxO72zsels5WUV+ZPwz/ok8rUPxagk4kokojzMyMjISVzVtsX1BKz2fDxiGX29NFFemyzIvkn4Z/0SeVquxCxHCPEkEeZmRkZmRkQcdlhpFg4pFqE+z8dFckcX+Cf9EnlapPsTnYjhHGZ1DMyLLMhJXNVHN0n1NdR6i7S0/BfqyL9U/6JPKmZk0dFRRZYimRkZGRmZGRZZpuMyQLisfFFciOROIN/tNZGpuYzcMNyw3bDdsEnYvxZZfqvlfKdf4JPKVB8I6IossssssvlkXysi1z4ltkfGY39yTovunWOsdY6p1TqDNUrfhNcn9pqmKWX6E9E/wCmTy1QfCPiorlZZkZGRfKyy+VjZnN92t4rInc3ibXCaoSdFEkMxJDqnUGalzfhuuRe5JEd8eqf9MnlqgqD4rHRleiyyy+VlllllliTuQ/5BzRvHK+WcehXuZro39vUEkElEmEmE1r0E4jIJxNwnE/8pxCNflszHds/6ZPKagrRUFaPiHRitKK5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',
    'price': '10000',
    'discountPrice': '30',
  },
  {
    'productName': 'Speaker',
    'imageAsset': 'data:image/png;base64,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',
    'price': '2000',
    'discountPrice': '30',
  },
  {
    'productName': 'Tap',
    'imageAsset': 'data:image/png;base64,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ICAgIDxyZGY6bGk+cG5nPC9yZGY6bGk+CiAgICA8cmRmOmxpPndvbWVuPC9yZGY6bGk+CiAgICA8cmRmOmxpPnRyYW5zcGFyZW50IHBuZzwvcmRmOmxpPgogICAgPHJkZjpsaT50ZWNobm9sb2d5PC9yZGY6bGk+CiAgICA8cmRmOmxpPnBvcnRyYWl0PC9yZGY6bGk+CiAgICA8cmRmOmxpPmZhc2hpb248L3JkZjpsaT4KICAgIDxyZGY6bGk+bGFwdG9wPC9yZGY6bGk+CiAgICA8cmRmOmxpPnBlb3BsZTwvcmRmOmxpPgogICAgPHJkZjpsaT5hZHVsdDwvcmRmOmxpPgogICAgPHJkZjpsaT5wYXBlcjwvcmRmOmxpPgogICAgPHJkZjpsaT5oYW5kPC9yZGY6bGk+CiAgICA8cmRmOmxpPndvcmtpbmc8L3JkZjpsaT4KICAgIDxyZGY6bGk+ZG93bmxvYWRhYmxlPC9yZGY6bGk+CiAgICA8cmRmOmxpPnRyYW5zcGFyZW50PC9yZGY6bGk+CiAgICA8cmRmOmxpPmNsb3RoaW5nPC9yZGY6bGk+CiAgICA8cmRmOmxpPmRvY3VtZW50PC9yZGY6bGk+CiAgICA8cmRmOmxpPmVsZW1lbnQ8L3JkZjpsaT4KICAgIDxyZGY6bGk+Z3JhcGhpYzwvcmRmOmxpPgogICAgPHJkZjpsaT5yZWFkaW5nPC9yZGY6bGk+CiAgICA8cmRmOmxpPndyaXRpbmc8L3JkZjpsaT4KICAgIDxyZGY6bGk+ZmVtYWxlPC9yZGY6bGk+CiAgICA8cmRmOmxpPm9mZmljZTwvcmRmOmxpPgogICAgPHJkZjpsaT5odW1hbjwvcmRmOmxpPgogICAgPHJkZjpsaT5waG90bzwvcmRmOmxpPgogICAgPHJkZjpsaT53aGl0ZTwvcmRmOmxpPgogICAgPHJkZjpsaT50YWxraW5nPC9yZGY6bGk+CiAgICA8cmRmOmxpPmVsZWN0cm9uaWNzPC9yZGY6bGk+CiAgICA8cmRmOmxpPnBuZyBlbGVtZW50PC9yZGY6bGk+CiAgICA8cmRmOmxpPm1hbmFnZXI8L3JkZjpsaT4KICAgIDxyZGY6bGk+c2ltcGxlPC9yZGY6bGk+CiAgICA8cmRmOmxpPnRhYmxldDwvcmRmOmxpPgogICAgPHJkZjpsaT5kaWFyeTwvcmRmOmxpPgogICAgPHJkZjpsaT5zdWl0PC9yZGY6bGk+CiAgICA8cmRmOmxpPmNvbXB1dGVyIG5ldHdvcms8L3JkZjpsaT4KICAgIDxyZGY6bGk+dXNpbmcgbGFwdG9wPC9yZGY6bGk+CiAgICA8cmRmOmxpPnlvdW5nIGFkdWx0PC9yZGY6bGk+CiAgICA8cmRmOmxpPmNvcHkgc3BhY2U8L3JkZjpsaT4KICAgIDxyZGY6bGk+aGFpcnN0eWxlPC9yZGY6bGk+CiAgICA8cmRmOmxpPmxvbmcgaGFpcjwvcmRmOmxpPgogICAgPHJkZjpsaT5pc29sYXRlZDwvcmRmOmxpPgogICAgPHJkZjpsaT5hcHBhcmVsPC9yZGY6bGk+CiAgICA8cmRmOmxpPmhvbGRpbmc8L3JkZjpsaT4KICAgIDxyZGY6bGk+bG9va2luZzwvcmRmOmxpPgogICAgPHJkZjpsaT5ibGF6ZXI8L3JkZjpsaT4KICAgIDxyZGY6bGk+amFja2V0PC9yZGY6bGk+CiAgIDwvcmRmOkJhZz4KICA8L2RjOnN1YmplY3Q+CiAgPGRjOnRpdGxlPgogICA8cmRmOkFsdD4KICAgIDxyZGY6bGkgeG1sOmxhbmc9J3gtZGVmYXVsdCc+UE5HIEZlbWFsZSBtYW5hZ2VyIGNvbXB1dGVyIGZlbWFsZSBhZHVsdC4gPC9yZGY6bGk+CiAgIDwvcmRmOkFsdD4KICA8L2RjOnRpdGxlPgogPC9yZGY6RGVzY3JpcHRpb24+CgogPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9JycKICB4bWxuczpleGlmPSdodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyc+CiAgPGV4aWY6Q29sb3JTcGFjZT4xPC9leGlmOkNvbG9yU3BhY2U+CiAgPGV4aWY6RXhpZlZlcnNpb24+MDIzMTwvZXhpZjpFeGlmVmVyc2lvbj4KICA8ZXhpZjpQaXhlbFhEaW1lbnNpb24+NjEyNDwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgPGV4aWY6UGl4ZWxZRGltZW5zaW9uPjQwODI8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogPC9yZGY6RGVzY3JpcHRpb24+CgogPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9JycKICB4bWxuczpwZGY9J2h0dHA6Ly9ucy5hZG9iZS5jb20vcGRmLzEuMy8nPgogIDxwZGY6QXV0aG9yPnJhd3BpeGVsLmNvbTwvcGRmOkF1dGhvcj4KIDwvcmRmOkRlc2NyaXB0aW9uPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6cGhvdG9zaG9wPSdodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvJz4KICA8cGhvdG9zaG9wOkNvbG9yTW9kZT4zPC9waG90b3Nob3A6Q29sb3JNb2RlPgogIDxwaG90b3Nob3A6SUNDUHJvZmlsZT5zUkdCPC9waG90b3Nob3A6SUNDUHJvZmlsZT4KIDwvcmRmOkRlc2NyaXB0aW9uPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6cGx1cz0naHR0cDovL25zLnVzZXBsdXMub3JnL2xkZi94bXAvMS4wLyc+CiAgPHBsdXM6TGljZW5zb3I+CiAgIDxyZGY6U2VxPgogICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSdSZXNvdXJjZSc+CiAgICAgPHBsdXM6TGljZW5zb3JVUkw+aHR0cHM6Ly93d3cucmF3cGl4ZWwuY29tL2ltYWdlLzE1NDU3MjE3PC9wbHVzOkxpY2Vuc29yVVJMPgogICAgPC9yZGY6bGk+CiAgIDwvcmRmOlNlcT4KICA8L3BsdXM6TGljZW5zb3I+CiA8L3JkZjpEZXNjcmlwdGlvbj4KCiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0nJwogIHhtbG5zOnRpZmY9J2h0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvJz4KICA8dGlmZjpCaXRzUGVyU2FtcGxlPgogICA8cmRmOlNlcT4KICAgIDxyZGY6bGk+ODwvcmRmOmxpPgogICAgPHJkZjpsaT44PC9yZGY6bGk+CiAgICA8cmRmOmxpPjg8L3JkZjpsaT4KICAgPC9yZGY6U2VxPgogIDwvdGlmZjpCaXRzUGVyU2FtcGxlPgogIDx0aWZmOkltYWdlTGVuZ3RoPjQwODI8L3RpZmY6SW1hZ2VMZW5ndGg+CiAgPHRpZmY6SW1hZ2VXaWR0aD42MTI0PC90aWZmOkltYWdlV2lkdGg+CiAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICA8dGlmZjpQaG90b21ldHJpY0ludGVycHJldGF0aW9uPjI8L3RpZmY6UGhvdG9tZXRyaWNJbnRlcnByZXRhdGlvbj4KICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogIDx0aWZmOlNhbXBsZXNQZXJQaXhlbD4zPC90aWZmOlNhbXBsZXNQZXJQaXhlbD4KICA8dGlmZjpYUmVzb2x1dGlvbj4zMDAvMTwvdGlmZjpYUmVzb2x1dGlvbj4KICA8dGlmZjpZUmVzb2x1dGlvbj4zMDAvMTwvdGlmZjpZUmVzb2x1dGlvbj4KIDwvcmRmOkRlc2NyaXB0aW9uPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6eG1wPSdodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvJz4KICA8eG1wOkNyZWF0ZURhdGU+MjAyMy0wOS0wNFQxMDoyMDoxOCswNzowMDwveG1wOkNyZWF0ZURhdGU+CiAgPHhtcDpNZXRhZGF0YURhdGU+MjAyNC0wOC0yMlQwOTo0ODoyMiswNzowMDwveG1wOk1ldGFkYXRhRGF0ZT4KICA8eG1wOk1vZGlmeURhdGU+MjAyNC0wOC0yMlQwOTo0ODoyMiswNzowMDwveG1wOk1vZGlmeURhdGU+CiAgPHhtcDpSYXRpbmc+NTwveG1wOlJhdGluZz4KIDwvcmRmOkRlc2NyaXB0aW9uPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6eG1wTU09J2h0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8nPgogIDx4bXBNTTpJbnN0YW5jZUlEPnhtcC5paWQ6MDVjM2EyMzEtN2E1ZS00ODgzLTk2ZmItZDc4YTA5NDMxMTJmPC94bXBNTTpJbnN0YW5jZUlEPgogIDx4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ+RTdFODYwNjU4MjgxNUUzNzZFQzYyNEFFMEU4MDFDMUE8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KIDwvcmRmOkRlc2NyaXB0aW9uPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6eG1wUmlnaHRzPSdodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvcmlnaHRzLyc+CiAgPHhtcFJpZ2h0czpXZWJTdGF0ZW1lbnQ+aHR0cHM6Ly93d3cucmF3cGl4ZWwuY29tL3NlcnZpY2VzL2xpY2Vuc2VzPC94bXBSaWdodHM6V2ViU3RhdGVtZW50PgogPC9yZGY6RGVzY3JpcHRpb24+CjwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9J3InPz4=',
    'price': '30000',
    'discountPrice': '30',
  }
];
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
          elevation: 4, shadowColor: Colors.black38, color: Colors.blue, foregroundColor: Colors.white),
      cardTheme: CardThemeData(
          elevation: 3, shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
    home: const HomePage(),
    debugShowCheckedModeBanner: false,
  );
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  final CartManager _cartManager = CartManager();
  final WishlistManager _wishlistManager = WishlistManager();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _filteredProducts = List.from(productCards);
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);
  void _onItemTapped(int index) {
    setState(() => _currentPageIndex = index);
  }
  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(productCards);
      } else {
        _filteredProducts = productCards.where((product) {
          final productName = (product['productName'] ?? '').toString().toLowerCase();
          final price = (product['price'] ?? '').toString().toLowerCase();
          final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return productName.contains(searchLower) || 
                 price.contains(searchLower) || 
                 discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _currentPageIndex,
      children: [
        _buildHomePage(),
        _buildCartPage(),
        _buildWishlistPage(),
        _buildProfilePage(),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Deena',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 20),
                            if (_wishlistManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_wishlistManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (searchQuery) {
                            setState(() {
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search products by name or price',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.filter_list),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Search by product name or price (e.g., "Product Name" or "$299")',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            enableInfiniteScroll: true,
                            viewportFraction: 0.8,
                            enlargeFactor: 0.3,
                          ),
                          items: [
                            Builder(
                              builder: (BuildContext context) => Container(
                                width: 300,
                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                                                const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6.0, height: 6.0, margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.4))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          child: Stack(
                            children: [
                              ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 5,
                                itemBuilder: (context, index) => Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12, left: 6, top: 6, bottom: 6),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child:                                         smallCards[index]['imageAsset'] != null
                                            ? Image.network(
                                                smallCards[index]['imageAsset'],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(Icons.image, size: 30, color: Colors.grey)
                                        ,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        smallCards[index]['categoryName'] ?? 'Category',
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (false true)
                                        Column(
                                          children: [],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.chevron_left, color: Colors.blue, size: 16),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.chevron_right, color: Colors.blue, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Color(0xFFFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            final product = productCards[index];
                            final productId = 'product_$index';
                            final isInWishlist = _wishlistManager.isInWishlist(productId);
                            return Card(
                              elevation: 3,
                              color: Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          ),
                                          child:                                           product['imageAsset'] != null
                                              ? Image.network(
                                                  product['imageAsset'],
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 40),
                                          )
                                          ,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            onPressed: () {
                                              if (isInWishlist) {
                                                _wishlistManager.removeItem(productId);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Removed from wishlist')),
                                                );
                                              } else {
                                                final wishlistItem = WishlistItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price: double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0,
                                                  discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                      : 0.0,
                                                  image: product['imageAsset'],
                                                );
                                                _wishlistManager.addItem(wishlistItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to wishlist')),
                                                );
                                              }
                                            },
                                            icon: Icon(
                                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                                              color: isInWishlist ? Colors.red : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] ?? 'Product Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                PriceUtils.formatPrice(
                                                                                                    product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? PriceUtils.parsePrice(product['discountPrice'])
                                                      : PriceUtils.parsePrice(product['price'] ?? '0')
                                                  ,
                                                  currency:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? PriceUtils.detectCurrency(product['discountPrice'])
                                                      : PriceUtils.detectCurrency(product['price'] ?? '$0')
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: product['discountPrice'] != null ? Colors.blue : Colors.black,
                                                ),
                                              ),
                                                                                            if (product['discountPrice'] != null && product['price'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 6.0),
                                                  child: Text(
                                                    PriceUtils.formatPrice(PriceUtils.parsePrice(product['price'] ?? '0'), currency: PriceUtils.detectCurrency(product['price'] ?? '$0')),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star_border, color: Colors.amber, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                product['rating'] ?? '4.0',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This is a detailed description of the product.',
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }
  Widget _buildCartPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        automaticallyImplyLeading: false,
      ),
      body: _cartManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(PriceUtils.formatPrice(item.effectivePrice)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        _cartManager.updateQuantity(item.id, item.quantity - 1);
                                      } else {
                                        _cartManager.removeItem(item.id);
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    onPressed: () {
                                      _cartManager.updateQuantity(item.id, item.quantity + 1);
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (8%):', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(PriceUtils.calculateTax(_cartManager.subtotal, 8.0)), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(5.99), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  Widget _buildWishlistPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        automaticallyImplyLeading: false,
      ),
      body: _wishlistManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _wishlistManager.items.length,
              itemBuilder: (context, index) {
                final item = _wishlistManager.items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                    title: Text(item.name),
                    subtitle: Text(PriceUtils.formatPrice(item.effectivePrice)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final cartItem = CartItem(
                              id: item.id,
                              name: item.name,
                              price: item.price,
                              discountPrice: item.discountPrice,
                              image: item.image,
                            );
                            _cartManager.addItem(cartItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                        ),
                        IconButton(
                          onPressed: () {
                            _wishlistManager.removeItem(item.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  Widget _buildProfilePage() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Profile Page', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (_cartManager.items.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cartManager.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.favorite),
              if (_wishlistManager.items.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_wishlistManager.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Wishlist',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                                GestureDetector(
                    onTap: () => _onItemTapped(0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Icon(
                          Icons.home,
                          color: _currentPageIndex == 0 ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Home',
                          style: TextStyle(
                            color: _currentPageIndex == 0 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Stack(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: _currentPageIndex == 1 ? Colors.blue : Colors.grey,
                            ),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cart',
                          style: TextStyle(
                            color: _currentPageIndex == 1 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Icon(
                          Icons.favorite,
                          color: _currentPageIndex == 2 ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wishlist',
                          style: TextStyle(
                            color: _currentPageIndex == 2 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Icon(
                          Icons.person,
                          color: _currentPageIndex == 3 ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: _currentPageIndex == 3 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }