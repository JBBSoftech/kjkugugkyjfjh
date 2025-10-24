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