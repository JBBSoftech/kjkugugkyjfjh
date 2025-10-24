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
    'productName': 'deena',
    'shortDescription': '100% cotton, Free size',
    'imageAsset': 'data:image/png;base64,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',
    'price': '299',
    'discountPrice': '199',
    'rating': '4.5',
    'reviewCount': '128',
    'brandName': 'Brand Name',
    'stockStatus': 'In Stock',
    'badgeText': 'New',
    'badgeColor': '#FF0000',
    'quantity': 1,
    'weight': '',
    'weightUnit': 'kg',
  },
  {
    'productName': 'jeeva',
    'imageAsset': 'data:image/png;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAdAB0DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD13xn4wtPBOjJql7Z3lzAZRE32VAxTIOGbJAAyAM+pFeU6p+0ai3YGkaE0ltsGTdybH3c54XIx0713fxo/5JLrn/bD/wBHx14RY6HpkvweTV3s0bUP7fW28/Jz5WwHb6YyaAPTdJ/aG0u5ggivdD1E6hI23yrNVkViThQuWBJPHbrXsyncoOCMjOD1r5e17SLDQv2hdN0/TLZLa0i1KwKRJnAyYyevuTX1FQBwXxnBPwl1zAz/AKj/ANHx1862vi+C3+Ha+GTayGYaqt/5wYbdoULtx1zxX2DdWlvfWstrdwRz28q7ZIpVDKw9CD1rm/8AhWvgr/oWtO/79UAfPEniWLxh8cdI1u3tpII7jU7ICJyCw2tGp6f7ua+sa57T/AvhXSr6O9sdBsILmI5jlSIblPqPQ10NAH//2Q==',
    'price': '',
    'discountPrice': '',
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
                                                Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Selected Category: Liter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
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
                          itemCount: 2,
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
                                itemCount: 1,
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