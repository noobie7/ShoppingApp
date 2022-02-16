import 'package:flutter/material.dart';
import 'package:shop/screens/cart_screen.dart';
import 'package:shop/screens/edit_product_screen.dart';
import 'package:shop/screens/orders_screen.dart';
import 'package:shop/screens/product_detail_screen.dart';
import 'package:shop/screens/user_products_screen.dart';
import './screens/products_overview_screen.dart';
import 'package:provider/provider.dart';
import './providers/products.dart';
import './providers/cart.dart';
import './providers/orders.dart';
import './screens/auth_screen.dart';
import './providers/auth.dart';
import 'dart:io';
import './screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Products>(
          create: (ctx) => Products(authToken: null, userId: null, items: []),
          update: (context, auth, previous) => Products(
            authToken: auth.token,
            userId: auth.userId,
            items: previous == null ? [] : previous.items,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Cart(),
        ),
        ChangeNotifierProxyProvider<Auth, Orders>(
          create: (ctx) => Orders(authToken: null, orders: [], userId: null),
          update: (ctx, auth, previous) => Orders(
            authToken: auth.token,
            userId: auth.userId,
            orders: previous == null ? [] : previous.getOrders,
          ),
        )
      ],
      child: Consumer<Auth>(
        builder: (context, auth, _) => MaterialApp(
              title: 'Flutter Demo',
              theme: ThemeData(
                primarySwatch: Colors.purple,
                fontFamily: 'Azeret',
              ),
              home: auth.isAuth
                  ? ProductsOverviewScreen()
                  : FutureBuilder(
                      builder: (context, snapshot) =>
                          snapshot.connectionState == ConnectionState.waiting
                              ? SplashScreen()
                              : AuthScreen(),
                      future: auth.tryAutoLogin(),
                    ),
              routes: {
                ProductDetailScreen.routeName: (ctx) => ProductDetailScreen(),
                CartScreen.routeName: (ctx) => CartScreen(),
                OrderScreen.routeName: (ctx) => OrderScreen(),
                UserProductsScreen.routeName: (ctx) => UserProductsScreen(),
                EditProductScreen.routeName: (ctx) => EditProductScreen(),
                AuthScreen.routeName: (ctx) => AuthScreen(),
              },
            ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProductsOverviewScreen();
  }
}
