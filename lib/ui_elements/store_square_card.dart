import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart';
import 'package:afriomarkets_cust_app/ui_elements/shop_square_card.dart';

/// A wrapper around ShopSquareCard to fit naming conventions in the Explorer Subsystem.
/// Store maps semantically to Shop in the Afriomarkets data model. 
class StoreSquareCard extends StatelessWidget {
  final Shop store;
  final VoidCallback? onTapOverride;

  const StoreSquareCard({
    Key? key,
    required this.store,
    this.onTapOverride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onTapOverride != null) {
      // Overriding standard shop tap behavior to keep navigation within Explorer
      return GestureDetector(
        onTap: onTapOverride,
        child: AbsorbPointer(
          child: ShopSquareCard(
            id: store.id,
            image: store.logo,
            name: store.name,
          ),
        ),
      );
    }
    
    // Default behavior navigates directly to the Seller Details
    return ShopSquareCard(
      id: store.id,
      image: store.logo,
      name: store.name,
    );
  }
}
