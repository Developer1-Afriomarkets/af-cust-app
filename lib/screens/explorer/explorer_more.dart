import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';

class ExplorerMore extends StatelessWidget {
  final ExplorerContext explorerContext;

  const ExplorerMore({Key? key, required this.explorerContext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "More exploratory features coming soon.", 
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
