import 'package:flutter/material.dart';
import '../models/http_exception.dart';
import 'dart:convert';
import 'product.dart';
import 'package:http/http.dart' as http;

class Products with ChangeNotifier {
  List<Product> _items = [];

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favItems {
    return _items.where((element) => element.isFavorite == true).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((element) => element.id == id);
  }

  Future<void> addProduct(Product product) {
    final url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'products.json',
    );

    return http
        .post(
      url,
      body: json.encode({
        'title': product.title,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'isFavorite': product.isFavorite,
      }),
    )
        .then((value) {
      print(json.decode(value.body));
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(value.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    }).catchError((error) {
      print(error);
      throw error;
    });
  }

  Future<void> updateProduct(String id, Product product) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = Uri.https(
        'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
        'products/$id.json',
      );
      http.patch(
        url,
        body: json.encode(
          {
            'title': product.title,
            'id': product.id,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price
          },
        ),
      );
      _items[prodIndex] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'products/$id.json',
    );
    print(id);
    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeWhere((element) => element.id == id);
    var response = await http.delete(url);
    if (response.statusCode >= 400) {
      print(response.body);
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('An error occurred');
    }
    notifyListeners();
  }

  Future<void> fetchAndSetProducts() async {
    final url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'products.json',
    );
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProduct = [];
      extractedData.forEach((prodId, prodData) {
        loadedProduct.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          imageUrl: prodData['imageUrl'],
          isFavorite: prodData['isFavorite'],
          price: prodData['price'],
        ));
      });
      _items = loadedProduct;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}
