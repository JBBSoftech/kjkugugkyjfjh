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
    'productName': '',
    'imageAsset': 'data:image/png;base64,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',
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