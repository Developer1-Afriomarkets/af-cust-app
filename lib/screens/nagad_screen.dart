import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';
import 'dart:convert';
import 'package:afriomarkets_cust_app/repositories/payment_repository.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:afriomarkets_cust_app/screens/order_list.dart';
import 'package:afriomarkets_cust_app/screens/wallet.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class NagadScreen extends StatefulWidget {
  final double amount;
  final String payment_type;
  final String payment_method_key;
  NagadScreen(
      {Key? key,
      required this.amount,
      required this.payment_type,
      required this.payment_method_key})
      : super(key: key);
  @override
  _NagadScreenState createState() => _NagadScreenState();
}

class _NagadScreenState extends State<NagadScreen> {
  int _combined_order_id = 0;
  bool _order_init = false;
  String _initial_url = "";
  bool _initial_url_fetched = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (widget.payment_type == "cart_payment") {
      createOrder();
    } else {
      getSetInitialUrl();
    }
  }

  createOrder() async {
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponse(widget.payment_method_key);
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(orderCreateResponse.message ?? "", context);
      Navigator.of(context).pop();
      return;
    }
    _combined_order_id = orderCreateResponse.combined_order_id ?? 0;
    _order_init = true;
    setState(() {});
    getSetInitialUrl();
  }

  getSetInitialUrl() async {
    var nagadUrlResponse = await PaymentRepository().getNagadBeginResponse(
        widget.payment_type, _combined_order_id, widget.amount);
    if (nagadUrlResponse.result == false) {
      ToastComponent.showDialog(nagadUrlResponse.message ?? "", context);
      Navigator.of(context).pop();
      return;
    }
    _initial_url = nagadUrlResponse.url ?? "";
    _initial_url_fetched = true;
    _initWebView();
    setState(() {});
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (page) {
          if (page.contains("/nagad/verify/") ||
              page.contains('/check-out/confirm-payment/')) {
            getData();
          }
        },
      ))
      ..loadRequest(Uri.parse(_initial_url));
  }

  void getData() {
    _webViewController!
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
      var decodedJSON = jsonDecode(data.toString());
      Map<String, dynamic> responseJSON = jsonDecode(decodedJSON);
      if (responseJSON["result"] == false) {
        ToastComponent.showDialog(responseJSON["message"], context,
            duration: ToastComponent.lengthLong,
            gravity: ToastComponent.center);
        Navigator.pop(context);
      } else if (responseJSON["result"] == true) {
        onPaymentSuccess(responseJSON['payment_details']);
      }
    });
  }

  onPaymentSuccess(payment_details) async {
    var nagadPaymentProcessResponse = await PaymentRepository()
        .getNagadPaymentProcessResponse(widget.payment_type, widget.amount,
            _combined_order_id, payment_details);
    if (nagadPaymentProcessResponse.result == false) {
      ToastComponent.showDialog(
          nagadPaymentProcessResponse.message ?? "", context,
          duration: ToastComponent.lengthLong, gravity: ToastComponent.center);
      Navigator.pop(context);
      return;
    }
    ToastComponent.showDialog(
        nagadPaymentProcessResponse.message ?? "", context,
        duration: ToastComponent.lengthLong, gravity: ToastComponent.center);
    if (widget.payment_type == "cart_payment") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList(from_checkout: true)));
    } else if (widget.payment_type == "wallet_payment") {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => Wallet(from_recharge: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: buildBody());
  }

  buildBody() {
    if (_order_init == false &&
        _combined_order_id == 0 &&
        widget.payment_type == "cart_payment") {
      return Center(
          child: Text(AppLocalizations.of(context)!.common_creating_order));
    } else if (_initial_url_fetched == false || _webViewController == null) {
      return Center(
          child: Text(
              AppLocalizations.of(context)!.nagad_screen_fetching_nagad_url));
    } else {
      return WebViewWidget(controller: _webViewController!);
    }
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop()),
      title: Text(AppLocalizations.of(context)!.nagad_screen_pay_with_nagad,
          style: TextStyle(fontSize: 16, color: MyTheme.accent_color)),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
