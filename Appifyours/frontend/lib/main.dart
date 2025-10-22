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
    'productName': 'sambar',
    'imageAsset': 'data:image/png;base64,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',
    'price': '290',
    'discountPrice': '',
  },
  {
    'productName': 'rasam',
    'imageAsset': 'data:image/png;base64,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',
    'price': '400',
    'discountPrice': '5',
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
                          'jeeva anandhann',
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
                          'All Categories',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
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
                                ],
                              )
                              ,
                            );
                          },
                        );
                      },
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