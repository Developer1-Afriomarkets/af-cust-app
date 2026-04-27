import 'package:afriomarkets_cust_app/screens/order_details.dart';
import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

import 'package:afriomarkets_cust_app/repositories/order_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class PaymentStatus {
  String option_key;
  String name;

  PaymentStatus(this.option_key, this.name);

  static List<PaymentStatus> getPaymentStatusList(BuildContext context) {
    return <PaymentStatus>[
      PaymentStatus(
          '', AppLocalizations.of(context)?.order_list_screen_all ?? "All"),
      PaymentStatus('paid',
          AppLocalizations.of(context)?.order_list_screen_paid ?? "Paid"),
      PaymentStatus('unpaid',
          AppLocalizations.of(context)?.order_list_screen_unpaid ?? "Unpaid"),
    ];
  }
}

class DeliveryStatus {
  String option_key;
  String name;

  DeliveryStatus(this.option_key, this.name);

  static List<DeliveryStatus> getDeliveryStatusList(BuildContext context) {
    return <DeliveryStatus>[
      DeliveryStatus(
          '', AppLocalizations.of(context)?.order_list_screen_all ?? "All"),
      DeliveryStatus(
          'confirmed',
          AppLocalizations.of(context)?.order_list_screen_confirmed ??
              "Confirmed"),
      DeliveryStatus(
          'on_delivery',
          AppLocalizations.of(context)?.order_list_screen_on_delivery ??
              "On Delivery"),
      DeliveryStatus(
          'delivered',
          AppLocalizations.of(context)?.order_list_screen_delivered ??
              "Delivered"),
    ];
  }
}

class OrderList extends StatefulWidget {
  OrderList({Key? key, this.from_checkout = false}) : super(key: key);
  final bool from_checkout;

  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  ScrollController _scrollController = ScrollController();
  ScrollController _xcrollController = ScrollController();

  List<PaymentStatus> _paymentStatusList = [];
  List<DeliveryStatus> _deliveryStatusList = [];

  late PaymentStatus _selectedPaymentStatus;
  late DeliveryStatus _selectedDeliveryStatus;

  late List<DropdownMenuItem<PaymentStatus>> _dropdownPaymentStatusItems;
  late List<DropdownMenuItem<DeliveryStatus>> _dropdownDeliveryStatusItems;

  //------------------------------------
  List<dynamic> _orderList = [];
  bool _isInitial = true;
  int _page = 1;
  int _totalData = 0;
  bool _showLoadingContainer = false;
  String _defaultPaymentStatusKey = '';
  String _defaultDeliveryStatusKey = '';

