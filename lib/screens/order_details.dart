import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

import 'package:timeline_tile/timeline_tile.dart';
import 'package:afriomarkets_cust_app/repositories/order_repository.dart';
import 'package:afriomarkets_cust_app/helpers/shimmer_helper.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:afriomarkets_cust_app/repositories/refund_request_repository.dart';
import 'package:afriomarkets_cust_app/screens/refund_request.dart';
import 'dart:async';
import 'package:afriomarkets_cust_app/screens/checkout.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class OrderDetails extends StatefulWidget {
  final int id;
  final bool from_notification;
  final bool go_back;

  OrderDetails(
      {Key? key,
      required this.id,
      this.from_notification = false,
      this.go_back = true})
      : super(key: key);

  @override
  _OrderDetailsState createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  ScrollController _mainScrollController = ScrollController();
  var _steps = ['pending', 'confirmed', 'on_delivery', 'delivered'];

  TextEditingController _refundReasonController = TextEditingController();
  bool _showReasonWarning = false;

  //init
  int _stepIndex = 0;
  var _orderDetails = null;
  List<dynamic> _orderedItemList = [];
  bool _orderItemsInit = false;

  @override
  void initState() {
    fetchAll();
    super.initState();

    print(widget.id);
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _refundReasonController.dispose();
    super.dispose();
  }

  fetchAll() {
    fetchOrderDetails();
    fetchOrderedItems();
  }

  fetchOrderDetails() async {
    var orderDetailsResponse =
        await OrderRepository().getOrderDetails(id: widget.id);

    if (orderDetailsResponse.detailed_orders.length > 0) {
      _orderDetails = orderDetailsResponse.detailed_orders[0];
      setStepIndex(_orderDetails.delivery_status);
    }

    setState(() {});
  }

  setStepIndex(key) {
    _stepIndex = _steps.indexOf(key);
    setState(() {});
  }

  fetchOrderedItems() async {
    var orderItemResponse =
        await OrderRepository().getOrderItems(id: widget.id);
    _orderedItemList.addAll(orderItemResponse.ordered_items);
    _orderItemsInit = true;

    setState(() {});
  }

  reset() {
    _stepIndex = 0;
    _orderDetails = null;
    _orderedItemList.clear();
    _orderItemsInit = false;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  onPressOfflinePaymentButton() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Checkout(
        order_id: widget.id,
        list: "offline",
        manual_payment_from_order_details: true,
      );
    })).then((value) {
      onPopped(value);
    });
  }

  onTapAskRefund(item_id, item_name, order_code) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                  top: 36.0, left: 36.0, right: 36.0, bottom: 2.0),
              content: Container(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(
                                AppLocalizations.of(context)!
                                    .order_details_screen_refund_product_name,
                                style: TextStyle(
                                    color: MyTheme.font_grey, fontSize: 12)),
                            Container(
                              width: 225,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(item_name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                        color: MyTheme.font_grey,
                                        fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(
                                AppLocalizations.of(context)!
                                    .order_details_screen_refund_order_code,
                                style: TextStyle(
                                    color: MyTheme.font_grey, fontSize: 12)),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(order_code,
                                  style: TextStyle(
                                      color: MyTheme.font_grey, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(
                                "${AppLocalizations.of(context)!.order_details_screen_refund_reason} *",
                                style: TextStyle(
                                    color: MyTheme.font_grey, fontSize: 12)),
                            _showReasonWarning
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                    ),
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .order_details_screen_refund_reason_empty_warning,
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 12)),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          height: 55,
                          child: TextField(
                            controller: _refundReasonController,
                            autofocus: false,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!
                                    .order_details_screen_refund_enter_reason,
                                hintStyle: TextStyle(
                                    fontSize: 12.0,
                                    color: MyTheme.textfield_grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 0.5),
                                  borderRadius: const BorderRadius.all(
                                    const Radius.circular(8.0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 1.0),
                                  borderRadius: const BorderRadius.all(
                                    const Radius.circular(8.0),
                                  ),
                                ),
                                contentPadding: EdgeInsets.only(
                                    left: 8.0, top: 16.0, bottom: 16.0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size(75, 30),
                          backgroundColor: Color.fromRGBO(253, 253, 253, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                                color: MyTheme.light_grey, width: 1.0),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .common_close_in_all_capital,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                          ),
                        ),
                        onPressed: () {
                          _refundReasonController.clear();
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 28.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size(75, 30),
                          backgroundColor: MyTheme.accent_color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                                color: MyTheme.light_grey, width: 1.0),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.common_submit,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          onPressSubmitRefund(item_id, setState);
                        },
                      ),
                    )
                  ],
                )
              ],
            );
          });
        });
  }

  shoWReasonWarning(setState) {
    setState(() {
      _showReasonWarning = true;
    });
    Timer timer = Timer(Duration(seconds: 2), () {
      setState(() {
        _showReasonWarning = false;
      });
    });
  }

  onPressSubmitRefund(item_id, setState) async {
    var reason = _refundReasonController.text.toString();

    if (reason == "") {
      shoWReasonWarning(setState);
      return;
    }

    var refundRequestSendResponse = await RefundRequestRepository()
        .getRefundRequestSendResponse(id: item_id, reason: reason);

    if (refundRequestSendResponse.result == false) {
      ToastComponent.showDialog(refundRequestSendResponse.message, context);
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
    _refundReasonController.clear();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        refundRequestSendResponse.message ?? "",
        style: TextStyle(color: MyTheme.font_grey),
      ),
      backgroundColor: MyTheme.soft_accent_color,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!
            .order_details_screen_refund_snackbar_show_request_list,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return RefundRequest();
          })).then((value) {
            onPopped(value);
          });
        },
        textColor: MyTheme.accent_color,
        disabledTextColor: Colors.grey,
      ),
    ));

    reset();
    fetchAll();
    setState(() {});
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (widget.from_notification || widget.go_back == false) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Main();
          }));
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Directionality(
        textDirection:
            app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: buildAppBar(context),
          body: MyTheme.brandBackground(
            context: context,
            child: RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: MyTheme.surface(context),
              onRefresh: _onPageRefresh,
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _orderDetails != null
                            ? buildTimeLineTiles()
                            : buildTimeLineShimmer()),
                  ),
                  SliverList(
                      delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _orderDetails != null
                          ? buildOrderDetailsTopCard()
                          : ShimmerHelper().buildBasicShimmer(height: 150.0),
                    ),
                  ])),
                  SliverList(
                      delegate: SliverChildListDelegate([
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!
                            .order_details_screen_ordered_product,
                        style: TextStyle(
                            color: MyTheme.secondaryText(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _orderedItemList.length == 0 && _orderItemsInit
                            ? ShimmerHelper().buildBasicShimmer(height: 100.0)
                            : (_orderedItemList.length > 0
                                ? buildOrderdProductList()
                                : Container(
                                    height: 100,
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .order_details_screen_ordered_product,
                                      style: TextStyle(color: MyTheme.secondaryText(context)),
                                    ),
                                  )))
                  ])),
                  SliverList(
                      delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 75),
                          buildBottomSection()
                        ],
                      ),
                    )
                  ])),
                  SliverList(
                      delegate:
                          SliverChildListDelegate([buildPaymentButtonSection()]))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildBottomSection() {
    return Expanded(
      child: _orderDetails != null
          ? Column(
              children: [
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          child: Text(
                            AppLocalizations.of(context)!
                                .order_details_screen_sub_total,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _orderDetails.subtotal,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          child: Text(
                            AppLocalizations.of(context)!
                                .order_details_screen_tax,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _orderDetails.tax,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          child: Text(
                            AppLocalizations.of(context)!
                                .order_details_screen_shipping_cost,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _orderDetails.shipping_cost,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          child: Text(
                            AppLocalizations.of(context)!
                                .order_details_screen_discount,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _orderDetails.coupon_discount,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
                Divider(),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          child: Text(
                            AppLocalizations.of(context)!
                                .order_details_screen_grand_total,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _orderDetails.grand_total,
                          style: TextStyle(
                              color: MyTheme.accent_color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
              ],
            )
          : ShimmerHelper().buildBasicShimmer(height: 100.0),
    );
  }

  buildTimeLineShimmer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            )
          ],
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: ShimmerHelper().buildBasicShimmer(height: 20, width: 250.0),
        )
      ],
    );
  }

  buildTimeLineTiles() {
    print(_orderDetails.delivery_status);
    return SizedBox(
      height: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TimelineTile(
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.end,
            isFirst: true,
            startChild: Container(
              height: 50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: _orderDetails.delivery_status == "pending" ? 36 : 30,
                    height:
                        _orderDetails.delivery_status == "pending" ? 36 : 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.redAccent, width: 2),

                      //shape: BoxShape.rectangle,
                    ),
                    child: Icon(
                      Icons.list_alt,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                          height: 2.0,
                          color: MyTheme.medium_grey_50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      AppLocalizations.of(context)!
                          .order_details_screen_timeline_tile_order_placed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MyTheme.font_grey),
                    ),
                  )
                ],
              ),
            ),
            indicatorStyle: IndicatorStyle(
              color: _stepIndex >= 0 ? Colors.green : MyTheme.medium_grey,
              padding: const EdgeInsets.all(0),
              iconStyle: _stepIndex >= 0
                  ? IconStyle(
                      color: Colors.white, iconData: Icons.check, fontSize: 16)
                  : null,
            ),
            afterLineStyle: _stepIndex >= 1
                ? LineStyle(
                    color: Colors.green,
                    thickness: 5,
                  )
                : LineStyle(
                    color: MyTheme.medium_grey,
                    thickness: 4,
                  ),
          ),
          TimelineTile(
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.end,
            startChild: Container(
              height: 50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width:
                        _orderDetails.delivery_status == "confirmed" ? 36 : 30,
                    height:
                        _orderDetails.delivery_status == "confirmed" ? 36 : 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.blue, width: 2),

                      //shape: BoxShape.rectangle,
                    ),
                    child: Icon(
                      Icons.thumb_up_sharp,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                          height: 2.0,
                          color: MyTheme.medium_grey_50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      AppLocalizations.of(context)!
                          .order_details_screen_timeline_tile_confirmed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MyTheme.font_grey),
                    ),
                  )
                ],
              ),
            ),
            indicatorStyle: IndicatorStyle(
              color: _stepIndex >= 1 ? Colors.green : MyTheme.medium_grey,
              padding: const EdgeInsets.all(0),
              iconStyle: _stepIndex >= 1
                  ? IconStyle(
                      color: Colors.white, iconData: Icons.check, fontSize: 16)
                  : null,
            ),
            beforeLineStyle: _stepIndex >= 1
                ? LineStyle(
                    color: Colors.green,
                    thickness: 5,
                  )
                : LineStyle(
                    color: MyTheme.medium_grey,
                    thickness: 4,
                  ),
            afterLineStyle: _stepIndex >= 2
                ? LineStyle(
                    color: Colors.green,
                    thickness: 5,
                  )
                : LineStyle(
                    color: MyTheme.medium_grey,
                    thickness: 4,
                  ),
          ),
          TimelineTile(
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.end,
            startChild: Container(
              height: 50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: _orderDetails.delivery_status == "on_delivery"
                        ? 36
                        : 30,
                    height: _orderDetails.delivery_status == "on_delivery"
                        ? 36
                        : 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.amber, width: 2),

                      //shape: BoxShape.rectangle,
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                          height: 2.0,
                          color: MyTheme.medium_grey_50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      AppLocalizations.of(context)!
                          .order_details_screen_timeline_tile_on_delivery,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MyTheme.font_grey),
                    ),
                  )
                ],
              ),
            ),
            indicatorStyle: IndicatorStyle(
              color: _stepIndex >= 2 ? Colors.green : MyTheme.medium_grey,
              padding: const EdgeInsets.all(0),
              iconStyle: _stepIndex >= 2
                  ? IconStyle(
                      color: Colors.white, iconData: Icons.check, fontSize: 16)
                  : null,
            ),
            beforeLineStyle: _stepIndex >= 2
                ? LineStyle(
                    color: Colors.green,
                    thickness: 5,
                  )
                : LineStyle(
                    color: MyTheme.medium_grey,
                    thickness: 4,
                  ),
            afterLineStyle: _stepIndex >= 3
                ? LineStyle(
                    color: Colors.green,
                    thickness: 5,
                  )
                : LineStyle(
                    color: MyTheme.medium_grey,
                    thickness: 4,
                  ),
          ),
          TimelineTile(
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.end,
            isLast: true,
            startChild: Container(
              height: 50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width:
                        _orderDetails.delivery_status == "delivered" ? 36 : 30,
                    height:
                        _orderDetails.delivery_status == "delivered" ? 36 : 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.purple, width: 2),

                      //shape: BoxShape.rectangle,
                    ),
                    child: Icon(
                      Icons.done_all,
                      color: Colors.purple,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                          height: 2.0,
                          color: MyTheme.medium_grey_50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      AppLocalizations.of(context)!
                          .order_details_screen_timeline_tile_delivered,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MyTheme.font_grey),
                    ),
                  )
                ],
              ),
            ),
            indicatorStyle: IndicatorStyle(
              color: _stepIndex >= 3 ? Colors.green : MyTheme.medium_grey,
              padding: const EdgeInsets.all(0),
              iconStyle: _stepIndex >= 3
                  ? IconStyle(
                      color: Colors.white, iconData: Icons.check, fontSize: 16)
                  : null,
            ),
            beforeLineStyle: _stepIndex >= 3
                ? LineStyle(
                    color: Colors.green,
                    thickness: 5,
                  )
                : LineStyle(
                    color: MyTheme.medium_grey,
                    thickness: 4,
                  ),
          ),
        ],
      ),
    );
  }

  Container buildOrderDetailsTopCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.0,
            spreadRadius: 2.0,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: MyTheme.medium_grey_50, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _orderDetails.code ?? '',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _orderDetails.date ?? '',
                  style: TextStyle(color: MyTheme.font_grey, fontSize: 13),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(color: MyTheme.light_grey, thickness: 1.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Payment Method", style: TextStyle(color: MyTheme.font_grey, fontSize: 12)),
                    SizedBox(height: 4),
                    Text(_orderDetails.payment_type ?? 'N/A', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 16),
                    Text("Shipping Method", style: TextStyle(color: MyTheme.font_grey, fontSize: 12)),
                    SizedBox(height: 4),
                    Text(_orderDetails.shipping_type_string ?? 'N/A', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                     Container(
                       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: _orderDetails.payment_status == "paid" ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Row(
                         children: [
                           Icon(_orderDetails.payment_status == "paid" ? Icons.check_circle : Icons.error,
                                color: _orderDetails.payment_status == "paid" ? Colors.green : Colors.red, size: 12),
                           SizedBox(width: 4),
                           Text(
                             _orderDetails.payment_status_string ?? '',
                             style: TextStyle(
                                 color: _orderDetails.payment_status == "paid" ? Colors.green : Colors.red,
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     ),
                     SizedBox(height: 12),
                     Container(
                       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: Colors.blue.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.local_shipping, color: Colors.blue, size: 12),
                           SizedBox(width: 4),
                           Text(
                             _orderDetails.delivery_status_string ?? '',
                             style: TextStyle(
                                 color: Colors.blue,
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     ),
                  ]
                )
              ]
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(color: MyTheme.light_grey, thickness: 1.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                 Container(
                   width: (MediaQuery.of(context).size.width - 72.0) / 2,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("Shipping Address", style: TextStyle(color: MyTheme.font_grey, fontSize: 12)),
                       SizedBox(height: 6),
                       if (_orderDetails.shipping_address.name != null)
                         Text(_orderDetails.shipping_address.name!, style: TextStyle(color: MyTheme.grey_153, fontSize: 13, height: 1.4)),
                       if (_orderDetails.shipping_address.address != null)
                         Text(_orderDetails.shipping_address.address!, style: TextStyle(color: MyTheme.grey_153, fontSize: 13, height: 1.4)),
                       if (_orderDetails.shipping_address.city != null)
                         Text("${_orderDetails.shipping_address.city}, ${_orderDetails.shipping_address.country ?? ''}", style: TextStyle(color: MyTheme.grey_153, fontSize: 13, height: 1.4)),
                       if (_orderDetails.shipping_address.phone != null)
                         Text("Phone: ${_orderDetails.shipping_address.phone}", style: TextStyle(color: MyTheme.grey_153, fontSize: 13, height: 1.4)),
                     ]
                   )
                 ),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                      Text(
                        AppLocalizations.of(context)!.order_details_screen_grand_total,
                        style: TextStyle(color: MyTheme.font_grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _orderDetails.grand_total,
                        style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                   ],
                 ),
              ]
            )
          ],
        ),
      ),
    );
  }

  Container buildOrderedProductItemsCard(index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.0,
            spreadRadius: 2.0,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: MyTheme.medium_grey_50, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _orderedItemList[index].product_name,
                maxLines: 2,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _orderedItemList[index].quantity.toString() + " x ",
                      style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    _orderedItemList[index].variation != "" &&
                            _orderedItemList[index].variation != null
                        ? Text(
                            _orderedItemList[index].variation,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          )
                        : Text(
                            "item",
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                  ],
                ),
                Text(
                  _orderedItemList[index].price,
                  style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
            _orderedItemList[index].refund_section &&
                    _orderedItemList[index].refund_button
                ? InkWell(
                    onTap: () {
                      onTapAskRefund(
                          _orderedItemList[index].id,
                          _orderedItemList[index].product_name,
                          _orderDetails.code);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .order_details_screen_ask_for_refund,
                            style: TextStyle(
                                color: MyTheme.accent_color,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 2.0),
                            child: Icon(
                              Icons.rotate_left,
                              color: MyTheme.accent_color,
                              size: 14,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
            _orderedItemList[index].refund_section &&
                    _orderedItemList[index].refund_label != ""
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .order_details_screen_refund_status,
                            style: TextStyle(color: MyTheme.font_grey),
                          ),
                          Text(
                            _orderedItemList[index].refund_label,
                            style: TextStyle(
                                color: getRefundRequestLabelColor(
                                    _orderedItemList[index]
                                        .refund_request_status)),
                          ),
                        ],
                      ),
                    ],
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  getRefundRequestLabelColor(status) {
    if (status == 0) {
      return Colors.blue;
    } else if (status == 2) {
      return Colors.orange;
    } else if (status == 1) {
      return Colors.green;
    } else {
      return MyTheme.font_grey;
    }
  }

  buildOrderdProductList() {
    return SingleChildScrollView(
      child: ListView.builder(
        itemCount: _orderedItemList.length,
        scrollDirection: Axis.vertical,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: buildOrderedProductItemsCard(index),
          );
        },
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
            onPressed: () {
              if (widget.from_notification || widget.go_back == false) {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return Main();
                }));
              } else {
                return Navigator.of(context).pop();
              }
            }),
      ),
      title: Text(
        AppLocalizations.of(context)!.order_details_screen_order_details,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildPaymentButtonSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _orderDetails != null && _orderDetails.manually_payable
              ? TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: MyTheme.soft_accent_color,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .order_details_screen_make_offline_payment,
                    style: TextStyle(color: MyTheme.font_grey),
                  ),
                  onPressed: () {
                    onPressOfflinePaymentButton();
                  },
                )
              : Container(),
        ],
      ),
    );
  }

  Container buildPaymentStatusCheckContainer(String payment_status) {
    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50.0),
          color: payment_status == "paid" ? Colors.green : Colors.red),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(payment_status == "paid" ? Icons.check : Icons.close,
            color: Colors.white, size: 10),
      ),
    );
  }
}
