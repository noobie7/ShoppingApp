import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> orders = [];

  List<OrderItem> get getOrders {
    return [...orders];
  }

  String? authToken = null;
  String? userId = null;

  Orders({
    required this.authToken,
    required this.orders,
    required this.userId,
  });

  Future<void> fetchAndSetOrders() async {
    final url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'orders/$userId.json',
      {
        'auth': authToken,
      },
    );
    final response = await http.get(url);
    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    if (extractedData == null) {
      return;
    }
    extractedData.forEach(
      (orderId, orderData) {
        loadedOrders.add(
          OrderItem(
            id: orderId,
            amount: orderData['amount'],
            dateTime: DateTime.parse(orderData['dateTime']),
            products: (orderData['products'] as List<dynamic>)
                .map(
                  (e) => CartItem(
                    id: e['id'],
                    title: e['title'],
                    quantity: e['quantity'],
                    price: e['price'],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = Uri.https(
      'shoppingapp-4967e-default-rtdb.asia-southeast1.firebasedatabase.app',
      'orders/$userId.json',
      {
        'auth': authToken,
      },
    );
    final timestamp = DateTime.now();
    final response = await http.post(
      url,
      body: json.encode({
        'amount': total,
        'dateTime': timestamp.toIso8601String(),
        'products': cartProducts
            .map(
              (e) => {
                'id': e.id,
                'title': e.title,
                'quantity': e.quantity,
                'price': e.price
              },
            )
            .toList(),
      }),
    );

    orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        products: cartProducts,
        dateTime: DateTime.now(),
      ),
    );

    notifyListeners();
  }
}
