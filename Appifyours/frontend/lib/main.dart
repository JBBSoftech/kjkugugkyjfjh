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
    'productName': 'uhgil',
    'imageAsset': 'data:image/png;base64,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',
    'price': '76',
    'discountPrice': '65',
    'shortDescription': '',
    'stockStatus': 'In Stock',
    'rating': '4.0',
    'reviewCount': '0',
    'brandName': '',
    'badgeText': '',
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