import 'package:flutter/material.dart';
import '../models/http_exception.dart';
import 'dart:convert';
import 'product.dart';
import 'package:http/http.dart' as http;

class Products with ChangeNotifier {
  List<Product> items = [];

  final String? authToken;
  final String? userId;

  Products({
    required this.authToken,
    required this.items,
    required this.userId,
  });

  List<Product> get getItems {
    return [...items];
  }

  List<Product> get favItems {
    return items.where((element) => element.isFavorite == true).toList();
  }

  Product findById(String id) {
    return items.firstWhere((element) => element.id == id);
  }

  Future<void> addProduct(Product product) {
    final url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'products.json',
      {
        'auth': authToken,
      },
    );

    return http
        .post(
      url,
      body: json.encode(
        {
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'creatorId': userId,
        },
      ),
    )
        .then(
      (value) {
        print(json.decode(value.body));
        final newProduct = Product(
          title: product.title,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          id: json.decode(value.body)['name'],
        );
        items.add(newProduct);
        notifyListeners();
      },
    ).catchError(
      (error) {
        print(error);
        throw error;
      },
    );
  }

  Future<void> updateProduct(String id, Product product) async {
    final prodIndex = items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = Uri.https(
        'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
        'products/$id.json',
        {
          'auth': authToken,
        },
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
      items[prodIndex] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'products/$id.json',
      {
        'auth': authToken,
      },
    );
    print(id);
    final existingProductIndex =
        items.indexWhere((element) => element.id == id);
    var existingProduct = items[existingProductIndex];
    items.removeWhere((element) => element.id == id);
    var response = await http.delete(url);
    if (response.statusCode >= 400) {
      print(response.body);
      items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('An error occurred');
    }
    notifyListeners();
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    var param = {
      'auth': authToken,
    };
    if (filterByUser) {
      param = {
        'auth': authToken,
        'orderBy': jsonEncode('creatorId'),
        'equalTo': jsonEncode(userId),
      };
    }
    var url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'products.json',
      param,
    );
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      print(extractedData);
      final List<Product> loadedProduct = [];
      url = Uri.https(
        'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
        'userFavorites/$userId.json',
        {
          'auth': authToken,
        },
      );
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);

      extractedData.forEach((prodId, prodData) {
        loadedProduct.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          imageUrl: prodData['imageUrl'],
          price: prodData['price'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
        ));
      });
      items = loadedProduct;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}
