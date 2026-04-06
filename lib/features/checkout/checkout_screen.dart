import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mock_data.dart';
import '../../core/network/order_service.dart';
import '../home/providers/shopping_providers.dart';
import '../../core/utils/snackbar_utils.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Address form
  final _nicknameCtrl = TextEditingController();
  final _receiverCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  String _addrType = 'Home';
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();

  // Payment
  final _upiCtrl = TextEditingController();
  String? _upiError;
  String? _selectedBank;

  // Promo code on step 3
  final _promoCtrl = TextEditingController();

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _receiverCtrl.dispose();
    _zipCtrl.dispose();
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _upiCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    return PopScope(
      canPop: checkoutState.currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && checkoutState.currentStep > 0) {
          ref.read(checkoutProvider.notifier).previousStep();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (checkoutState.currentStep > 0) {
                ref.read(checkoutProvider.notifier).previousStep();
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Step Indicator
            _buildStepIndicator(context, checkoutState.currentStep),
            const SizedBox(height: 8),

            // Step Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (checkoutState.currentStep) {
                  0 => _buildAddressStep(context),
                  1 => _buildPaymentStep(context, checkoutState),
                  2 => _buildSummaryStep(context, checkoutState),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // STEP INDICATOR
  // ════════════════════════════════════════════

  Widget _buildStepIndicator(BuildContext context, int currentStep) {
    final theme = Theme.of(context);
    final steps = ['Address', 'Payment', 'Summary'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final done = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: done
                      ? theme.colorScheme.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isActive = currentStep == stepIndex;
          final isDone = currentStep > stepIndex;

          return GestureDetector(
            onTap: isDone ? () => ref.read(checkoutProvider.notifier).goToStep(stepIndex) : null,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? theme.colorScheme.primary
                        : isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.grey.shade200,
                    border: isActive
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive || isDone ? FontWeight.w600 : FontWeight.normal,
                    color: isActive || isDone
                        ? theme.colorScheme.primary
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════
  // STEP 1 — ADDRESS
  // ════════════════════════════════════════════

  Widget _buildAddressStep(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = ref.watch(addressProvider);
    final selectedId = ref.watch(selectedAddressProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Delivery Address',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Saved addresses
                ...addresses.map((addr) => _buildAddressCard(context, addr, selectedId == addr.id)),

                const SizedBox(height: 12),

                // Add new address
                if (!_showAddForm)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showAddForm = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Address'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  _buildAddressForm(context),
              ],
            ),
          ),
        ),
        _buildStepButton(context, 'Continue to Payment', () {
          if (selectedId == null) {
            showAppSnackBar(context, 'Please select a delivery address');
            return;
          }
          ref.read(checkoutProvider.notifier).nextStep();
        }),
      ],
    );
  }

  Widget _buildAddressCard(BuildContext context, Address addr, bool selected) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => ref.read(selectedAddressProvider.notifier).set(addr.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) =>
                  ref.read(selectedAddressProvider.notifier).set(addr.id),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(addr.receiverName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(addr.type,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      if (addr.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${addr.line1}, ${addr.line2}',
                      style: theme.textTheme.bodySmall),
                  Text('${addr.city}, ${addr.state} - ${addr.zip}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            PopupMenuButton<String>(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (val) {
                if (val == 'default') {
                  ref.read(addressProvider.notifier).setDefault(addr.id);
                } else if (val == 'delete') {
                  ref.read(addressProvider.notifier).remove(addr.id);
                }
              },
              child: const Icon(Icons.more_vert, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New Address',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _showAddForm = false),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(hintText: 'Label (e.g. Home, Office)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _receiverCtrl,
              decoration: const InputDecoration(hintText: 'Receiver Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addr1Ctrl,
              decoration: const InputDecoration(hintText: 'Address Line 1'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addr2Ctrl,
              decoration: const InputDecoration(hintText: 'Address Line 2 (optional)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(hintText: 'City'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateCtrl,
                    decoration: const InputDecoration(hintText: 'State'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _zipCtrl,
              decoration: const InputDecoration(hintText: 'PIN Code'),
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.length != 6) return 'Enter valid 6-digit PIN code';
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Address type
            Row(
              children: ['Home', 'Work', 'Other'].map((type) {
                final selected = _addrType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _addrType = type),
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAddress,
                child: const Text('Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final newAddr = Address(
      id: '0',
      nickname: _nicknameCtrl.text,
      receiverName: _receiverCtrl.text,
      line1: _addr1Ctrl.text,
      line2: _addr2Ctrl.text,
      city: _cityCtrl.text,
      state: _stateCtrl.text,
      zip: _zipCtrl.text,
      country: 'India',
      type: _addrType,
    );

    final err = await ref.read(addressProvider.notifier).add(newAddr);
    if (!mounted) return;

    if (err != null) {
      showAppSnackBar(context, err);
      return;
    }

    setState(() => _showAddForm = false);
    _nicknameCtrl.clear();
    _receiverCtrl.clear();
    _addr1Ctrl.clear();
    _addr2Ctrl.clear();
    _cityCtrl.clear();
    _stateCtrl.clear();
    _zipCtrl.clear();

    showAppSnackBar(context, 'Address saved');
  }

  // ════════════════════════════════════════════
  // STEP 2 — PAYMENT
  // ════════════════════════════════════════════

  Widget _buildPaymentStep(BuildContext context, CheckoutState checkoutState) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Payment Method',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Saved Cards
                Text('Saved Cards', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ...MockData.savedCards.map((card) => _buildPaymentOption(
                      context,
                      icon: card.brand == 'Visa' ? Icons.credit_card : Icons.payment,
                      title: '${card.brand} •••• ${card.last4}',
                      subtitle:
                          card.isExpired ? 'Expired ${card.expiry}' : 'Expires ${card.expiry}',
                      selected: checkoutState.selectedPayment == PaymentMethod.savedCard &&
                          checkoutState.selectedCardId == card.id,
                      onTap: card.isExpired
                          ? null
                          : () => ref.read(checkoutProvider.notifier).setPaymentMethod(
                              PaymentMethod.savedCard,
                              cardId: card.id),
                      isDisabled: card.isExpired,
                      badge: card.isExpired ? 'Expired' : null,
                    )),

                const SizedBox(height: 16),

                // UPI
                Text('UPI', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'UPI / QR',
                  subtitle: 'Pay using UPI ID',
                  selected: checkoutState.selectedPayment == PaymentMethod.upi,
                  onTap: () =>
                      ref.read(checkoutProvider.notifier).setPaymentMethod(PaymentMethod.upi),
                ),
                if (checkoutState.selectedPayment == PaymentMethod.upi) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _upiCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter UPI ID (e.g. name@upi)',
                        errorText: _upiError,
                      ),
                      onChanged: (_) {
                        if (_upiError != null) setState(() => _upiError = null);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Net Banking
                Text('Net Banking', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance,
                  title: 'Net Banking',
                  subtitle: _selectedBank ?? 'Select your bank',
                  selected: checkoutState.selectedPayment == PaymentMethod.netBanking,
                  onTap: () => _showBankSelector(context),
                ),

                const SizedBox(height: 16),

                // COD
                _buildPaymentOption(
                  context,
                  icon: Icons.money,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your order arrives',
                  selected: checkoutState.selectedPayment == PaymentMethod.cod,
                  onTap: () =>
                      ref.read(checkoutProvider.notifier).setPaymentMethod(PaymentMethod.cod),
                ),

                const SizedBox(height: 16),

                // Wallet
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Nexus Wallet',
                  subtitle: 'Balance: 5,000',
                  selected: checkoutState.selectedPayment == PaymentMethod.wallet,
                  onTap: () =>
                      ref.read(checkoutProvider.notifier).setPaymentMethod(PaymentMethod.wallet),
                ),
              ],
            ),
          ),
        ),
        _buildStepButton(context, 'Review Order', () {
          if (checkoutState.selectedPayment == null) {
            showAppSnackBar(context, 'Please select a payment method');
            return;
          }
          if (checkoutState.selectedPayment == PaymentMethod.upi) {
            final upi = _upiCtrl.text.trim();
            if (!upi.contains('@') || upi.length < 5) {
              setState(() => _upiError = 'Enter valid UPI ID');
              return;
            }
          }
          ref.read(checkoutProvider.notifier).nextStep();
        }),
      ],
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback? onTap,
    bool isDisabled = false,
    String? badge,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade300
                : selected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: isDisabled
              ? Colors.grey.shade50
              : selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isDisabled ? Colors.grey : theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? Colors.grey : null,
                      )),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDisabled ? Colors.red : Colors.grey,
                      )),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22),
          ],
        ),
      ),
    );
  }

  void _showBankSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Bank',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...MockData.banks.map((bank) => ListTile(
                    leading: const Icon(Icons.account_balance, size: 20),
                    title: Text(bank),
                    dense: true,
                    onTap: () {
                      setState(() => _selectedBank = bank);
                      ref
                          .read(checkoutProvider.notifier)
                          .setPaymentMethod(PaymentMethod.netBanking);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════
  // STEP 3 — ORDER SUMMARY
  // ════════════════════════════════════════════

  Widget _buildSummaryStep(BuildContext context, CheckoutState checkoutState) {
    final theme = Theme.of(context);
    final cartState = ref.watch(cartProvider);
    final addresses = ref.watch(addressProvider);
    final selectedId = ref.watch(selectedAddressProvider);
    final selectedAddr =
        addresses.where((a) => a.id == selectedId).firstOrNull ?? addresses.firstOrNull;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Summary',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Items
                ...cartState.activeItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item.product.imageUrl,
                                width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium),
                                Text('Qty: ${item.quantity}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text('${item.totalPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),

                const Divider(height: 24),

                // Address
                if (selectedAddr != null) ...[
                  Text('Delivery Address', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(selectedAddr.receiverName,
                      style: theme.textTheme.bodyMedium),
                  Text(
                      '${selectedAddr.line1}, ${selectedAddr.city}, ${selectedAddr.state} - ${selectedAddr.zip}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 16),
                ],

                // Payment method
                Text('Payment Method', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(_paymentMethodLabel(checkoutState),
                    style: theme.textTheme.bodyMedium),

                const Divider(height: 24),

                // Price summary
                _summaryRow(context, 'Subtotal', '${cartState.subtotal.toStringAsFixed(2)}'),
                _summaryRow(context, 'Discount', '-${cartState.discount.toStringAsFixed(2)}',
                    color: Colors.green.shade700),
                if (cartState.couponDiscount > 0)
                  _summaryRow(context, 'Coupon',
                      '-${cartState.couponDiscount.toStringAsFixed(2)}',
                      color: Colors.green.shade700),
                _summaryRow(
                    context,
                    'Delivery',
                    cartState.deliveryCharge > 0
                        ? '${cartState.deliveryCharge.toStringAsFixed(2)}'
                        : 'FREE',
                    color: cartState.deliveryCharge == 0 ? Colors.green.shade700 : null),
                _summaryRow(context, 'Platform Fee',
                    '${cartState.platformFee.toStringAsFixed(2)}'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${cartState.grandTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        )),
                  ],
                ),

                const SizedBox(height: 16),

                // T&C
                Text(
                  'By placing this order, you agree to our Terms & Conditions and Privacy Policy.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        _buildStepButton(
          context,
          checkoutState.isPlacingOrder ? 'Placing Order...' : 'Place Order',
          checkoutState.isPlacingOrder ? null : () => _placeOrder(context),
          isLoading: checkoutState.isPlacingOrder,
        ),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _paymentMethodLabel(CheckoutState state) {
    switch (state.selectedPayment) {
      case PaymentMethod.savedCard:
        final card = MockData.savedCards.where((c) => c.id == state.selectedCardId).firstOrNull;
        return card != null ? '${card.brand} •••• ${card.last4}' : 'Saved Card';
      case PaymentMethod.upi:
        return 'UPI — ${_upiCtrl.text}';
      case PaymentMethod.netBanking:
        return 'Net Banking — ${_selectedBank ?? ""}';
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.wallet:
        return 'Nexus Wallet';
      default:
        return 'Not selected';
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cartState = ref.read(cartProvider);
    final addresses = ref.read(addressProvider);
    final selectedId = ref.read(selectedAddressProvider);
    final selectedAddr =
        addresses.where((a) => a.id == selectedId).firstOrNull ??
            addresses.firstOrNull;

    if (selectedAddr == null) {
      showAppSnackBar(context, 'Please select a delivery address');
      return;
    }

    if (cartState.activeItems.isEmpty) {
      showAppSnackBar(context, 'Your cart is empty');
      return;
    }

    ref.read(checkoutProvider.notifier).setPlacingOrder(true);
    final nav = GoRouter.of(context);

    try {
      final service = OrderService();
      final items = cartState.activeItems
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
                if (item.productSizeId != null)
                  'productSizeId': item.productSizeId,
              })
          .toList();

      final order = await service.placeOrder(
        items: items,
        totalAmount: cartState.grandTotal,
        addressId: selectedAddr.id,
        paymentMethod: _paymentMethodLabel(ref.read(checkoutProvider)),
      );

      await ref.read(cartProvider.notifier).clearAll();
      ref.read(checkoutProvider.notifier).reset();

      final orderId = order['id']?.toString() ?? 'N/A';
      nav.goNamed('order_success', pathParameters: {'orderId': orderId});
    } catch (e) {
      ref.read(checkoutProvider.notifier).setPlacingOrder(false);
      if (mounted) {
        showAppSnackBar(context, 'Failed to place order: ${e.toString()}');
      }
    }
  }

  // ════════════════════════════════════════════
  // STEP BUTTON
  // ════════════════════════════════════════════

  Widget _buildStepButton(BuildContext context, String label, VoidCallback? onPressed,
      {bool isLoading = false}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
