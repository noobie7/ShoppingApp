import 'package:flutter/material.dart';
import 'package:shop/screens/product_detail_screen.dart';
import '../providers/product.dart';
import 'package:provider/provider.dart';
import '../providers/cart.dart';
import '../providers/auth.dart';

class ProductItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final product = Provider.of<Product>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);
    final authData = Provider.of<Auth>(context, listen: false);
    // putting listen to false because only the favorite Icon changes
    // that is now serviced by the Consumer<Product> widget for minimal re-build
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context)
              .pushNamed(ProductDetailScreen.routeName, arguments: product.id);
        },
        child: GridTile(
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
          ),
          footer: GridTileBar(
            backgroundColor: Colors.black54,
            title: Text(
              product.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
              ),
            ),
            leading: Consumer<Product>(
                builder: (ctx, product, child) => IconButton(
                      icon: Icon(
                        (product.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border),
                      ),
                      onPressed: () {
                        product.toggleFavoriteStatus(authData.token as String , authData.userId as String);
                      },
                    ),
                child: const Text(
                    '**** this is a child widget which is one of the arguments in the builder function above it is technically used for the parts of the Consumer widget which are exceptionally to stay constant over time. You can just call it like you would normally use an argument in a function ****')),
            trailing: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                cart.addItem(product.id, product.price, product.title);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Added item to the cart'),
                    action: SnackBarAction(
                      label: "UNDO",
                      onPressed: () {
                        cart.removeSingleItem(product.id);
                      },
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
