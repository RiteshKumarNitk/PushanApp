import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/models/product.dart';
import '../vip/cart_page.dart';
import '../profile/profile_page.dart';
import '../vip/product_page.dart'; // Source of productListProvider & Bulk Catalog

class CustomerMainScreen extends ConsumerStatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  ConsumerState<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends ConsumerState<CustomerMainScreen> {
  int _currentIndex = 0;
  String selectedCategory = "All";
  final categories = ["All", "White Tea", "Green Tea", "Black Tea", "Herbal"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(),     
              const ProductPage(), // Tab 1: Full Bulk Catalog (User requirement)
              const CartPage(),    // Tab 2: Bag
              const ProfilePage(), // Tab 3: Profile
            ],
          ),
          
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final productsAsync = ref.watch(productListProvider);

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildCategorySelector(),
                    Expanded(
                      child: productsAsync.when(
                        data: (products) {
                           final filtered = selectedCategory == "All" 
                               ? products 
                               : products.where((p) => p.description.contains(selectedCategory) || p.name.contains(selectedCategory)).toList();
                           
                           if (filtered.isEmpty) return const Center(child: Text("No teas found"));

                           return GridView.builder(
                             padding: const EdgeInsets.only(right: 20, bottom: 100, top: 10),
                             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                               crossAxisCount: 2,
                               childAspectRatio: 0.7,
                               crossAxisSpacing: 16,
                               mainAxisSpacing: 16,
                             ),
                             itemCount: filtered.length,
                             itemBuilder: (context, index) => _buildProductCard(filtered[index]),
                           );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text("Error: $e")),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    // Determine display price from first variant or default
    double displayPrice = 0;
    if (product.variants.isNotEmpty) {
      displayPrice = product.variants.first.price;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to 'Favorites'/Catalog tab detailed view or just switch tab?
        // For now, switch to Catalog Tab (Index 1) as it has details
        setState(() => _currentIndex = 1);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Switched to Catalog for details"), duration: Duration(seconds: 1)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : Constants.defaultTeaImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: (context, url, error) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  Positioned(
                      top: 10, right: 10,
                      child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                      )
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Text(
                            "${Constants.currencySymbol}${displayPrice.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Icon(Icons.add_circle, color: Colors.black, size: 24)
                      ]
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 280,
        width: double.infinity,
        color: AppTheme.royalMaroon,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {}),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}), 
                  ],
                )
              ],
            ),
            const Spacer(),
            Text(
              "World's first\nbagless teadips",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            // const Icon(Icons.coffee, color: Colors.white70, size: 28), 
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 50,
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          _buildRotatedText("Focus on today", isActive: false),
          const SizedBox(height: 40),
          _buildRotatedText("The main squeeze", isActive: false),
          const SizedBox(height: 40),
          _buildRotatedText("In mint condition", isActive: true),
        ],
      ),
    );
  }

  Widget _buildRotatedText(String text, {bool isActive = false}) {
    return RotatedBox(
      quarterTurns: 3,
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.black87 : Colors.grey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.home_filled, color: _currentIndex == 0 ? Colors.white : Colors.white54), 
            onPressed: () => setState(() => _currentIndex = 0)
          ),
          IconButton(
            // Heart Icon now maps to Catalog as per my logic (Bulk Catalog is key feature)
            // But icon is Favorite. Let's call it "Collection"
            icon: Icon(Icons.favorite_border, color: _currentIndex == 1 ? Colors.white : Colors.white54), 
            onPressed: () => setState(() => _currentIndex = 1)
          ),
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: _currentIndex == 2 ? Colors.white : Colors.white54), 
            onPressed: () => setState(() => _currentIndex = 2)
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: _currentIndex == 3 ? Colors.white : Colors.white54), 
            onPressed: () => setState(() => _currentIndex = 3)
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
