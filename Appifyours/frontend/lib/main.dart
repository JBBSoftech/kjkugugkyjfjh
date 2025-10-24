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
    'productName': 'Product Name',
    'shortDescription': '100% cotton, Free size',
    'imageAsset': 'data:image/png;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA0JCgsKCA0LCgsODg0PEyAVExISEyccHhcgLikxMC4pLSwzOko+MzZGNywtQFdBRkxOUlNSMj5aYVpQYEpRUk//2wBDAQ4ODhMREyYVFSZPNS01T09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0//wAARCARLAzgDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD06iiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKY0safekRfqaAH0VB9ttc4+0w5/3xUqSI/3HVvoc0AOooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiigkAZJAHvQAUVTn1XTrc4nvrZD/tSAVAPEOik4GqWmf+uop2A06KrQ6jYzjMN5A/+7IDVkEEZByKQBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRQSAMnpQAUjMFUsxAA6kmsjUNegtspBiWT1/hH+Nc1eX93fN+9kJH90cAfhTSFc6e88Q2NrkKxmYdk6fnWDeeK7yTIto0iHr941nNbrHGZJ3CJ6mse81UKStpGAP7zcmqURNl+51PU7jJe4mYem4gVmzNdMfmZj+NZk93cy/flY/jVRnfP3j+dXykcxpSGZeu4VEt5cwtmOWRD6qxFVI7iVTxI351bRvOHzAE+opMaNKz8W61aEbbx5FH8Mvzj9ea6bTPiFG5CalaFP8AppEcj8Qa4R4CD0oWI+lJpFantVhqNnqMPm2Vwkq99p5H1HarVeL2clxaTia1leKUdGQ4Nd74f8WrclbbVNsUx4WUcK59/Q/pUNDudXRRmikMKKKKACiiigAooooAKKKKACiiigAooooAKKKjnnitoWmnkWONBlmY8CgCSsfVvEum6VlJZfNmH/LKLlvx9PxrmNf8V3F2Wg08tBb9C/R3/wAB+tcmykk+/WtIw7kOXY6HUvHepXGVso47ROx++35nj9K5q71HULxibu9uJvZpDj8ulL5JbtTmt1jXMn5VokkQ22Z5XJ6U0pjqBVp/QDAqFlx1piIwADxirtpqOoWhBtL25ix2SQ4/LpVEkZ6inRvg1LQ0zsNO8darb4F0sV2vfcNjfmOP0rqtM8ZaVfbVmZrSQ9pemf8Ae6V5vbLFMMOMHsRU7WjRnnlT0NZtI0TZ7GjK6hkYMp6EHINLXlemajqGlsDZzlUzzG3KH8P8K7XR/FFre7YroC2uDwAT8rH2P9DUtDub9FFFIYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRUF5dxWkJklP0HrQA64uIraIySsFUfrXK6rrctyTHGSkX90Hr9ap6pqkl1KWZuOwHQVmbix5q1ElssLmRqvRxpBEZZOgFV7VRnJp18JLiSO0gGWb9Pc1QjGvpp9QuPLiVm/uotSweHCw3Xc23/AGI+T+dbXl22k23Xk/eb+JzVON573M0xMVqvIRTjf9T6UX7BbucPeFo7qWNTwjlRUDrKoywYD3rRlREnmuZcDc5Kj0H+NUWL3Mmeij9P/r1dyLEO8g1btLlN4VjtPvVeUqo8tQDUTRkJk/lSeo1odVDGsybWHPY0n2XBxisbSdTMEiw3DfujwGP8P/1q6kqGANZvQtalEQY7U4RAjBFXdgxTCuKQzf8ADWvPbsljfuWiPEUrHlfY+3vXZV5fsDDBHFdd4X1Zpk+wXLZljH7tj/Gvp9RSYzoqKKKQBRRRQAUUUUAFFFFABRRRQAUUUUARzzR28LzTOEjQZYntXn2v6zLqc2BlLdT8kfr7n3/lWh4n1Y3c5toW/cRHnH8bf4Cuafk1pGPUiTK7KSackG41Kqc1aiQVdybEPlLEm4iqsdpPfzlYVyR1J4C/U1pi2e8uFgQ4HVm/uj1rTnkttLtAqrhRwqjqx/z3pXsO1zLOg20FpK80hkkCk7s7VBriZd4crISWHYnNdt5c17G95fEiFFLJGOAf/rfzrlY4VgDXExw2cgen/wBehMGiq1qyx73ZU46HrUKhzkoDx6VOxe6l9EH6f/XolkWJfLi6jv6f/XpiFtr54WHmAsv6iun065iuIhhgyH9K5NYflJkJyelOs7mawnEgU4P3lPG4f41LRSZ2wgAO2kaAdCKfaTx3NtHPG25SODU7gYzUFF7R9duNPIhuS09t055ZPp6j2rs7eeK5hWaBw8bDIIrznIq9peozabOXi+aNv9ZGeh9x6GkM7yiobW5iu7dZ4H3I36exqakAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUVnX2u6Vp523d/DG/8Ac3bm/Ic0AXbiZLeFpJDhVridX1N7qYknjoB6Vd1/VPOby4yRGOnauZkcs1XFEtiM5Y9afH1qKpIzzVkmlAcKKZp2oodfu4DgLFDkt9OTSRNyg965vRpFuPEI80nbcOwbBxnPOP0oSumDdmjpFjfUrg3M4IgH3FPcf561nazqimNoom2wL95h/F7D2q7qN01zJ9jshlehK9D7fSsPXLYRyRWcZzgb5X9T2ApLcbMZjJeSkn5UH6f/AF6SeRYx5cXUfp/9epLiVYl8mHqOCfT/AOvUKxiJd8nX09KskYqCNd79anAVI9zjk9BVYEySAkfKO1XbaAzyb5Pu+nr/APWqWNFWWLzIi5UA9j610Xh+7Nzp2xzl4TsOfTt/n2rGu5UZmRPujqRUvhiQrczx9mQH8j/9epexXU6jPFMJpA3FRs1SMlBqaKR4ZUmhbbJGwZT71UDVNG1ID0XT7tL6yiuY+jjkeh7irNcr4Su9lxLZsflceYn1HB/pXVUhhRRRQAUUUUAFFFFABRRRQAVk+Ir82VgUjbEs2VUjsO5rWrhfEd4bnUpMHKRfu1/Dr+tOKuxMxZW5qGnueaZWxmPSrKcCqqnmrCnikxofpWorHrslm2ArQ5LHsRz/ACqdIDf3BvboYg/5Zo3dfU+3euXtpl/4SdHfBQzbWz0x0roL+7l1Kf7JZg+V3PTd7n0FJoEyrrWrB42jibbAv3j/AH//AK1cwxkvZcn5UX9P/r1ua/ZrEbe0iPGPMlfuT0rGuJliHkwdRxkdv/r01sDGTyrCvkw9e59P/r1GkYjXzJevp6U6OJYV8yX73p6f/XqEl7iT0UfpTET277mMrjgcKKsLC08ZeUfIen/1qbawKxAP3B+tWLm480iGAfKOpHf/AOtUMtFnwvcMjXNi5yF+df5H+ldAzZQVyGkSFPEC8/eDKf8Avn/61dTv/d0mCGs+DTo5eaqyPzTFkwaQzpNI1JrC43jJhf8A1iD+Y967aORJY1kjYMjDII7ivMYJveun8Paolvm2uJAsJ+ZGY8Ke4+lJjOpopsckcq7o3V19VOadSAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACs/WdZstFtDcXsmM8Ii8s59AKdrOqW+j6bLe3J+VB8qjq7dgK8N8Qa3daxfyXF1JljwAOiD+6Pb+dNITZt+IvHmpakzxW0htbc8BI2wSPdup/Cq3g20a71B9RufmiteVB6NIen5dfyrlSc16NpFuNP0KGADDMN7/7x/yB+FUhE11KZJCSetVgKVjlqUVZIhoQ/NQ3SmqfmoAt79oz6An9K5vRoPNmDj74ICDOOTW9K2IXP+w38q53SS63sDqCVjcSMM8cVUdmS90dgyw6Ra7nw8z8cfxH0+lcnqt7I0pLEmWTknHQe1dLBbSajObu7/1ZPA7H2+lYWrtA2oy3QYFRhVPbj0qFuW9jKSIQp5kv3vT0/wDr1A26d8nhR+lSMXupM9FH6f8A16bM4jHlx9v0qyQBUSLGo4zzVgyPKRBAPvcHHf8A+tVWOPBBP3j0rQheO0j3nlz29f8A61QykQ3EAhiMeQXYYJpND/d6vsHQowqOdpZFedzyRx/9ak0UkavFnqQ2c/Q0ugdTq88VCzU8nioHPNSUPDVNG1VA1SxtzQBsabcfZtQtps/dkAP0PB/nXodeWhv3Zx1xXptpJ5tpDL/fjVvzFJjJaKKKQBRRRQAUUUUAFFFFAEN5N9ntJpv7iE15tcMSSSeTya7zxE+zRp8fxYX8yK8/nPJq4EyIGNJmgmm5rQgkU81Yj7VVXrVhDxmkxo57T9smoOWIDO2FJ9S1dfO9vo1t5cYDzOM8/wAR9T6CuL01Wa8SVSP3R3nP1rrbOxadzfagcg/MA/f3Pt7U5hE5vWLi4EimTd5k43Bj1x7VTjhW3TzZvvfy/wDr1r65dQTXxuhyEXYpPf6CsPEl3LuPCD9P/r0LYT3GHfcyZPCj9P8A69EsgjHlx9R+n/16fPKIx5UXUcHHamJGIl8yTr6elAE8HmNGkKDk9a0ZIorK2UcGR+p9f/rVTt5liiEmPmboKlSKSYfaZycH7vv/APWqGWitY4GvQlf73P5GunDfu65nSoz/AGtk/wAJ3V0QP7ukwRBM3NQ7+aWZuarluaAL8MvNadvIHXawyD1FYUb4NaFrLgikMyZtU1PQNVeKKd9gO5DnBKnp9fTmuz8PeP4rkrDqI57uo5H1Hce4/KuX8V24msoroD5oTgn/AGT/APXrlFJVgykgjkEdqe4tj6LiljmiWWJ1dHGVZTkEU+vJ/BniySxmFvdHdAxy6+n+0Pf1HevVo3WSNZI2DIwyCOhFS1Yadx1FFFIYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFBOBRWX4gvfsmnuAcM4I+g70JXA81+I+vNe6l9lhc+Rb8KPVj1NcLnNWtSna4vZJGOSzE/nzVWrZKLOnQie/gjPKlwT9BzXoMj5jA9q4fQ1/wBO3/3V/nXYF8oKpLQTeoo606owadmmIG6UxT81KxpgPzUAS3B/cSf7jfyrG0WVVuooGXd50iKfTHetW5P7h/8Acb+VZOkQCWbd1ZSAgzjk1S2ZL3R02pXTXMv2KxGV+6SvAPt9K5nVrR11E24fKRqMt2zXWFYdItSz4eZ/T+I+g9q5PVbyRpST/rZOScdB7VMfIqXmUriRYl8qLgjr7f8A16iWMRLvk6/yqVIhCnmS9fT0/wDr1Ad0756KP0qhCI7NMGxwvar1pAbiUPNynp6//WqoCokWMDvzVlpHlIggGd3Bx3/+tUMpBezozlUxsXv2qDSW3azEw6En+Rqa5txDEY85dhgmotJULq8YHRSf5Gl0DqdKx4qs55qwx4qpIeakoA3NSxtVbdzUiNzQIvq3y16Vo5zpFmf+mK/yry0yYQ/SvVrCPytPtoz1SJR+lJjRYooopDCiiigAooooAKKKKAMfxR/yB2/66LXBz9TXoPiJN+iz4/hw35EV59OOTWkSZFYmm5obrSZqyCROtWM4jY/7J/lVZOtWG4gf/cP8qTA5zSZTHfQLkBXdQxPpmupvbmbVLn7NaAiIHknjPufb2rmdHVGuVQkB3KohPqa7C5lg0e28mEBpjzz3Pqfb2pz3HHY5rXdPCahHChPlpGCzHqTWZcTCMCCAcjjI7e1XNXmuFmCuG82YbiT1waqJEttH5kp+bsPT2oWwmRJGIEMkn3uw9P8A69Q/NcPk8KP0p+HuZNx4UfpRLIEHlxduMigC5aQKzAv9xe1WLq6+0OIoR8i9T6//AFqpwiR0SBB25q/MkVnbqinMj8k9z/8AWrNlog0P95fXDkfdWtcH91WdoaqJ70rjATt9KvKf3VDBFaY81ATUkp5qEmgCRDVy3fkVQBqxC3NAGje4m06WNujKRXFAY4NdfNJ/ozfSuTkH71/rQhMRGaN1dDhlOQa9V+H2uC4thp8rdBuhz2HdfwPT2ryrFbPhu7e2vkKNtZXBB+vH88U2gT1PcqKr2Nyt5ZxXCdHXJHoe4qxWZYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFcT4xuy/2kKeI4yo/Lmu1dgqMx6AZrzfW3Mtvck9WRj+hq4ImR5lIcyufc0gof77fU0gqRmno/Ekh+n9a6dHygrldLb5pR7A10EEmYxWsfhM3uXA1PDVWD04PQBMTTQfmqPdQrfNQBLcH9y/+438qx9LMgvoHUErG4kYZ44rVnP7tv90/yrP0eVVuooWXPnSop9Md6tbMT3R0kFtJqM5u7v8A1ZPC+vsPasLVzA2oy3QYFBgLgccelb2pXTXMn2KxGV+6Svf2+lcxqtrINRNvvykYGW7ZqFuWygxe6lz0Ufp/9ekmcRjy4+o/SpZ5FiXyouo6+3/16hWMRrvk6/yqiRsceDk/ePQVoQtHZx7yMueg9f8A61ZyuzTBscL2q9aW5uJQ833PT1/+tUSKRXnaSRXnc9Rx/wDWpdFB/tJN2c85z9DUt7MjSFUxsXv2/CmaM2/U9w75P6Gl0Dqb7n5apyHmrUh+WqMrc1JQm7mnq9Vi1OD0xGnp0Ru9RtrYc+ZKoP0zz+levAYGK84+H9kbnWJLxh+7tkwD/tt/9bP516PUsaCiiikMKKKKACiiigAooooAhvIftFnND/fQivNLhSCc9Rwa9RrgfEVobbVJgBhZD5i/j/8AXzVRYmc8/WmVLIOairUzJY+tWJP+PaT/AHG/lVeLrVib/j0l/wCubfypDOc0pW+1xzKQPJIfn17V1tnYlmN9qByT8+H/AJn/AArldGm8vUbdSQEaRd5I7Dmumu55tWufItwVgBySf5n/AApz3FHYx9auYJb17sA4A2JnqaxcSXcm5jhB+nsK1NasAuqeUpbyo0GWPUms64nCjyYPocfyFC2Gxk8oT91Dx2OO1MRFhXfJ1/lT1jWBN8n3vT09qhw1w+Two/SkI0IJlhhD4+dhkCpEhkkH2m4J+bkZ7/8A1qjs4VZg0mNi9jU11cm6kEcQ/dr39ff6VDLHeHkKLf7uoWran91VXQXLwai54JH9KlDfuqAIZDzUWac55pmaAHA1LG2DUGaerYoAsXMuICM9qwW5Yn1rQvJf3eKz1IYcHkdaaExMVYsmKXII9P8A69QVJb/64fQ0xdT1/wAIXe5Z7Vj0xIn49f6fnXS1wPhu48nVrbnh/kP4j/HFd9WbLQUUUUhhRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFAFfUG26fOw/uGvPrwb9yH+IEfnXf6oM6bcY/uGvP7v7xrSBEjzS4UpcOp6g1HmtLxBB5OpyMB8sh3D8eazKl7lLYt6a225I/vKRW7byY4rnbNtl1GffFbSNgg1pB6WM573NEPS76rK+RS7qoRZ309G5qoGqWNuaBlqU/If90/yqhpMCyzbjyykBBnuauSHK/8AAT/Ks/TfMF7CyglY3DsM8cU1syXudgVh0i23Ph5m44/iPoPauT1S9dpWJ/1snJIHT6V0sFtJqM5u7v8A1ZPA7N7D2rC1byDqM10GBUYC46celQtzR7GUkQiXzJev8v8A69QEtO/oo/SpGL3Unoo/T/69JK4jHlx9f5VRIgKiRY1HfmrLSPKRBBn5uDjv/wDWqpHHggn7x6CtCFo7SMueXPQev/1qhlIhubcQxGPILsME0mjKF1IqOg/wqOdpJEedzgnp/wDWp+h5+3fNnOOc/Q0ugdTZmbANZ0r81ZuZMA1mySc9aSGOL0B6rl+a6zwFoZ1PVBezofstowbkcO/Yfh1/KgDvPCWlHSdChikGJ5P3kv8AvHt+AwPwraooqCgooooAKKKKACiiigAooooAKwvFdibiwFyg+eDJPuvf/Gt2kYBlKsMgjBBoA8nmXmoCK2te01tOvmiAPlP80Z9vT8KxiMGtUyGh8XWrE/FnN/1zb+VQRdasXP8Ax4z/APXJv5UxGBoqo90IiwDyMqKT711l3cQaTb+RbgGUjPP/AKE3+FcfpKuLxLhGAMJDDjPPauss7Hy917qDfN9/D9vc+/tRPcI7HLatNcCfynD+bINzE9Tmqyxpax+ZJgufT+QrS1e5he+lu8HLfKueprICvdSF3OF/zwKa2ExgV7h9zcKP88Uk0gUeXF9OKfPKB+6h+nH8hTVRYF3v970oGWYhJKqQJxxz/wDXq9cJFZwrEnLsMk9z71VhnEEIYAF2GcVIsMhU3NwTluRnqfes2UTaKFW11LZjaBxj6Um790KTQ1MemakG6gf0qIt8goAazc03NMLUm6mA/NLvxUW6o5HwKAI7mTccVQWQrKXX1qaZ8KTVQGkwRo5DKGHQ1NYrvuVFU4CTB9DitLSEzKXouKx1unSlLu3cdVlQ/qK9Prym0OZIx6uv869WHSpZSCiiikMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAiu08y0mT+8hH6V53eDk16SelcFrFuYbuWPHRjirgTI4rxJbebbLMo+aM4P07f1rlhXe3cYdGRujDBribuBra5aNh0NOS6ii+hECQcjqK14JRIgP41j1ZtZdjbfypRdmOSujYjftUuapq4IBFTo2RWpmTA1LG3NQCnoeaQy9nK/gf5VU0qZUuY4SufNlRT6YzzViI5GPY/yqvpcCyTF2xuUgKCeMmqWzE90dNqV21xL9isRlc7SV4B9h7VzGqW0g1FrbflYwMntmutKw6RbFnw8zccdWPoPauT1S9cyt/z1fkkDpUR8ipeZTnkWFfKi4I6+3/16hWMRrvk6/yqVIhEvmy8H0Pb/wCvUDFp39FH6VQhFdnmDY4Xmr1pbm4lDzfc9PX/AOtVQFRIsYHfmrLSPKRBAM7uDjv/APWqGUgvZ0aQqmNi9+1Jorb9QZh0P+FFzbiGIx7hvbgmjRVC6g6joB/Sl0H1H3suHYe9UGbJp9zJumf/AHjT9PsbnUryO1tImklkOAB29z6CgRPo2l3OsajHZ2o+d+WY9EXuxr2zStOt9K0+KytVxHGOp6se5PuaoeF/D0GgaeIlxJcSczS4+8fQewrbqG7lJBRRRSGFFFFABRRRQAUUUUAFFFFABRRRQBQ1nTI9UsWhbCyDmN/7p/wrzW7gkt53hmQpJGcMPQ16zWH4k0JdUh86ABbuMcH++PQ007CaPPkODVm4OdPuD/0yb+VUpVeCVo5UZHU4ZWGCDUvm7rG6X0iY1oSZGizeVqlurECMyAucdhXR3Es+sXJihykCnPPb3Pv7Vz2iqkl0ISwV5XCKcZPvXVXt1DpcH2a1AMv549z7+1OW4o7HL6tYj+1XjXPkxgDJPJqhczD/AFMA4HHH8hVnVJZ/tBgIfzW5cn7xz2qARpaR75OXPp/IU+giIItum9yC3t/IVCFed9zcKKeFe4cu+Qo9P5CkmkGPKiHtxQBfs4ULCSTGxeQD0qW6uTdy4jB8tf196rRLJPshTgd//r1dulitY1gj5YjJ9T7ms2WJozl9I1KQ9Wqmx+WrulhRo+pbMbd2Bj8KoNQA0mm5pTTTTAC2BVeR806R+Kru+0ZNAiKds/KKhFBOTk0VBRPBIQNnUMenvXQafH5cSjvWLp0PmTbj91a6CHqKpCZs6SnnajaRD+OZB+teqV534Nt/P1tHx8sCFz9eg/nXolSxoKKKKQwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigArm/FFp8yXCjhhtb610lQXtst3ayQt/EOD6HtTTsJnl90mCa53WrTzY/NUfOtdjqFs0Ujo64ZTgisO5j6gitdzPZnFCgcHNXtStDDKZEHynrVIVm1YtO5bt58cMeKuo+KyFODVmGbHB6VcZdCWjWR81KprPjlx3q1HKDTYIv25y4Hsf5VVsFkN7GUGVjcO3pwamtWzOo9c/wAqbp84iuBHtyZZVXnoBnmqjsyZbo6aC2k1Gc3d3/qyeB0z7D2rA1QQnUZ7rcCoOFx0H0roNSu2uZPsViMr90le/sPauW1K3kOovb7srFjJxxUoplJi91J6KP0/+vSTOsY8uPr/ACqWeRYV8qLqOvt/9eoVjEa75OD/ACqhDY48EE/ePQVoQvHZxl2GXPb1/wDrVnI7NMGxwvOKvWlv9plDzfcHb1/+tUSKRXneWRHuHPJ6f/WqTQs/bGznOOc069nRpCExsXv2/CjRDvvpGHGaXQOo7StGvdb1Breyi3HJLOeFQZ6k1674c8OWegWuyAb7hwPNmI5b2HoParulWFrp9hHBZwrEmMkAdT6k9zVyobuUkFFFFIYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAYXiLw5Dq8ZliIivFGFfsw9G/xrz2a1ubFr62u4mjkWBuD356g9xXr9cz49Rf+Efd9o3gkBsc4waqL1E0eY6Uji7W5RsGFsjjPNdXZ2K26m8vyN4+bDc7fc+9ctotwYdUtwTiPzQz8dgK6GZ7jWbrYgKW6Hv0HufU1rLciOxh6nPD9rmu8HdIflB64rLRHupPMkPy/wCeBV/UbPdqsy8iGM7Rk8mqVxPuPkwDjpkd/YUITGTy5/dQ9OnH8hTQqwJuf7xqQKlum5uXPp/IVAFad9z/AHf88UhmjFOLeIFQN5GacYJBE09wTvcZAPX6miyiTd5suNq8jPT60t3dNdSMyAiNBnnv7moKJdIUx6Bfq3UNg/pVBqv6Yxbw7fyHqz5/lWazUABNRSPikklxVZ37saAFdupNVnYsaHcsfb0ptJsEJTkUuwUdTSYrRsLfb87Dk0JDuXLSERRhR171oQiq8a1q6Pp8mp6hDZx5G85dh/Co6n/PrVEnc+BrHyNLe7cfPctkf7o6f1NdNTIYkhhSKNQqIoVQOwFPrMsKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigDA8Sab5sZuolywH7wDuPWuIu4ME8V6sQCMHkGuP8QaP9nYzQrmFv/HT/hVRZLRwN3bh1KkVzl1bNbyHA+X+Vdrc25BPFZN3bCRSCKt6krQ5oc0oNT3Fo0TnaOP5VCRjuM+1RsUPWVl9xU0dzg+lVc0Zp3Cxu6ZOHvIlz1P9KtafEjzu79UYBc9MmsbRM/2xbD/a/oa1LVJHvRs+6kgdvTg1pDVMiW6OxKw6Ra7n+eZ+OP4j6D2rktSvGMr9PNc5JA4FdLBbSajObu7/ANWeg6bvYe1c/qKw/wBoT3RZSuflx0H0pLcp7GckQiXzZevp6f8A16gYtO/oo/SpGL3Unoo/T/69JK4jHlx9f5VRAgKiRYwO/NWWkeUiCAfe4OO//wBaqkcZBBP3j0FaMDx2cZdhuc9B6/8A1qhlogurcQxGPILtwTS6IoW+kUdBUNw8siPcOcE9P/rVNoIP2t92c45zS6D6nusP+pT/AHRT6ZF/qU/3RT6zKCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAK5rx8f8AinX/AN7+hrpa5nx//wAi+3+9/Q047iex5toojkuVgZtrzSBAQOQK6e/u4tOhFpZgeaPx2+59TXKaVG/2oXMbENE3y4HJNdVaWSWaG8vmAcfN838P+LVrPciOxyOozSm4a3Abf/HnqTUOxLSPc/Ln0q7fyxJPNcAfPKxIB6kVnJG9w5llzt/n7CmIYqPcPvf7v+eBSSy5/dxdOnFOnl3HyoRx0470gVYEy3LHikMtxLJcMsKcKOpq5eLDboLaPqRz6/U1XScW8Q2AbyPy96JLaRYHlmz5jg4B68+tQUT2ZVfDOoMuNok4x9RWE0pPStq1Up4RvlPUSY/UVgigBpf2zUbZJ5qfZu6UCB2PGB9TRYVyttoIq1JaSpzjcPVeRT4bbDZblvT0osO4y1tiWDOPoK1I0xgU2KPFWUXAyaBD41xXp3hDRDpdh59wmLu4GXH9xey/41jeDPDZdo9Uv0IVTut42HX/AGj/AE/Ou6pNlJBRRRUjCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKa6K6FHAZSMEHvTqKAOR1zw+0e6a1UvF1K9Sv+Irkbm2IzxXrlZGqaBa32XT9zKe6jg/UVSYmjye4tg3Uc+tY91YEElflP6GvQNT8O3truLQl0H8aDI/+tWBNakZ4p3uTY5B0eM4dSKbXQzWYIIA49CMiqMunr2Vl/wB3kflRYYzQudatR/tH+RrXtp/JuGjAyZJVHPQDPNUdFtDHrVs3mKQGPGMHoa0LOKNrmWSTHyMAuemTVw2ZEuh0upXbXMn2KxGVPykrxn2+lcrqMEjag9vuysXBI6V2BWDSLXc+Hmcfix9B6CuR1K8PmvjHmucsQOBREcvMqzyLCvlRdR19v/r1CsYjXfJ1qVIhEvmy9fQ9v/r1Axad/RR+lUIRXZ5g2OFq9aW5uZg833B29f8A61VAVEixqO/NWWleUi3gB+bg47//AFqhlIL6dGkITGxe+OPwpdDbfeyMO9NurcQxGPcC7dTT9DULeyqOgpdB9T3SL/VJ/uinU2P/AFS/QU6sygooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACuY+IH/IA/4H/Q109cv8QP8AkAj/AH/6U47iex5rotwYdUtwxIiWTe+BzwK6FzcazdcfJbof++f8TWFogikuUtmOHnl28DkDFdNqF7HYxi0slHmDg452/wCLVrLciOxyV1abtRm3ZESOVGTycVUuJi58qHp047//AFqnvpZXna2UNkHDZ6k1GVS0jyTuc/r/APWpiI9qW0eW5c1CqNM+9z8tPSNp23yfd/nTZZNxEcXTpxSGadlGit58xGF5Ge3vSXd01y7yKpEaDIB/rUcSSXUixKdqDqfSrV8IYQLWMcAfN/8AX96gobbknwfeMerSZ/UVgV0dpH53hW5jRkXdLwzHCjkVlfYrdP8AXX8Z9olLGmJlMHFTxxSOu/7qf3m4FTBreL/UQFj/AH5jn9OlBLStukYse2e1ArCAdo847sep+lSxxgDAFIoAxmt/SPC+ramVaO3MEJ/5azAqMew6mlcqxkovIABJJwAOpNd14X8IMWS91iPAHzR25/m3+H51uaF4VsNHxLj7Rdf89pB0/wB0dq3qlsdgAwMCiiikMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAqndaXYXeTcWsbE98YP5irlFAHPz+DtJlyVE0ZP8AdfI/WqT+ArBjxd3A/Bf8K62igDj5PBen6fDLeJPO8kKMygkAZx9K88jikkvyE+6sm5vQYNe0ar/yCrr/AK5N/KvGkuPIuZlAyzygZPQDPNbU9mZz6HS29tJqM5urv/VnoOm72HtXPagkIv57kspXd8uOgrotRu3uXFlYjKngleM+3sK5W/hke/eDd8sRwTjgURBlRi9zJ6KP0/8Ar0krrGPLj6/yqSeRYV8qLqOp9P8A69RLGIxvk61QhscZBBP3j0rRgeOzjLkbnPQev/1qzVdnmDY4XtV+zt/tMwkm+4O3r/8AWqJFIrXDyuj3Dnk9P/rVPoAIupN3XjOaS+nRpCEx5a9x0/Cn6C2+8lbHXFLoPqe5x/6tfoKdTY/9Wv0FOrMoKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigArlviCf+JGo/266muV+IX/ACBU/wB+nHcT2PN9Jhf7QLmNiHRsIF65x/8AXrqrWzj0+I3d6R5g59dv+JrldFuGi1O3yW8pJDI4Ue1dARcazc7mzHAh7dF9h6mtZEROeu5IoZJZcZklYkA9f/1VRjiadjLL93+f/wBarMlt5l5M8mRGrkAHuB/Sq9xMZW8qEfL047//AFqYhk0pc+VF06cd6MLAuTyx4pxC2yc8uaiRGlbzHPH86QzRW4+zR7Yh+8P6UTWsiWztL/rZB0J6Z9fen2MccZ8+cjC8jPb/AOvTLy6ednnC4RPug/561BRt+E9Kj1fTBp08jxpLI2XTGRjnv9K2ZPhhFn91qsmP9qIH+Rqt8OOWtyepeQ/pXpVS3qNHn0fwyQH59VfH+zCP8a0LX4c6REc3Fxdz+xcKP0FdjRRcLGZYeH9I04hrSwhRh/GRub8zzWnRRSGFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAVdU/5Bd1/1yb+VeOwxx/bLiWXH7t+M9MmvYtU/wCQZdf9cm/lXi7QyTahIqcKJNzHsK1p9TOfQ6/EGk2u9vnmcfix9PYVyOo3Z8x9uPMc5YgdM10tvayX8v2q7J8rsP72Ow9q528jjW8nuXK43HbjoKa3BlBIhEvmy9fT0/8Ar1Cxad/RR+lSOXuZPRR+lJK4jGyPr/KqEICokWMDvzVppJJSLe3H3uDjv/8AWqnHGQQT949K0YHjs4zIRuc9B6//AFqhlIr3duIovK3fOepqXQlC3kqjoMCq1w8ro9w55PT/AOtVjw/kXMgbOeM5pdB9T3RP9Wv0FOpqf6tfoKdWZQUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABXKfEL/kDxj/AGzXV1yfxD/5BMX++f6U47iex59onlSXEVqxO6eXB29QMV0eo3yWqCzsQAw+UledvsPU1zGlQOZluIy3mBiqBeuf8mupgtItNt2ubph5uOP9k+g9TWstyI7HGXc0k8pgjB4OD7n/AApCI7SP+85/X/61TTtHahyOZJCTg9//AK1VI4mmbzZicH9f/rUxDEjaZvMkPH8//rU2STe4SP7ue3enTSmVvLiHHt3/APrUoCwKO7NxSGXIY5LyZYwdsY6n0/8Ar1YvxDGfsyAbV+9z0+tRC4+zx+XCP3h7jt/9em3Fo6WzCT/Wv2J6f/XqCjrvhzybcjpuk/lXpFecfDgY+zj3kr0epe40FFFFIYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAVdU/5Blz/ANcm/lXjMlyYLm5VB8zycH0r2bVP+QZc/wDXJv5V46ixC8uZpcYjfjPrWtPqZz6HQXt490Es7MEgqAxHGeOnsK5S6SSe8eLPyRnGR0FdkPI0uxEh+eaVc+7e3sK5G9uBGzJHjzGOSR2P+NOISK08iwr5UXUdfb/69RLGEG+Tr/KpEiEa+bL19D2/+vULFp39FH6VQhFdmmDY4XtV+zt/tMweb7g7ev8A9aqalRIsYHfmrRkeUi3tx97g47//AFqhlIS+nR5CEx5a9/8ACnaE268kbpnFR3duIYvK3Dcepp+iAJfuo6A0ug+p7sn3F+lLWaNd0lQFOo22QP8AnoKRvEOjKcHUYPwbNZ2KNOiso+JNGA/5CER+maZ/wk+jf8/g/wC+G/wp2YGxRWP/AMJPo/8Az9/+ON/hSHxTo4/5eSfpG3+FFmFzZorE/wCEq0f/AJ+H/wC/Tf4Uf8JXo/8Az3k/79N/hRZhc26KxP8AhK9I/wCe8n/fpv8ACj/hK9I/57yf9+m/wosxXNuisT/hK9I/57yf9+m/wo/4SvSP+e8n/fpv8KLMLm3RWJ/wlej/APPeT/v03+FH/CV6P/z3k/79N/hRZjubdFYn/CV6P/z3k/79N/hSjxVo/wDz8t/36b/CizC5tUVjjxRo5/5e8fVG/wAKP+En0f8A5/P/ABxv8KLMLmxXI/EQ/wDErh/3j/StceJtGP8Ay/IPqCP6VznjjUrLUNMj+xXCTeWx3be2cYpxWonscPo87x6jbk7jFE5dgPpW863GrSvPL8kEYOPQew9T71jaK0Tz29qwJaaUhsdQK6HVL9IkNlZBeBtJXovsPetJbkR2OPSAyyNNOflzkZ7/AP1qinlad/Ki+7/P/wCtUlxM9zJ5UQ+T+fufahvLtI8D5nP6/wD1qYiNtlsnq5/z+VRRo0jeY54/nTo0Mp8yU5H8/wD61NaQvIqp90Ht3pDNaxSOA/aJz93ke3/16gvLqSYyXG3Cr90HtTreJ72dUztjU8n0/wDr1NqHkI32dANidR2FR1KOo+G/P2f/ALaGvR685+G//LD6SV6NUvcaCiiikMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACignHWsm/8SaTYErLdq8g6pF85/TpQBrUVxN347Y5FjY4HZ5m/oP8axbrxNrV1kG9MSntCoX9etVysVz06SRIxukdUHqxxWdP4h0e34l1CHPop3H8hXl8skk7bp5ZJW9ZHLfzpAvoPyp8ornfXXirTbuOSztvPd5VKhvLKr0PrXmckD3F/Ki8KHyx7CtjTuL+LJA69T7GsiW5aCe5VB87vwfStIK17ET8zo7azkvD9puifKUYUdN2P6VgRWLzXkjqu5ixI9FHrW9dXklzDFZ2oP3AHI/i45HsKoahM1lEtnaHEzDdJJ/dH+J7URQ2VZtOs0b/AE27JYfwIcY/rUJTSP8AVJO8Z9Tn+oqVdKlMOTKkO7u/JJ9/eqFzp0lj88xV1J4Zen/66okWbS3gHmROJk7EdR/jUsDx2UZkPzOeg9f/AK1TQ3Bh0mGYLkb8Ee2TQbOKa6SXOYmGdvr/APWqJIqLM24eV0e4fgnp/wDWp+iZF4wPXHNPvp0eQhMbF7j+lR6Q+6/Zumc/yqeg+pv4o596wGluyTm7m6+tN33J63U3/fVUB0PPvRg1zuZj1uZv++zR+873E3/fZosB0eDRg+lc3tf/AJ7S/wDfZo2N/wA9ZP8Avs0WA6TB9KMH0rm9h/56Sf8AfZo2H+/J/wB9mgDpMUYrm/LP9+T/AL6NHl/7cn/fRosI6TB9KMVzXl/7cn/fRpfL/wBuT/vo0WA6TFGDXN+Wf78n/fRo8v8A25P++jRYDo8GjBrnNh/56Sf99mjY3/PST/vs0WA6PB9KMH0Nc5tb/nrL/wB9mlxJ/wA95f8Avs0AdFg+9Nuc/wBmT5/vLWB+97XE3/fZq/al/wCyrvfK7/OmNxzjrQA3SrZmkSdNxkyVjVfXpXSmzh06wkknZTO6lR7E9h/jXM6NO8eoW7kM0UDFyB9DW6YrnVpGnlbZEvC+g9h/jTluEdjMsNMDRFi2yP8Aic9T/wDWoabTbfJgtxOe8j85/E1Y1ZzLMljDxCmAVH8bdgfYfzqG5tdPgCxXkjtIwyVQkfy7VRJVOsQTv5UlkHQ8cYpz6fBJCJrEFS/O09D/AIVFe2cNtafabMl48/Nk5Ip8cskei20qk79+fryeKXqAz7Q0CeTAD5h44HI/+vUd1ZvHbFGx5r4zk9K0QbeOQXrrt+X8c/41m3lzJKJLnbgdFHYVm1Zmi2N7wzqM+l6TFdWyxtICy4cEjBPtXQReOrpf9dYQt/uOR/MVx9nPHb+G4nlJC+ZjgZpi31q3SZR9QRQkmFz0CHx3aEgXFlcR+pUhh/OtCDxfok3BuzEfSWNl/XGK8zWSJ/uSxt9GFOKmjlQrs9dt9RsroZt7uCT/AHXBq1XipUZyAM+tXLbVdStCPs1/cIB/DvLL+RyKXIPmPXqK85tPG2qQYFzHDcr7jYfzH+Fb1j440yfC3Uc1q3+0Ny/mKXKx3R1FFQWt5a3sfmWlxHMnqjA1PUjCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKK5zX/FlppZa3twLm7HVAflT/AHj/AEoSuBvzzxW8TSzyJHGvVmOAK5TVPHNvEWj0uL7Qw/5avlU/Dua43UdTvdVm8y+naTB+VOiL9B/WqjMsab5GCr6k1oo9yWzRv9Z1LUyftl05Q/8ALNPlQfgP61SVcDCjA9BWfLqag7beMufVun5VA7Xdx/rZCq/3RwPyFMRpyXMEP+smUH0HJ/Sqz6rFnEUTuffiqqWsa9RuPvUoUKMAAfSmANfXz/6uNIx9P8ajY3cn+suW+gNS0UCJ9Ct1XWrZyzMwY9T7Gpo1iW7uZpcfu24zRov/ACF7b/eP8jUMsDz6hMi8KHyx7CqiKR19vHBa2qYI86dc+57/AJVz1xMr68sPBLS4b2A//VWxY2s07C7lYhEXCZ74GPyrLls1h19ZzyJX3J7cc/jRHYHuMmtlvdalW4Zika/IoPTp/jVS2Y3Wj3kcnSMkJnt3qb7SYfEk5c4jxsJ7DgHNNlsbuFZYbIp5MpyST0piIWAGiwLjjzMfqaeN1xp7JDy2do7Z/wDrUy+CQWkNkrbmQ5Y+/P8AjUisthapv5c8hfU1LGild26wx+Vuyx6mo9KAXUio6DI/Sm3LSujXDnlun/1qNIBF+AeoBz+VR0K6iSTIpPPOaha4PYAVAzfMfrTc1VwsSGZz/FTfMb1NMopXAkErj+I1Ilww+8M1XoBouBopIrjg0+s9GIORxVyGQOOetUIkooooAKKKKACiignAoAQnFQvOB05pksmfpVdmoAlaZz3xTPMb+8ajzRmpuMlEr/3jWtpzs+kXhY5/eJ/I1iVs6X/yBrv3lT+RppgXNEaKW4tbNgSZXO/HGBXTvewtdLZ24XYoOSOnHYVymk2jO6SpkysSqAHHtXTC3t9KtDLOwMrcZ/oKbspErY5uKaSbxKqEHakzEj6Z5NXIlifXLpXVWYr0IzxwKlmgW31uCSNcrcsTuA43bTWc8htNeublvubiCPUYFVsIZYAnRr7zfuliefoKbcHdotqy5x5g/malnt7C8JkjvQkbHLICOf8ACq97cRyNBZ2qnYuFUetJjRbt4heWkcb/ACgvnjrgGoNQaAMYVC+XH19BipbmVrZY7W2/1hGMr1GfT3qneWjR23lkjzCRn2qHuUtizF/yLEII6yVRMSHqi/lWhGP+Kat/9/8AxqlihAyE20R7EfQ0CF0/1Uzr+NTUU7CGCe+TpIsg/wBoVINSkX/X2/4qcUlFAE8d/bScbyh9GFTjDLlCGHqDms54o3+8o+tRfZ2Q7oZGU/WgZrxSSQSiWCR4pB/EjEH9K6LTPG2pWmEvVW8iHc/K4/Hoa4pb64i4nQSL69D+dWormGfhG2sf4W4NGjDY9e0jxFpurgLbThZu8MnyuPw7/hWtXh5BVgRlWU5BHBBrqND8a3dkVh1PddW/TzB/rF/+K/nUOHYakekUVXsb221C2W4s5lliboVP6H0NWKgoKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigApGZUUsxAAGST2pSQBk15v4u8TNqMj2FhIRZqcO4OPOPp/u/zppXE3YseJvGD3DPZaQ5SHlXuB1f2X0Hv+Vciq8cfU5puVRC7sFVeprOubp7g+WgKx9l7n61olYksz36x/LbgO3Tceg+nrVURSzv5k7sT79f8A61SQwBBublv5VNTAakaxjCjFOoooASilooASiiigRe0T/kMW3+8f5Go7m4aC6ulQfO74B9Kk0T/kM2v+8f5GnOIk1C7nl/5Ztxn/AD1qoiZtXF3LdQxWVqCfkAc/3uOR9KpWl3FczfZ7kYmtpP3b9j2/OtWN7fTtNSbG6WZc+7e3sBXJ3twIyyR43sctjtn+tKLHIsazBcpcSSRQMyuc7lGccfzqjbx3iptXz+eijOBU9ve3lrDmSclR0V+cf1pjaxezEhCiD1C8iq0JJIbIW5F1fMF28rGDnn39TREhvroTTDEQ4Vc9RVJ5WlnUSOzsepY1OZJJiLeAfe4OO/8A9aokykNvrhHkbZ9xe4HX6VFpbbr8tjGc/wAqku7dYo/K3ZY9TUemALqBVegyP0qeg+pnH7x+tJSn7x+tFMBKKWjFACYpcClxSgD1xQAmMVIjFSCKbjHBpOhpoDQRgyginVWt3w2D0NWqYhMUU6igBtQTP2qaRtq1RkbJoAYxyaaRS+9JjuakYmKKXFGKAEra0sf8SW5/67L/AOg1j1taZ/yBJ/8AruP/AEGhAP0WeSPUbeUhmigycDjqD/jWzLHcX8c19OdsaKSvofYe3vWborxS3VpaMu7ex39vU1s6vqSMjWtrjywMMwHGB2HtTluKOxk6TqEkNtsvuYgdyMeqj39qbqGmyX7mezuInjc7iuf6isqWV7yXZGMJ1/8Armld1tE2xk7zz1x+Jqr9ybF1NGuI12gxg92JJoVbbTtxRvPum4LHoP8ACs5Wmdd080hXrgucGmCXfOoXOxTmlfsM2LRkty13ctukPfv9BVG9uJXR7ggDJ2gdhU9nbtfTjzCREvXH8hRqLwlmjULsj/IGs+pZOox4bth/tVSq4zBfDtnk4yapA5qoiYtFFFUIKKWikAlJS0UDExUElsjcr8p/SrFJQBXjup7chJRvT0J/kavRyRzJuibOOoPUVXZQwwwyKqOj27h42Ix0I7UXA6HStVvNHuvtFlJjJG+NvuyD0I/rXqGga9aa3a74TsmT/WQseUP9R7145bXK3HynCy+nZvp/hVuyvLjT7tLq0kMcydCO49D6ik43BOx7dRWT4d12DXLHzY/kmjwJos/dP+B7VrVkWFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFZviDVU0fSZbtsF/uxKf4nPQf1/CgDmvHfiAxg6RZvh2H+kMD91T/AA/U9/b61wo2qpZjtRRyfSleSSeZ5ZWLyyMWZj1YnrVC+nDN5SH92h5P941qlYi5Hc3DXEgABCg4Rf8APepoIRGMnlj1NNtosDzGHJ6ewqemAUUUUAFFFMklRB8xoAdRmqj3ZP3Bj3NQNK7dWNAF9pUXqwqJrpB0BNUs0maLgbWgXLPr1muAAX/oanvLd7jVbhF4UPlj6Vn+HjjxBY/9dQP0NaN/cNBfXaoPmdhg+nFOO5MtjctbJp4/PuCfKRcKD/Fj+lc4YljeS4mI+8SB6f8A162ku5302G0UFSE+c9z/APWrn5DJeTEDhFP5f/XoQ2ROXuZPRR+n/wBemyusY2R9f5VLPIsK+VF1HX2/+vUSxhBvk60xDY4zkE/ePQVowSR2UZc/M56D1/8ArVmxuWmDY4XtV+zt/tEokm5QdvX/AOtUSKRVuWlZGnc8t0/+tRpIK3hVuDg/yqW9nRpDt+4vf1qvp8mdRVumc/ypdA6lM9T9aKU9TRTATFLilxS4oATFGKdRTAAMjHp0ppp44I+tI64YigQiHBrQjbcgPrWcODV21OUI9DTAmooooArXDc49KqE5qaY5Y1D70mCDHOT0FIeTk0/aTEWwcAjJppOWJxj2pDEpaBSigBK2dO40Of8A67/+y1j1r2B/4kk49Jx/6DTQiXTLXJjkBzJIdqDOMZ4roL+0hsdJkQuDPMNu4/yHtXM6c0xuoJBykBzz0/8A11qak9zJayX8zY7JkfyHpTluKOxkTPHaR+VFy565/magih6zT/Xnv7mpIbfaDNcfXB/mahlke5k2pwo/zk0AMldp32p933/makQIjrEOSx5pJGS3TavLGmQxsW8xs5PT1NJjNM3DhRbWoO9vl+Xr9BVe+tDHAI8gvnLe2BV6y8qxiM8vL9Bjr9BWde3EjI0zDmQ7R7fSoKJ7xgfDdmPR/wClZKuy9CRVy4k3aNbpn7sh/lWfTQiwtzIOpB+tSrdj+JfyqnRmncDRW4jb+LH1qQMD0INZWaUMR0JFO4GrRVBLmRepyPerEdyjcN8poAnooBz0ooASkIBGCODS0lIClNEYmBXO3sfSr1tcfaF2t/rQOf8AaHr9aayhlII4NUmDwSjaSCOVNAHQaRqdxpGox3lscleHTPDr3Br2DTr2DUbGK8tX3RSrke3qD714ikgmiEqgDswHY11ngHWjZaj/AGbO3+j3J+TPRZP/AK/86JK6uCdj0uiiisiwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACvMfHmqfbta+yRtmGzG3joXPX8un516Hqt6unaXc3j9IYy2PU9h+deMFnlkLyHMjsWY+pPWrgupMiK4l8mAkfff5V9vU1Rgj8yTn7q8mn3sm+4IB+VPlFTwJsjA7nk1Yh9FFFABSMQoyTgUjMFXJPFUppTIfQelAEktyTwnA9arEknJ5NFJSASiiigBKKWkoAt6RJ5WsWUh6LOmfzroL5IodXu5Zf+WZGM/T+dcqGKEOvVTkfhXU65F9q1VJUOEmiWTPt/k047ilsNtb9pYpkVNu7jd6CqFzKkCeTD97ufT/69SXFwtvH5FuMMOp9P/r1DHCIVMs33uuD2/wDr1VibkSRCJfMl6+h7f/XqBi07+ij9KkdnuJPRR+lNlcRjYnX+VADo9vmiMdO9WGleXEEA4PXHf/61U4kOf9o8VeR0tYiert+v/wBaoZaILmELGIgeSeTUFqAl8cdFVv5Uk8zbuvzt+lMt/lWZvRCPxPFAMiFLiiloAKWkrf0rQ9wWe+XjqsX/AMV/hTEZVpp91ecwQkr/AHjwPzqe60i6tLYzymPaCAQrZPNdcAFUKoAA6ADAFUdcIGkT57gD9RTsTc5Chjk/hRSeppFDT1q1Zn5iPaqlWrT7/wCFMC3SNwp+lLTZP9W30pAZ8h5pnanSdaZ60MEXoRnRL1/SSFR+bGqNXInA0O7TuZ4j+jVS7GkM0hot+0CzJGrqyhgAwzj6VSZGjco6lWHUEYIrubYg2sJHTYuPyqG/0+3v48TLhx92QfeH+NOxNzi609OOdMvE9HRv5iqt9YzWM/lzAEHlXHRhU2lEs1zCP+WkJwPdef8AGgZJ9s8u1SKH7+OTjp9PetGe8kltI/tWFEYHBrNtDDHCbhz8wOB7fSo2aW9l/uov5D/69U0SmNleS8l2oMIP85NLK6WybI+WPX/E0+aVLZPKiHzd/b61BHFtHmzfXB/rSGNji/5aSn3waWKbdcA87F5+tMd2nfauQo9f5mpYVTzBEOvU0mNF61ga8l8yYkRL2Hf2FRXzxPu4G1AQvpnFPkuTt8iDgHgkfyFUJI2muPKQ5VOCe2agojfiyjU95GP6AVDird7hJFiABCLz9Tz/AIVWyP7oqhDMUYpxx6UmKAExRS4pcUANpaXFGKAHxzPGeDx6VcimWQccH0qhQCQcg4NAGnSVFBP5g2t97+dTUAJUU8fmJx1HIqWkoArWcwimwx+R/lb29/wq+dyPkEq6nII7Ed6zbhNsmR0bmr8L+bbo5+8Plb8On6U0JnsvhzUxq+i293x5hXbKB2ccGtSvOvhvqHlX1zpzn5Zl82MejDg/mMflXotZSVmWnoFFFFIYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAch8RrzydIt7RTzcS5I9l5/nivOt2xHk/uqSPr2rqviLcebrkEGeIIOnux5/kK5C7O20I/vMB+Vax2Ie5ShXfKM/U1eqraD5mPoKtUwCkJxzS1XuZMLtHU0AQzy+Y3H3RUVBpKACkpaSkAUlLRQAlFLRQAldDFK15o9u8bYntQYX+nVT+XH4Vz9W9NvTZXO5gWicbZVHce3uOoo2AtxRrCPNmPzdvb/69QOz3Mnoo/T/AOvWne2sc0IlibepG5WXuKy5maJAqqQD0NXe5LVhJZBGuyPrUQAUbm600YXlutMZi556UgHq7GUMO1LJONxJ+ZvSomfAwtMXA5PWpY0SZ25kc5c9PalB2Qbe7nJ+lMUeYdzcIv8AnFKSWOTQMKKK2dD0r7Swurhf3Kn5FP8AGf8ACmIsaDpeAt5cryeYkI6f7R/pW/SUtUSwrG8TTbbOKEHmR8n6D/8AXWzXJa9c/aNSZVOVhGwfXv8ArQwRmmmk0pppqSxKt2f3z9KqCrlmPvH2oQi1TZPuN9KdSNypHtQMzZOtR1JJ1qOhghwchGQfdfGfwptJSikB2ehzifSYTnlBsb6j/wCtitCuZ8MXWy4ktWPEg3L9R1/T+VdNVIhkN3axXlu0Mwyp6EdVPqK5GSKfStQXcPmjbcp7OP8A69dpVTUbCO/t/LfCuOUf+6f8KGNM5eaKMXQCtiGT5kPsf84p8tyI18qAAEcZHb/69RMrwlrK6GxkPysein/A1GjCF2DqQ4p3CxKkYjHmzHn0Pb/69Qu7TvgcKKaztM2ScAfpSNIEG1PzpAPd1iXanX1psYKZkY4NMUBRufrTctM3oBUsZaWbKlIAQT95z2+laFpElvbmZ+FUZGaisbLKh5BtjHOD3qHULwTsIov9Uv8A48ancopyOZZGkbqxzTcUtFWITFGKWloATFGKWigBMUlOpKAEpKWikAgJByOtXoZPMTn7w61Rp8TmNw3bvQBeoozkZFFAEVwuYie45o098tJF/eXI+o/+tmpGGVI9RVW1fy7mNj2bBoA3dEvPsGt2d1nASVd3+6eD+hr2qvB3UjcvcZFe16Lc/a9Gs7jvJCpP1xSmOJdooorMoKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPJPGEpl8U3vOdjKg/BRXPX5xFEv1NbHiE7vEepHP8Ay8MKxdRPMQ/2K16EDbQfIx9TU9RW3+pH1qWmAGqErbnJq5KcRk1RoATGeBSEYOKkHClqjoAKSprS3ku7uK2hGZJWCrXQ/wDCE3+f+Py0x6/N/hRZsV0cxRWlrWjvo7xRzXMUrygttQH5QPXNZtIYUUlFAC0UUUAXLHUJLMlcb4mOWQnH4j0NaxNtqMWIZfm67SMMPw/wrnadGru4EaszdcKMmgDRudKkUZjYtjsRWdNHJFwyEVbF7qFuMF5QvpImf5io5L+WUYdYT/wGlqGhSBycAEn2qQREczHH+yOv/wBanmZyMbgo9FAX+VMyPUUwHFs4GAAOgHakqWG1uJziGCR/oprZsPDzlhJfkKv/ADzU8n6ntTFcraPpRvX86YEW6n/vs+g9q6tQFUKoAAGAB2pFVUQIihVUYAHQClpolsKKKKYFbUrsWVk83G77qD1Y9K4okkkk5J5J9a0dbv8A7Zd7YzmGLhfc9zWbUspIQ0hoJpO9IYCr9oMRk+pqgvWtGEbYlFMCSikpaAM+cYc1Cas3Qw5qsaGCEoooqQJIpHhlSWM4dCCDXcWV0l5apPH/ABD5h/dPcVwdaeiaj9hudshPkScP/snsaaYmjsaKQHuORS1RJQ1XTU1CHjCzoPkf+h9q5OQPE5guEYMhxg9V/wDrV3dUdS0yDUEBb5JVGFkA/Q+ooaGmccVbHyHcPbr+VR5KnlTn3rRudIvrYnMJkUfxR8j/ABqmzOhwxZT6HipGQ5Z2wAT7CtC28m3Aablh0UVU3k/xH86SlYZbur6S5+X7kf8AdHf61VHNIPmOF5PtzU4t58ZEEufXYaYEVFSC2uDwLeX/AL4NRsCrFWBBHBB7UxBRSUtAwoopKAFpKKO9ABSVKIt1u0qup2sAydwD0P0qKkAu35dwP4UlOQ4bFIwwxFAFm2bdHg9RUtVbU4kI9RVqgBaoP8sjexq9VKbiZqANWXl9394A/mK9V8DS+b4UtMnlNyfkxryjqkZ9UX+VenfDo58M49J3H8qJ7BHc6miiisiwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA8a18Y8RakP+nl/51jaj96L/AHK3/FcfleKNQUcBpA35gGsHUR8kLexFa9CBLf8A1K1JUNqcxY9DU1AEVwcRmqdW7j/V1UPWgBznCAVHTn+6tMoA6bwNbCTVJ7hh/qIsL9WOP5A1200scMTyysFjQFmY9gK5PwARtv1/izGf51D4x1oTMdMtXzGp/fsOjEdF/CrTsiGrswdWv31LUprpuFY4Rf7qjoKp0lFQWLRSUUALRSUUALXTeF7dVtZLn+N22D2ArmK2NA1JbSQ285xDIchv7rf4UITOryT1NQvbW8n+st4m+qCpaKokriwsh0tIP++BUqQQp9yGNfogFSUUAGaKKKACiiimIKx/EGofZ4PssTfvZR8xH8K//Xq/qF7HYWxmk5J4Rf7xri5ppJ5nmlbc7nJNJspIZRRmkNSUHem0opBQA+MZYD1rRHAxVK2XMgPpzV2mIWikzRSGQXQyAapGtCYbozVButMBtJS96SpGFLSUUAdL4d1LcosZ2+Yf6pj3H92t+vPVYqwZSQQcgjtXY6Nqa38G2QgXEY+cf3vcVSZDRo0tJRTELSMocYdVb6jNLRQBA1nat962hP8AwAUgsbNTkWkA/wCACrFFACIiRjCIq/7oxTsn1NJRTELk+prmvEtokcyXaHBlO1l9SB1rdvLuGygMs7YHZR1Y+grkNQvpb+fzJOFHCIOiikykVqKSipKFpKKKACikooAXNFJRQAoODmlk+8KbSydfwoAfCcTLVuqcP+tWrlABVOf/AFzVcqjKcyN9aANUf6uL/cX+Vem/DkY8NH3uH/pXmbjGF9FA/SvU/AMXl+Fbc/8APR3f/wAeI/pRLYI7nR0UUVkWFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFAHmPxAg8rxGJMcTQqw+oyD/SuSvxm1U/3W/nXo3xJs99pZ3qjmJzGx9mH+I/WvP5V8y3kTuVyPqK0WxL3M+0bll/GrVUIG2zD34q9mmIjnGYjVI9avsMqRVBuDigBTyn0NMp685HrUdAFux1G608T/ZJNhnTYxHUDPb3qpRRSAKKOlJQMWikooAWikooAdRSUUAbGk629oFgucyQDof4k/xFdRFLHNGskLq6N0ZTmvP6s2V9cWMm+3kxn7ynlW+oppktHdUVlWGvWtyAkx8iX0Y/Kfof8a1ewPY9DVEi0UlFAC1Bd3UNnAZp2wo6Dux9BVfUNVtrEFWbzJu0ann8fSuUvb2e+m82ds4+6o6KPai40h1/ey31wZpeB0VR0UVWpKKkoWkNA5OBSsMNj0oATtRSHrSjrQgLdqMKW9ampiDagHpTs0ALRSZozQAp6VRlGGIq7Va5XnPrQBWpD1paQ9PpSASlpKKBjqkgnkt5lmhba6HINRUUAdxpmoRahBvXCyL99M9Pf6Vcrgba4ltZlmgco69DXVabrVveARykQz/3SeG+h/pVJkNGpS0lFMQtFJ0BJ4A6k1m3muWdtlVczSf3Y+n4mgDTrJ1HXYLXMdviaUccH5V+p71hX2r3d7lGfy4v7icZ+p71QpXKSJrm5mupjLO5dz69vYVFSZozSGLRSUUALSUUlAC0UlFADgCTxzSlWAyRT4wAvHOadnHJoAgHJApXPzGhepb06U0mgCa35lHtVqq1sPvH8KsUgAnAJqnCvmzov95hVidtsR9+KTTkzcGQ9I1J/HoKBl6Rssze5NeyeHLc2vh+xhIwVhUke55/rXken2pvdRtrRes0qofpnn9M17cqhFCqMADAomERaKKKzKCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigDO8QWH9p6JdWg++yEx+zDkfqK8dUlTyMEdQe1e515V4y0s6brsjxriC6/ep7H+Ifnz+NXF9BM4y7j8i6YDpncv0qyjhkBHepL+LzYN6j5o+fqKo20mDsP4UyS3VO4XbIfQ81bzUcyb046jpTAp5pGOTmg9abSAXNFJRQMXNGaSigBaKSikAtFJRTAWikozQAtFJmigBas219d2vFvO6D+7nI/Kq1FAGuviLUAMExN7lKhn1i/uFKtOVU9kG2s6lp3FYWlptLQAUUmafGueT+FAD0GxSzVFnqT1p0jbjgdBTCe1ABU0C7nHoOahFW4V2pz1NAE2aKbmjNIB2aM03NGaYDs1HKu5D607NGaAKJ603vUsy7WPp2qI0AIaOlHWngB1/2hSGMpaQgg4NFAC0tNpaALlvqd9bLtiuX2jorfMP1qwde1EjHnKPogrLpadxWJ7i7ubn/XzyOPQtx+VQ0n40UgFozSZozQMWikzSZoAdSUmaKAFopKKAFzRmkzSZoAdmjPvTc0UAPJ4wKQU2pYE3Nk9BQBZiXbGB36mn5puaRmCqWPagCG5fLBfTk1ds4/LtQSPmkO78O1UbeI3NwAfu9WPoK1GPfHHYCmhM6v4eaf9p1mS9ZfktU4P+03/wBbNemVi+EtK/snQ4YpFxPL+9l/3j2/AcVtVnJ3ZSCiiikMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACsbxTo41nSHiQD7RH+8hP8AtDt+PStmigDww7kYqylWU4KkcgjqDWVeQeRLuT/Vscr7H0r0nx54fMUjaxZp8jf8fKjsf7/+NcNIquhRxlTWl7klKKQOue/epM1Ukje2l9VPQ+oqZJA65FADJ4t3zL17j1qsavZqKWIPyOGoAq0UrKVOGGKSkAUUlGaAFopKKAFopKKAFopKKAFopKPxoAXNLSY96crAdVBpgJS8+hp4dfQil3r7/lQIZg+hoCse1P3r70nmDsKAFVMcnmh37D86YzlutNzQA7NJSZpygscCmBJCm5uegqzmmKAq4FLmkMdmjNMzRmgB+aM0zNLmgB2aM03NGaAElXcvuKqMKuZqGZP4h+NAEFLnByDSGjNAEgKuMHrTShHTmm04SEDnmgQ3B9DS4Poaf5i+ho3r70AM2t6UYPoak3r70eYvoaAI6TNSGT0H50wnJzxQMSjNFJQAtFJRmgBc0UlJSAdmkpKKAFzRmkooAXNFJUscJbluBQAkaF2wOnc1aUBVCjoKQYUYAwKM0AOzVaaQyNsXn6dzSzS/wr+Jq1Z2/lfvJB+87D+7/wDXpgT20It4dv8AG3Ln+ldT4I0U6nqouZlza2pDHI4Z+w/r+VYWm2Nxqd/FZ2i5kkPU9FHcn2Fex6RpsGk6dFZ2w+VBy3dm7k0SdlYErl2iiisygooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAK4fU/iB9kvZreDTt3lOU3vLjODjoBXX3OoWlq+24mEZ968Y1mC8GpXUxt3aN5nZXUbgQScHIqkhM6h/iRe/wAGnWwHvIx/pVWX4larn5LO0X/vo/1rjDMucMMH0NBKHuafKK51UvxI1l0ZGtbEqwwQUY5H51yct9M8jMsccakkhVHC+w9qUop6EU0xelFguRPcSyKVdQR9K1bTQo5rZJk1a2V3XJjOPl9jzWaYm9KYY/VaLMB96s1ldPbysjMv8SHIIqv9pepNvtSbB6UtRkZnZhgjIpoYE4wfzqXYvoKPLX0FGoGlHoUjAGWdUz2AzUv9gx97l/8AvgVSF/ejpcP+Qpf7Rvf+fg/98j/CizAu/wBgxf8APzJ/3yKP7Bh/5+ZP++RVP+0r3/nuf++RR/aV7/z3/wDHRRqGhd/sGH/n4k/IUf2DB/z8S/kKpf2ne/8APb/x0Uf2pe/89h/3yKLMNC4dAi7XL/8AfIpP7AT/AJ+m/wC+P/r1V/tS8H/LcH/gApRq12P+Win/AIAKLMLosf2Av/P03/fv/wCvR/YC/wDP2f8Av3/9eoRrNyOvln6ripk1uQffgU/7rYosw0E/sA9rv84//r1WvdNFnFve7jLfwptILVNdazO67baMR/7ROTWRIZHcvKWZj1JOaWoaCbzRvNNooux2HbzRvNNoouwsO3mlDc88D2pgoouxEuY/7z/kKcsm0nDkD121DmlwT0FO4ExlbtID+FJ5rn+L9KYIz3NPC4piF8yT+9+lHmSf3v0pMUYoAXzJP736UeY/979KTFGKAF82T1/SjzX9f0pMUYoAdvfHLgUpc44lyfTbUZXNJtI7UtRjht/jZh9AKUKjA7GbI9ajPvQjbXB7d6LhYQtjtSbzTpV2ufQ1HSuwHbjRuNNoouMfuNG40yl69BRdhYuWNqLxyn2hIm7Bh976VoDQW73Y/CP/AOvWKEb0xWja6nd24CuwlQdm6j8aNRaFr+wf+nv/AMh//Xo/sAf8/Z/79/8A16Y2tXB+7HEv1yajOr3Z6Og+iCnZhoWP7AX/AJ+m/wC/f/16P7AT/n6b/vgf41VOq3n/AD1H/fApP7Vvf+ew/wC+BRZhoW/7Aj/5+n/74H+NH9gx/wDP0/8A3wP8ap/2nff89v8Ax0Uf2nff89//AB0UWYaFz+wY/wDn6b/vgf40f2Cn/P03/fH/ANeqf9p3v/Pf/wAdFH9pX3/Pc/8AfIosw0LZ0Be10fxj/wDr0xtBkA+S5Q/VSKrf2je/8/DfkKQ394f+XmSjUCtOklpcNFIBvX8aZ9of2qSQtK5eVi7nqTSbB6UagM+0PQZ5CMfyp+32pwU+lGoEUTuj71UZHTIzip1u5++B+FAic9FNSLbOewFNJiNbQfFd/oayfZba0Z5D80kiksR2Gc9K20+Jes/xWtn+Ct/jXJLaf3nAqZbeBfvMTRyhc7CP4lajj5rC0PvuYVai+JF0SN2lxN67Zj/hXE7raPoi/jzQbktxGhP+6KOVBc9k8Oa2uu2DXIt2gKOUZC27nAPX8a1q868F6/p2i6TPHq93Hbu8xdEzuYjA7Lmu9sb2C/tluLZi0bdCRjNSykWKKKKQBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUVl+IJdmnlQzKWPVWIP5igDA8UTZuH54FeR3M7teyyI7KS5wQcV22qXd4+5WuPOBGP3qjd/30MfrXPW9jpKnGoJfqc8vAyMPyIBrToSZX225Iw8pkHpIA/wDOj7QD96FP+A5WtqfQ9JmXdpWuRl/+eN4hhb8+lZtzoupWwLPas6f34iJF/Nc0CuQCaM/89E/Jv8KcJV7SD8QRVUgg4IwR2NFAy8shPQhvoc04SeoI+orPxShmHRiPxpiNEMh6gUu2I9qzxLIP4s/UZrb8P6Je675pgeKNIcBmfPJPYYoV2DstWVPIjPQkUhth2f8ASuifwVq6f6uW1f8A7aEfzFVpPC2vRdLMSD/YlU/1p8r7E88e5iG1bsQaabeQfw5rTk0rVof9bpt0vv5ZP8qqv5sX+tikT/eQj+dKxVyoYXHVD+VNKkdQauC4X+8KcJQaWgFDFGK0NyHqBRshPVBRYDOCjOaNo9P1rQ8mE/w/rSG3hPqPxp2Az9gpcVeNpH2YimmzHZ/0pWAqYpMVb+xt2cUn2N/7y0WAqFFPUCmmFaufZJP9n86T7LL6D86LDuU/JHqaPIH941b+zS/3P1pPs8v9w0uULlUQr6mneUvpU/kSf3DSeVJ/cb8qLBciCgdAKXFP8t/7h/KjY390/lTsAzFGKdtb+6fyo2n0P5UANxRinbT6GjafSgBuKMU7B9DRg+hoAbijFO2n0NG0+h/KgBuKMU7afQ0bG/un8qAGYpCintUvlv8A3W/Kjyn/ALjflRYCNl3DBphhHqaseTJ/cal8iX+4aVguVfJHqaXyV9TVr7NL/cpfssv90fnRyhcrCNR2pcYqz9ll9B+dL9kk9V/OnYLlbFGKtfY27sKUWnq4osIplQaUCrgtF7uad9miHUk0WAokA9qQKBWh5EI7frR5cI/hFFguUMUbT6Vofux0VaPMUdMUWHcoiNj0U/lThBIf4TVozKO4pvngnAOT7UaCIRbP3wKcLX1YVYSK6l/1VtO/+7Gx/pU6aTrEv3NMuz/2zx/OnYLlIW6DqxpfKiHbNMvVubGcwXdvJDLjO1xg4qqbhuyj8TQBd/dr0UUnmqOmKomZz3A/Cml3PVjQBfMx9D+NMNwB1dfzzVHr15paALZuh/eY/QV1+g+B9Q1ezivJpo7W3lG5d2Xcj1wMAfnXC9SAOSegr6A8NK0PhrTlmUoy26Bg3GOKl6DMSy+Hmk2+DcST3DdySFH6c/rW5a+HdGtAPJ063z/edN5/M5p93r2kWWftWo20ZHYyAn8hWPceO9LBK2MF3et/0ziKr+bYqdWPQ434rabFaarZ3UESRpcRFWCKANyn/Aiut+HF19o8ORKTkoMflxXOeJr6/wDE0EcM+mQ2sUbbld3LSD8uBUnhUvptzDEsrhFb7ucLz14/xqrOwr6nptFHaioKCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigArn/FMuI0TPbNdBXJeKpM3BXPQAU0JnGXhy5qmyg9RVqfljUJFaElOWFCOVFVvJEbbomaM+qEr/ACq9IKrPTEVZ0eb/AFsrv7udx/M1VazP8L/mKvNTadguZ5tJh0AP0NMMMq9Y2/KtYVIopWC5h4OcH5frXpHgi60uy0VYG1C1FxJIZJFLhT6Ac+wrlwit1UGg2du/3ol/KnF8ruKS5lY9UR0kGY3Vx6qQf5UteVLp0KHMTSRH1RyKtxPqUGPs+rXiY7F8j9a09r5GLo9melcig/MPm5+tcBHrHiKL7uoxyj0lhBqzH4n16P8A1trYzf7u5P60/aIn2MjrpbCym/11lbSf70Kn+lU5fDmiS/e0y3B9UBX+VYyeMLpcefozn1McwP8AOrCeNLL/AJb2N9F/wAN/WnzQYck0TyeD9Ff7sM0f+7Mf61Vk8Eae3+rurpPxU/0q3H4w0NzhrqSM/wDTSBx/SrUXiLRZThNUts+hbb/Oi0GF6i7mE/gQf8stVcf78IP8jVd/A98P9XqNs/8AvIy/412Ed9ZS/wCqvLd/pKp/rU6kN91gfoc0uSLD2s0cC/g7WF+69q/0kI/mKgfwvrif8uyN/uyrXo+D6Gko9kh+2keZtoGuJ/zDpT/ulT/Wom0vV0+9pd3+EZNeo0UvZLuP2z7HlDW18n37C7X6wt/hURaRfvxSr/vIR/SvXdzDufzo3N6mj2XmHt/I8g+0KOpx9aPtCf3h+deusqt95FP1UGomtLV/vW0B+sYpeyfcft/I8o89fUUvnD1r1FtL05/vWFsf+2S/4VE2haQ3XTbX/v2BR7Jj9sux5p5o9aXzBXoreG9EbrpsH4ZH9ajbwroTf8w9R9JGH9aXs5B7aJ595go3j2rvj4R0I/8ALpIPpM/+NMPg7RD0iuB9J2o9nIftonCbx7Ubx7V3J8F6N6XY/wC23/1qQ+CtH/vXg/7bD/Cj2cg9tE4fevtRvX2rt/8AhCtI/wCel7/39H+FH/CFaR/z0vP+/o/wo9nIPaxOI3r7Ub19q7j/AIQvRvW7P/bb/wCtTh4M0UfwXJ+s5o9nIPbROF8wUeYK7weD9DH/AC7zH6ztUg8J6EP+XIn6yuf60ezkHtonn3mik84eteir4Y0Mf8w6I/VmP9alXw/oy9NNtvxXNHs2L20TzXzh6003C/3h+deoLo2lr93TrUf9shUq6fYp92ztx9Il/wAKfsn3D2y7HlP2hP7w/OlE2fuhj9ATXrawQr92GJfogFPHHTA+lHsn3F7fyPJFW5f7lrcN/uxMf6VMtjqcn3NNvD/2xb/CvVtzf3j+dBJPUmn7LzF7d9jy5dG1p/u6Xcj6rj+dTL4c1x/+XEr/ALzqP616VRT9khe2Z52nhLW36xwJ/vTD+lTp4K1Vvv3Nmn/Amb+ld9g+hpCCOvFHsoi9tI4lPAlwf9bqkY/3ISf5mrMfgS3H+t1Gdv8AdjC/411L3EEf+sniT/ecCqsutaTD/rdStVx/01B/lRyQQe0mzJj8E6Uv35Lp/rIB/IVaj8J6GnWyMn+/Ix/rRL4s0GPrqCv/ANc42b+QqtJ410of6qK8m/3YcfzNHuIP3j7mnFoekQ/6vS7MY7mIE/rVyO3gi/1UESf7qAfyrmJPGmf+PfR7lvd3C1Wk8W6u/wDqdMtox6ySFv5Yp88UHs5s7TJ9TRya4GTxB4jl6XFrAP8ApnDn+eapzXmtT/6/WLjHony/ype0XYaos1viPpzTW9rfRIS0RMb4HO08j9c/nXnuMVvy2QlbdcTzzH1dyaaLG3TpGPxrKWrubxXKrGFThG7fdRj+FbnlRr91APwoIFKw7mOtrM38BH1qZLCVupUVoinpTsFyXT/tdooFrJDA3/PRIV3/APfRBNXzDcXhzfX95c+0kzEflmq0NaEFICez06ziIKW8efUrk1rwoqjCgAe1UoO1X4qQxlwmVNZsJ8u6B962JVytZEo2zg+9AHpVs/mW0Un95Af0qWqOiyeZpVufRcflV6smWFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABXEeJpN13L9a7evP8AX33XMh/2jVREznZOWpjDipSOaaw4qySpKKqyVclFU5KYiA0lONNpiHLUq1GtSrQMlWpVqNalWkA8U8U1aeKBjhThTRThQAopaSlpABUHqAfwpjW0D/ehjP1UVJS0AVW06yY5NtGD7DFN/sy1BygkQ/7MhFXKKAK620qf6rUL6P8A3bhqmWXVU/1et3w/3n3fzp9FO7FZCrf68nTWGb/fhU1INX8Qr/y+2r/71uKioouxcsexYGva+vX7A/8AwBh/Wnr4k1wfes7Fvo7CqlFPnl3FyR7F8eKdUH3tJgb/AHZyP6U5fFt6Pv6J/wB83A/wrOop88u4vZx7GoPF8g+9olx+Eyn+lL/wmKD72jXw+jKayqKOeQeyia48ZW38Wl6iP+Aqf607/hMrHvY6gP8AtkP8axqWj2kheyibP/CZab3tr8f9sP8A69L/AMJlpfeK+H/buf8AGsWij2kg9lE2v+Ey0n+7e/8AgOaX/hMtI/6e/wDwHasSin7SQeyibf8AwmWj/wDT3/4DtR/wmWj/APT3/wCA7ViUUe0kHsYm1/wmWkel5/4Dmj/hMtK7R3p/7dzWLRR7SQeyibX/AAmWmdoL4/8AbD/69N/4TLT+1nqB/wC2I/xrGope0kHsomwfGVn/AA6dqJ/7ZqP600+Mof4dIvz9do/rWTRR7SQ/ZRNU+MSfu6Ld/jIopjeL7k/c0ST/AIFOP8KzaKOeQeyj2L58Waifu6NGP964/wDrUxvE+sH7mnWi/wC9KTVOilzy7j9nHsWT4i19ukNgn/fR/rTG1vxC3SeyT6Q5qGko5n3Dkj2HnVPEDddUjX/cgUVG11rT/f1u5/4AAv8AKlopXY+WPYgdL2T/AFur6g3/AG3IqJrCOT/WzXMn+/Mxq5SUXHYpjTLMdYQ3+8SakWytU+7bxj/gNWKSgZGI41+6ij6ClwKdSUANNNNPNNNAhhppp5phoAjNMapDUbUwI2phqQ1GaYhtPSm05aALUXWtC3rPi61fg7UmM0oO1aENZ8FaENSMncZWse8XEmfetrGVrKv15oA7Dww+/SVH91iK16wPCD5sJF9GH8q36ze5SCiiikMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooARvun6V51rLZnf616JIcROf9k15xqxzM31qoiZlY5pHHFPApHHFWSUpapyVdmqlJTQiBqQUrUgpiHrUq1EtTLQMlWpFqNalWkA8U8U1aeKBjhSikFLQA6iilpAFLSUtABS0lLQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAlFFFABSUtJQAUlLSUwEpDTqQ0ANNNNONNNADTTTTjTTQIYajapDUZpgRtTDUjVGaYhtPWmU5aALMXWtCDtWfF1FaEFJjRpQdq0Iaz4O1aENSMtgfLWXqArVX7tZ2oDg0Abfg1v3Nwv+6f510tcr4MPzXA/2R/OuqrOW5SCiiikMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAZP8A8e8n+6f5V5vqh/etXo10cWsv+4f5V5xqX+tb61URMoLSOOKcopH6VRJSmqjJV6aqUlUBXNIKc1IKYh61KtRLUq0ASrUq1GtSLSAkWnimCnigY4U4U0U6gBRS0gpaQBS0lLQAUtJS0AFFFFABRRRQAUUUUAFFFFABRRRQAUUUtACUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAlFLSUAFJS0lABSUtJTADSUtIaAGmmmnGkNADTTDTzTDQIYaY1PNMNMCM1GakamGmIZTlpKVaALMXWtCCs+LrV+DrSY0aUHatCGs+DtWhDUjLqdKoagPlNX06VS1AfKaAL/g0/6RMP9j+tdbXIeDj/AKXKP9j+tdfUS3KQUUUVIwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigCK7/wCPSb/cP8q831H/AFrfWvR7v/j0m/3D/KvONR/1pqoiZUWmydKevSmydKoRRm71Rlq/N3qjLVIRXakFK1IKZI9amWoVqZaBkq1ItRrUi0gJBTxTBTxQMcKdTRTqQC0tJS0ALRRRQAUtJS0AFFFFABRRRQAUUUUAFFLRQAlFLSUALRRRQAlFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFJS0lABSUtJQAUlLRTASkpaSgBppDSmkNADTTDTzTDQIaajanmmGmBG1MNPamGmIbSrSU5aALEXWr8FUIutaEFJjRowdq0Iaz4O1aMNSMux9Kpah901dj6VT1D7hoAteD/APj9k/3D/Ouwrj/B/wDx/Sf7h/nXYVEtykFFFFSMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAiu/+PSb/AHD/ACrzfUf9aa9JuObaX/cP8q831Efvm+tVETKq02TpT1psnSqEUZqoS1oTiqEtUiSs1IKc1NFMB61KtRLUq0ATLUgqNakWkBIKeKYKeKBjhThTRTqQCilpKWgBaKSloAKWkpaACiiigAooooAKKKKAClpKKAFpKWigAooooASiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACkpaSgApKWkoAKKKSmAUlLSUANNIaU0hoENNMNPNMNADTUbU80xqYEbUw09qYaYhtOWm05aALEXWtCCqEXatCCkxo0YO1aENUIO1X4akZej6VS1D7pq7H0qjqP3TQBb8Hf8fsn+4f512Fcj4NH+lTH/Y/rXXVEtykFFFFSMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAZMMwuPVT/KvONTGJm+teksMoR7V5zqoxO31qoiZRSiTpSpQ/SqEUJxVCbqa0Zx1rPmHNUhFVqbT2plMQ9alWolqVaAJlqRaiWpVpASLTxTBTxQMcKcKaKcKAFpaQUtIApaSloAKWkpaACiiigAooooAKKKKACiiigAopaSgBaKSloASilooASiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKSiigApKWkoAKSlpKYBSGlpDQA00hpTSGgQ00w080w0AMNMNPNMamBG1MNPNMNMQ2nLTaelAFmHtWhB2qhD1rQtxSY0aEFaEFUIB0rQhqRl1OlZ+on5TWgn3aztSPBoA0vBg/e3B/wBkfzrq65jwYvyXDf7o/nXT1EtykFFFFSMKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAD0rz3W123Ug/2jXoVcL4jTbfS/wC9VREzFSlccUidae3SqEUZxWfMK0phWdOKaEU3plSP1qOqEOWplqFalWgCZalWoVqVaAJFqQVGKeKQx4pRSClFADhS02nUgClpKWgApaSloAKKKKACiiigAooooAKWkooAKWkooAKKKWgBKWikoAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigBKKKKACkpaSgApKWkpgFJRSUAIaaacaaaBDTTTTjTTQAw1G1SGo2pgRmmGnmmGmISnpTKkSgC1D2rQgHSqEI5rRgHSpY0aEAq/CKowCtCEUhltfu1laketav8NY2on5qAOj8Hriymb1YfyroaxfCqbdKB/vOTW1WctylsFFFFIYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAVx3imPF4x9QDXY1zPiuP5kf1XFNCZyKdakPSoxw9SdqsRUmFZ84rTmHFZ04600IoSCojU8g5qE1QhVqRaiFSLQBOtSLUS1ItAEwp4qMU8UhjxThTRThQAtLSUtIBaWkooAWlpKKAFooooAKKKKACiiigAooooAKKKKAFpKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKSgAooooAKSlpKYBSUtJQAlJS0hoAQ000pppoEIaYacaaaYDGpjU81G1ADGphpzUw0xAKkSoxU0YoAtQitKAdKz4BWlAOlSxovwCtCEVRgFaEIpDJm4SsO+OZQPetqY4Q1hTnfcge9AHdaCnl6PB7jNaNQWUflWUEf92MD9KnrNlhRRRSAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKxvE0W+yV8fdOK2ap6tF5unSr3AzTQHm7jEhqQdKS6XbKfrSIeKskjlFZ84rSkHFUZxTQjNlHNV2q1KOarNVCEFPWo6etAE61KtQKalU0ATCnio1p4pASCnCmCnigY4UtNFLQA6ikpaQC0UUUALRSUtABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRSUALSUUUAFFFFABSUUlMAoopKACmmlNIaAENNNKaaaBCGmGnGmGmA01G1PY1G1ADDTTTjTKYhRU8YqFasRdaALkA6VpQDpVCAdK0oBUsaL0Aq/EKpwCrsfApDGXTYQ1k2Ufn6pEnq4FXr98IaPCsPnaur44TLUAd0BgAUUUVkWFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABTZFDoynowxTqKAPN9WhMVw6kdCRVKM10fiq22XbOBw43VzKnDVaJJX5FU5xVwnIqtMOKYjMmHNVHFXpxVOQVSERU5TTaUUxEympVNQKakU0DJ1NSA1CpqQGkBKDTxUQNPBoGPFOpgpwNADqKSlpALS02loAWikpaAFopKKAFopKKAFopKWgAooooAKKKKACilCs33VY/QZpOhwaACiilKsBkqwHrigBKKKOR1GKACigAk4AJ+gpSrDqrD6igBKKKME9FP5UAFFG1v7p/KkoAWikooAKKKKACiikoAWkoopgFJRSUAFBopDQAGm0E0hoEIaaaU00mgBDTCacTUZNMBpNMJpxNRk0xDTSd6DSUAPWrUQ5qslW4RQwL1uK0oB0qhbitKAdKkouwirecLVeEU+V9qUgM7UZeord8GW+IppyOuFFcvdP5kwUetd/oNv9m0mFCMMw3H8aUthrc0aKKKzKCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAxvEtt51kJAOU4/A1wE42SGvVLiITQPE3RlIrzfV7doZ2UjBBxVREyorZFMl5FMRsU5jkVZJRnFUpBWhMKoyimhFY0gpzU2mIkU1IpqEGnqaBlhTUimoFNSKaAJga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BRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAf/9k=',
    'price': '$299',
    'discountPrice': '$199',
    'rating': '4.5',
    'reviewCount': '128',
    'brandName': 'Brand Name',
    'stockStatus': 'In Stock',
    'badgeText': 'New',
    'badgeColor': '#FF0000',
    'quantity': 1,
    'weight': '',
    'weightUnit': 'kg',
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
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            final product = productCards[index];
                            final productId = 'product_${index}';
                            final isInWishlist = _wishlistManager.isInWishlist(productId);
                            return Card(
                              elevation: 3,
                              color: Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:                               Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                      ),
                                      child: product['imageAsset'] != null
                                          ? Image.network(
                                              product['imageAsset'],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] ?? 'Product Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (product['shortDescription'] != null && product['shortDescription'].isNotEmpty)
                                            Text(
                                              product['shortDescription'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Brand: ' + (product['brandName'] ?? '') + '',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          Text(
                                            'Weight: ' + (product['weight'] ?? '') + '',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          Text(
                                            'Stock: ' + (product['stockStatus'] ?? '') + '',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                PriceUtils.formatPrice(
                                                  product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                      : double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: product['discountPrice'] != null ? Colors.blue : Colors.black,
                                                ),
                                              ),
                                              if (product['discountPrice'] != null && product['price'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 6.0),
                                                  child: Text(
                                                    PriceUtils.formatPrice(double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0),
                                                    style: TextStyle(
                                                      fontSize: 10,
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
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    final cartItem = CartItem(
                                                      id: productId,
                                                      name: product['productName'] ?? 'Product',
                                                      price: double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0,
                                                      discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                          ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                          : 0.0,
                                                      image: product['imageAsset'],
                                                    );
                                                    _cartManager.addItem(cartItem);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Added to cart: ${cartItem.effectivePrice.toStringAsFixed(2)}')),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    minimumSize: const Size(double.infinity, 30),
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                  ),
                                                  child: const Text('Add to Cart', style: TextStyle(fontSize: 10)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
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
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                      ),
                                      child: product['imageAsset'] != null
                                          ? Image.network(
                                              product['imageAsset'],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'jeeva',
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