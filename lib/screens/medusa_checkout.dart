import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/services/medusa_cart_service.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/price_helper.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';
import 'package:afriomarkets_cust_app/screens/order_list.dart';
import 'package:flutter/material.dart';

/// Multi-step Medusa checkout — mirrors the web storefront's checkout-context flow:
///
///   Step 1: Contact & Shipping Address
///   Step 2: Shipping Method
///   Step 3: Payment (manual plugin for now)
///   Step 4: Order Confirmed
class MedusaCheckout extends StatefulWidget {
  const MedusaCheckout({Key? key}) : super(key: key);

  @override
  State<MedusaCheckout> createState() => _MedusaCheckoutState();
}

class _MedusaCheckoutState extends State<MedusaCheckout> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // ── Step 1 state ──────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _countryCode = 'ng';

  // ── Step 2 state ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _shippingOptions = [];
  String? _selectedShippingOptionId;

  // ── Step 3 state ──────────────────────────────────────────────────────────
  Map<String, dynamic>? _cart;
  List<Map<String, dynamic>> _paymentSessions = [];
  String? _selectedProvider;

  // ── Step 4 state ──────────────────────────────────────────────────────────
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = user_email.$;
    _phoneCtrl.text = user_phone.$;
    final nameParts = (user_name.$).trim().split(' ');
    _firstNameCtrl.text = nameParts.isNotEmpty ? nameParts.first : '';
    _lastNameCtrl.text = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _address1Ctrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _handleBack() {
    if (_currentStep > 0 && _currentStep < 4) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Step 1 → submit address ───────────────────────────────────────────────
  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final address = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'address_1': _address1Ctrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'country_code': _countryCode,
      'phone': _phoneCtrl.text.trim(),
    };

    final cart = await MedusaCartService.updateCartAddress(
      email: _emailCtrl.text.trim(),
      shippingAddress: address,
    );

    if (cart == null) {
      if (mounted) {
        ToastComponent.showDialog('Could not save address. Please try again.', context);
        setState(() => _isLoading = false);
      }
      return;
    }

    final options = await MedusaCartService.getShippingOptions();
    if (mounted) {
      setState(() {
        _shippingOptions = options;
        if (options.isNotEmpty) {
          _selectedShippingOptionId = options.first['id'].toString();
        }
        _isLoading = false;
      });
      _goToStep(1);
    }
  }

  // ── Step 2 → select shipping ──────────────────────────────────────────────
  Future<void> _submitShipping() async {
    if (_selectedShippingOptionId == null) {
      ToastComponent.showDialog('Please select a shipping method.', context);
      return;
    }
    setState(() => _isLoading = true);

    final cart = await MedusaCartService.addShippingMethod(_selectedShippingOptionId!);
    if (cart == null) {
      if (mounted) {
        ToastComponent.showDialog('Could not set shipping. Please try again.', context);
        setState(() => _isLoading = false);
      }
      return;
    }

    // Init payment sessions (idempotency-keyed, mirrors web initPayment)
    Map<String, dynamic>? cartWithSessions = cart;
    final existingSessions = (cart['payment_sessions'] as List? ?? []);
    if (existingSessions.isEmpty) {
      cartWithSessions = await MedusaCartService.createPaymentSessions();
    }

    final paymentSessions = List<Map<String, dynamic>>.from(
        (cartWithSessions?['payment_sessions'] as List? ?? []));

    if (mounted) {
      setState(() {
        _cart = cartWithSessions;
        _paymentSessions = paymentSessions;
        _selectedProvider = paymentSessions.isNotEmpty
            ? paymentSessions.first['provider_id'].toString()
            : 'manual';
        _isLoading = false;
      });
      _goToStep(2);
    }
  }

  // ── Step 3 → confirm payment ───────────────────────────────────────────────
  Future<void> _submitPayment() async {
    if (_selectedProvider == null) {
      ToastComponent.showDialog('Please select a payment method.', context);
      return;
    }
    setState(() => _isLoading = true);

    final cartWithSession =
        await MedusaCartService.selectPaymentSession(_selectedProvider!);
    if (cartWithSession == null) {
      if (mounted) {
        ToastComponent.showDialog('Could not initialize payment. Please try again.', context);
        setState(() => _isLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _goToStep(3);
    }
  }

  // ── Step 4 → place order ──────────────────────────────────────────────────
  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    final order = await MedusaCartService.completeCart();
    if (order == null) {
      if (mounted) {
        ToastComponent.showDialog('Order placement failed. Please try again.', context);
        setState(() => _isLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _orderId = order['id']?.toString();
        _isLoading = false;
      });
      _goToStep(4);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MyTheme.brandBackground(
      context: context,
      child: PopScope(
        canPop: _currentStep == 0 || _currentStep == 4,
        onPopInvoked: (didPop) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: MyTheme.isDark(context)
                    ? MyTheme.appBarGradientDark
                    : MyTheme.appBarGradient,
              ),
              child: Stack(
                children: [
                   const Positioned.fill(
                    child: CustomPaint(
                      painter: AfricanSilhouettePainter(
                        baseColor: MyTheme.golden,
                        opacity: 0.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            elevation: 0,
            centerTitle: true,
            leading: _currentStep < 4
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _handleBack,
                  )
                : const SizedBox(),
            title: Text(
              ['Shipping', 'Delivery', 'Payment', 'Review', 'Confirmed']
                  [_currentStep],
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                  ],
                ),
              ),
              if (_isLoading) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    if (_currentStep == 4) return const SizedBox(); // Hide steppers on Success phase
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? MyTheme.primary(context)
                      : active
                          ? MyTheme.golden
                          : MyTheme.border(context),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text('${i + 1}',
                          style: TextStyle(
                              color: active ? Colors.white : MyTheme.secondaryText(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              if (i < 3)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: done ? MyTheme.primary(context) : MyTheme.border(context),
                ),
            ],
          );
        }),
      ),
    ),
  );
}

  // ── Step 1: Address & Contact ─────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(context, 'Contact Information'),
            _buildField(context, _emailCtrl, 'Email address', TextInputType.emailAddress,
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
            _buildField(context, _phoneCtrl, 'Phone number', TextInputType.phone),
            const SizedBox(height: 16),
            _sectionLabel(context, 'Shipping Address'),
            Row(
              children: [
                Expanded(
                    child: _buildField(context, _firstNameCtrl, 'First name', TextInputType.name,
                        validator: (v) => (v ?? '').isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: _buildField(context, _lastNameCtrl, 'Last name', TextInputType.name)),
              ],
            ),
            _buildField(context, _address1Ctrl, 'Address', TextInputType.streetAddress,
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
            _buildField(context, _cityCtrl, 'City', TextInputType.text,
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
            _buildDropdownField(context),
            const SizedBox(height: 24),
            _primaryButton('Continue to Delivery', _submitAddress),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Shipping Options ───────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Choose Delivery Method'),
          const SizedBox(height: 8),
          if (_shippingOptions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 48, color: MyTheme.light_grey),
                    const SizedBox(height: 8),
                    Text('No shipping options available for your address.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: MyTheme.font_grey, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            ..._shippingOptions.map((option) {
              final id = option['id'].toString();
              final name = option['name']?.toString() ?? 'Standard';
              final amount = ((option['amount'] as num?) ?? 0) / 100.0;
              final selected = _selectedShippingOptionId == id;
              return GestureDetector(
                onTap: () => setState(() => _selectedShippingOptionId = id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: selected ? MyTheme.golden : MyTheme.border(context),
                        width: selected ? 2 : 1),
                    borderRadius: BorderRadius.circular(10),
                    color: MyTheme.surface(context),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: MyTheme.golden.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? MyTheme.golden : MyTheme.secondaryText(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(name,
                              style: TextStyle(
                                  color: MyTheme.primaryText(context), fontWeight: FontWeight.w600))),
                      Text(
                        amount == 0 ? 'Free' : PriceHelper.formatPrice((amount * 100).toInt(), 'NGN'),
                        style: TextStyle(
                            color: MyTheme.golden, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          _primaryButton('Continue to Payment', _submitShipping),
        ],
      ),
    );
  }

  // ── Step 3: Payment ────────────────────────────────────────────────────────
  Widget _buildStep3() {
    final total = (_cart?['total'] as num?)?.toDouble() ?? 0;
    final currency = (_cart?['region']?['currency_code'] as String? ?? 'NGN').toUpperCase();
    final totalStr = PriceHelper.formatPrice(total.toInt(), currency);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Payment Method'),
          const SizedBox(height: 8),
          if (_paymentSessions.isEmpty)
            _buildPaymentProviderCard(
                context,
                'manual',
                'Pay on Delivery (Manual)',
                Icons.local_shipping_outlined,
                selected: true)
          else
            ..._paymentSessions.map((session) {
              final pid = session['provider_id'].toString();
              final selected = _selectedProvider == pid;
              return _buildPaymentProviderCard(
                context,
                pid,
                _providerLabel(pid),
                _providerIcon(pid),
                selected: selected,
                onTap: () => setState(() => _selectedProvider = pid),
              );
            }),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyTheme.surface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MyTheme.border(context)),
            ),
            child: Row(
              children: [
                Text('Order Total', style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(totalStr,
                    style: TextStyle(
                        color: MyTheme.golden,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton('Review Order', _submitPayment),
        ],
      ),
    );
  }

  Widget _buildPaymentProviderCard(BuildContext context, String pid,
      String label, IconData icon,
      {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: MyTheme.surface(context),
          border: Border.all(
              color: selected ? MyTheme.golden : MyTheme.border(context),
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: MyTheme.golden.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? MyTheme.golden : MyTheme.secondaryText(context)),
            const SizedBox(width: 12),
            Icon(icon,
                color: selected ? MyTheme.golden : MyTheme.primaryText(context),
                size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: MyTheme.primaryText(context),
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  String _providerLabel(String pid) {
    switch (pid) {
      case 'paystack': return 'Pay with Paystack';
      case 'flutterwave': return 'Pay with Flutterwave';
      case 'manual': return 'Pay on Delivery (Manual)';
      default: return pid;
    }
  }

  IconData _providerIcon(String pid) {
    switch (pid) {
      case 'paystack': return Icons.credit_card;
      case 'flutterwave': return Icons.bolt;
      case 'manual': return Icons.local_shipping_outlined;
      default: return Icons.payment;
    }
  }

  // ── Step 4: Review Order ──────────────────────────────────────────────────
  Widget _buildStep4() {
    final total = (_cart?['total'] as num?)?.toDouble() ?? 0;
    final currency = (_cart?['region']?['currency_code'] as String? ?? 'NGN').toUpperCase();
    final totalStr = PriceHelper.formatPrice(total.toInt(), currency);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Order Summary'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyTheme.surface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MyTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(context, 'Shipping to', '${_firstNameCtrl.text} ${_lastNameCtrl.text}\n${_address1Ctrl.text}, ${_cityCtrl.text}'),
                Divider(color: MyTheme.border(context)),
                _summaryRow(context, 'Delivery Method', _shippingOptions.firstWhere((o) => o['id'].toString() == _selectedShippingOptionId, orElse: () => {'name': 'Standard'})['name'] ?? 'Standard'),
                Divider(color: MyTheme.border(context)),
                _summaryRow(context, 'Payment Method', _providerLabel(_selectedProvider ?? 'manual')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyTheme.golden.withOpacity(0.05),
              border: Border.all(color: MyTheme.golden),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text('Total to Pay', style: TextStyle(color: MyTheme.primaryText(context), fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(totalStr,
                    style: TextStyle(
                        color: MyTheme.golden,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _primaryButton('Complete Order', _placeOrder),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Confirmation ──────────────────────────────────────────────────
  Widget _buildStep5() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyTheme.market_green,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Order Confirmed!',
                style: TextStyle(
                    color: MyTheme.market_green,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            if (_orderId != null) ...[
              const SizedBox(height: 8),
              Text('Order #$_orderId', style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14)),
            ],
            const SizedBox(height: 12),
            Text(
              'Your order has been placed successfully.\nYou will receive updates on delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MyTheme.secondaryText(context), height: 1.6),
            ),
            const SizedBox(height: 32),
            _primaryButton('View My Orders', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => OrderList(from_checkout: true)),
              );
            }),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text('Back to Home',
                  style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: TextStyle(
              color: MyTheme.primaryText(context),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2)),
    );
  }

  Widget _buildField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    TextInputType type, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        validator: validator,
        style: TextStyle(color: MyTheme.primaryText(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: MyTheme.secondaryText(context), fontSize: 14),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.border(context)),
              borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.golden, width: 1.5),
              borderRadius: BorderRadius.circular(8)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.market_red),
              borderRadius: BorderRadius.circular(8)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.market_red, width: 1.5),
              borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    const countries = [
      {'code': 'ng', 'name': 'Nigeria'},
      {'code': 'gh', 'name': 'Ghana'},
      {'code': 'ke', 'name': 'Kenya'},
      {'code': 'za', 'name': 'South Africa'},
      {'code': 'eg', 'name': 'Egypt'},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _countryCode,
        style: TextStyle(color: MyTheme.primaryText(context)),
        dropdownColor: MyTheme.surface(context),
        items: countries.map((c) {
          return DropdownMenuItem<String>(
            value: c['code'],
            child: Text(c['name']!, style: TextStyle(color: MyTheme.primaryText(context))),
          );
        }).toList(),
        onChanged: (v) => setState(() => _countryCode = v ?? 'ng'),
        decoration: InputDecoration(
          labelText: 'Country',
          labelStyle: TextStyle(color: MyTheme.secondaryText(context), fontSize: 14),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.border(context)),
              borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.golden, width: 1.5),
              borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: MyTheme.primary(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
