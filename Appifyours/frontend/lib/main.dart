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
    'productName': 'fan',
    'shortDescription': '100% cotton, Free size',
    'imageAsset': 'data:image/png;base64,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',
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
  },
  {
    'productName': 'Product Name',
    'imageAsset': null,
    'price': '$299',
    'discountPrice': '$199',
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
    return Column(
      children: [
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'jee',
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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Color(0xFFFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            final product = productCards[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 2,
                                color: Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: product['imageAsset'] != null
                                              ? Image.network(
                                                  product['imageAsset'],
                                                  width: 140,
                                                  height: 140,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                                  ),
                                                )
                                              : const Icon(Icons.image, size: 50, color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              product['productName'] ?? 'Product Name',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Highly reordered',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              product['price'] ?? '₹0',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (product['shortDescription'] != null && product['shortDescription'].toString().isNotEmpty)
                                              Text(
                                                product['shortDescription'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
                          itemCount: 1,
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
              ],
            ),
          ),
        ),
      ],
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