  @override
  void initState() {
    super.initState();
    // Note: fetchData() is called from didChangeDependencies (after init())
    // so that _selectedPaymentStatus / _selectedDeliveryStatus are initialized first.

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    if (_paymentStatusList.isEmpty || _deliveryStatusList.isEmpty) {
      _paymentStatusList = PaymentStatus.getPaymentStatusList(context);
      _deliveryStatusList = DeliveryStatus.getDeliveryStatusList(context);
      init();
      fetchData(); // safe to call here — late fields initialized by init()
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  init() {
    _dropdownPaymentStatusItems =
        buildDropdownPaymentStatusItems(_paymentStatusList);

    _dropdownDeliveryStatusItems =
        buildDropdownDeliveryStatusItems(_deliveryStatusList);

    _selectedPaymentStatus = _paymentStatusList[0];
    _selectedDeliveryStatus = _deliveryStatusList[0];

    for (int x = 0; x < _dropdownPaymentStatusItems.length; x++) {
      if (_dropdownPaymentStatusItems[x].value?.option_key ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems[x].value!;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems.length; x++) {
      if (_dropdownDeliveryStatusItems[x].value?.option_key ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems[x].value!;
      }
    }
  }

  reset() {
    _orderList.clear();
    _isInitial = true;
    _page = 1;
    _totalData = 0;
    _showLoadingContainer = false;
  }

  resetFilterKeys() {
    _defaultPaymentStatusKey = '';
    _defaultDeliveryStatusKey = '';

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    resetFilterKeys();
    for (int x = 0; x < _dropdownPaymentStatusItems.length; x++) {
      if (_dropdownPaymentStatusItems[x].value?.option_key ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems[x].value!;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems.length; x++) {
      if (_dropdownDeliveryStatusItems[x].value?.option_key ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems[x].value!;
      }
    }
    setState(() {});
    fetchData();
  }

  fetchData() async {
    try {
      var orderResponse = await OrderRepository().getOrderList(
          page: _page,
          payment_status: _selectedPaymentStatus.option_key,
          delivery_status: _selectedDeliveryStatus.option_key);
      if (!mounted) return;
      _orderList.addAll(orderResponse.orders);
      _totalData = orderResponse.meta?.total ?? 0;
    } catch (e) {
      // Fail gracefully — _orderList stays empty, _totalData stays 0
      print('[OrderList] fetchData error: $e');
    } finally {
      _isInitial = false;
      _showLoadingContainer = false;
      if (mounted) setState(() {});
    }
  }

  List<DropdownMenuItem<PaymentStatus>> buildDropdownPaymentStatusItems(
      List _paymentStatusList) {
    List<DropdownMenuItem<PaymentStatus>> items = [];
    for (PaymentStatus item in _paymentStatusList) {
      items.add(
        DropdownMenuItem(
          value: item,
          child: Text(item.name),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<DeliveryStatus>> buildDropdownDeliveryStatusItems(
      List _deliveryStatusList) {
    List<DropdownMenuItem<DeliveryStatus>> items = [];
    for (DeliveryStatus item in _deliveryStatusList) {
      items.add(
        DropdownMenuItem(
          value: item,
          child: Text(item.name),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (widget.from_checkout) {
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
                child: Stack(
                  children: [
                    buildOrderListList(),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: buildLoadingContainer())
                  ],
                ),
              )),
        ));
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: MyTheme.surface(context),
      child: Center(
        child: Text(_totalData == _orderList.length
            ? AppLocalizations.of(context)?.order_list_screen_no_more_orders ??
                "No more orders"
            : AppLocalizations.of(context)
                    ?.order_list_screen_loading_more_orders ??
                "Loading more orders ..."),
      ),
    );
  }

  buildBottomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            decoration: BoxDecoration(
                color: MyTheme.surface(context),
                border: Border.all(color: MyTheme.border(context), width: 1),
                borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 36,
            width: MediaQuery.of(context).size.width * .3,
            child: DropdownButton<PaymentStatus>(
              isExpanded: true,
              dropdownColor: MyTheme.surface(context),
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.expand_more, color: MyTheme.secondaryText(context)),
              ),
              hint: Text(
                AppLocalizations.of(context)?.order_list_screen_all ?? "All",
                style: TextStyle(
                  color: MyTheme.primaryText(context),
                  fontSize: 13,
                ),
              ),
              iconSize: 14,
              underline: SizedBox(),
              value: _selectedPaymentStatus,
              items: _dropdownPaymentStatusItems,
              onChanged: (PaymentStatus? selectedFilter) {
                if (selectedFilter == null) return;
                setState(() {
                  _selectedPaymentStatus = selectedFilter;
                });
                reset();
                fetchData();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.credit_card,
              color: MyTheme.secondaryText(context),
              size: 16,
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.local_shipping_outlined,
              color: MyTheme.secondaryText(context),
              size: 16,
            ),
          ),
          Container(
            decoration: BoxDecoration(
                color: MyTheme.surface(context),
                border: Border.all(color: MyTheme.border(context), width: 1),
                borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 36,
            width: MediaQuery.of(context).size.width * .35,
            child: DropdownButton<DeliveryStatus>(
              isExpanded: true,
              dropdownColor: MyTheme.surface(context),
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.expand_more, color: MyTheme.secondaryText(context)),
              ),
              hint: Text(
                AppLocalizations.of(context)?.order_list_screen_all ?? "All",
                style: TextStyle(
                  color: MyTheme.primaryText(context),
                  fontSize: 13,
                ),
              ),
              iconSize: 14,
              underline: SizedBox(),
              value: _selectedDeliveryStatus,
              items: _dropdownDeliveryStatusItems,
              onChanged: (DeliveryStatus? selectedFilter) {
                if (selectedFilter == null) return;
                setState(() {
                  _selectedDeliveryStatus = selectedFilter;
                });
                reset();
                fetchData();
              },
            ),
          ),
        ],
      ),
    );
  }

  buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(150.0),
      child: AppBar(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: [
            new Container(),
          ],
          elevation: 0.0,
          titleSpacing: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 0.0),
            child: Column(
              children: [
                Padding(
                  padding: MediaQuery.of(context).viewPadding.top >
                          30 //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                      ? const EdgeInsets.only(top: 36.0)
                      : const EdgeInsets.only(top: 14.0),
                  child: buildTopAppBarContainer(),
                ),
                buildBottomAppBar(context)
              ],
            ),
          )),
    );
  }

  Container buildTopAppBarContainer() {
    return Container(
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.arrow_back, color: MyTheme.primaryText(context)),
              onPressed: () {
                if (widget.from_checkout) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Main();
                  }));
                } else {
                  return Navigator.of(context).pop();
                }
              },
            ),
          ),
          Text(
            AppLocalizations.of(context)!.profile_screen_purchase_history,
            style: TextStyle(fontSize: 16, color: MyTheme.primaryText(context), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  buildOrderListList() {
    if (_isInitial && _orderList.length == 0) {
      return SingleChildScrollView(
          child: ListView.builder(
        controller: _scrollController,
        itemCount: 10,
        scrollDirection: Axis.vertical,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Shimmer.fromColors(
              baseColor: MyTheme.shimmer_base,
              highlightColor: MyTheme.shimmer_highlighted,
              child: Container(
                height: 75,
                width: double.infinity,
                color: MyTheme.surface(context),
              ),
            ),
          );
        },
      ));
    } else if (_orderList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: MyTheme.surface(context),
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _orderList.length,
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return OrderDetails(
                          id: _orderList[index].id,
                        );
                      }));
                    },
                    child: buildOrderListItemCard(index),
                  ));
            },
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.common_no_data_available, style: TextStyle(color: MyTheme.secondaryText(context))));
    } else {
      return Container(); // should never be happening
    }
  }

  Container buildOrderListItemCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.0,
            spreadRadius: 2.0,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: MyTheme.border(context), width: 1.5),
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
                  _orderList[index].code,
                  style: TextStyle(
                      color: MyTheme.primaryText(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _orderList[index].date,
                  style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 13),
                ),
],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(color: MyTheme.border(context), thickness: 1.0),
            ),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                        AppLocalizations.of(context)!.order_details_screen_grand_total,
                        style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _orderList[index].grand_total,
                        style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                   ],
                 ),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     // Payment Status Chip
                     Container(
                       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: _orderList[index].payment_status == "paid" ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Row(
                         children: [
                           Icon(_orderList[index].payment_status == "paid" ? Icons.check_circle : Icons.error,
                                color: _orderList[index].payment_status == "paid" ? Colors.green : Colors.red, size: 12),
                           SizedBox(width: 4),
                           Text(
                             _orderList[index].payment_status_string,
                             style: TextStyle(
                                 color: _orderList[index].payment_status == "paid" ? Colors.green : Colors.red,
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     ),
                     SizedBox(height: 8),
                     // Delivery Status Chip
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
                             _orderList[index].delivery_status_string,
                             style: TextStyle(
                                 color: Colors.blue,
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     ),
                   ],
                 )
               ]
            ),
          ],
        ),
      ),
    );
  }
}
