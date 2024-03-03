import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ProductsPage(),
    );
  }
}

class Product {
  final int id;
  bool isLiked = false;
  final String price;

  Product({required this.id, required this.price});
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final List<Product> _products = [];
  final ScrollController _scrollController = ScrollController();
  var _nextId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProducts();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchProducts();
    }
  }

  void _fetchProducts() {
    final newProducts = List.generate(
      5,
      (index) {
        final product = Product(
            id: _nextId++, price: "₩${(100 + Random().nextInt(900)) * 1000}");

        // 상품이 생성될 때 impression 로그 전송
        sendUserAction(product.id, "impression");

        return product;
      },
    );

    setState(() {
      _products.addAll(newProducts);
    });
  }

  Future<void> sendUserAction(int productId, String action) async {
    const String endpointUrl = "https://yourserver.com/api/track";
    final response = await http.post(
      Uri.parse(endpointUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "productId": productId,
        "action": action,
        "timestamp": DateTime.now().toString()
      }),
    );

    if (response.statusCode == 200) {
      print("$action sent for Product ID: $productId");
    } else {
      print("Failed to send $action for Product ID: $productId");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Products with Actions'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Image.network(
                  'https://via.placeholder.com/400x200',
                  fit: BoxFit.cover,
                  height: 200,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text('Product ${product.id}',
                          style: Theme.of(context).textTheme.headline6),
                      Text(product.price,
                          style: Theme.of(context).textTheme.subtitle1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              product.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.pink,
                            ),
                            onPressed: () {
                              setState(() {
                                product.isLiked = !product.isLiked;
                              });
                              sendUserAction(product.id,
                                  product.isLiked ? "like" : "unlike");
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Buy'),
                            onPressed: () {
                              sendUserAction(product.id, "buy");
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
