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
                    height: 160,
                    child: Stack(
                      children: [
                        Container(color: Color(0xFFBDBDBD)),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'hey hi!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('dude', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
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
                        const Text(
                          'Share this product',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.facebook, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Facebook', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.alternate_email, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Twitter', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.message, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('WhatsApp', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.link, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Copy Link', style: TextStyle(fontSize: 10)),
                              ],
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