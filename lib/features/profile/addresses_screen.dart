import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/mock_data.dart';
import '../../core/network/address_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../home/providers/shopping_providers.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  bool _showAddForm = false;
  Address? _editingAddress;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');
  String _addrType = 'Home';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(addressProvider.notifier).fetchAddresses());
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _fullNameCtrl.clear();
    _phoneCtrl.clear();
    _streetCtrl.clear();
    _cityCtrl.clear();
    _stateCtrl.clear();
    _pincodeCtrl.clear();
    _countryCtrl.text = 'India';
    _addrType = 'Home';
    _editingAddress = null;
  }

  void _openAddForm() {
    _clearForm();
    setState(() => _showAddForm = true);
  }

  void _openEditForm(Address address) {
    _editingAddress = address;
    _fullNameCtrl.text = address.receiverName;
    _phoneCtrl.text = address.nickname; // nickname holds phone/label
    _streetCtrl.text = address.line1;
    _cityCtrl.text = address.city;
    _stateCtrl.text = address.state;
    _pincodeCtrl.text = address.zip;
    _countryCtrl.text = address.country;
    _addrType = address.type;
    setState(() => _showAddForm = true);
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = _editingAddress != null;

    if (isEditing) {
      // Edit existing address via service
      final notifier = ref.read(addressProvider.notifier);
      try {
        await notifier.editAddress(
          id: _editingAddress!.id,
          receiverName: _fullNameCtrl.text.trim(),
          nickname: _phoneCtrl.text.trim(),
          line1: _streetCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          zip: _pincodeCtrl.text.trim(),
          country: _countryCtrl.text.trim(),
          type: _addrType,
        );
        if (mounted) {
          showAppSnackBar(context, 'Address updated');
          setState(() => _showAddForm = false);
          _clearForm();
        }
      } catch (e) {
        if (mounted) showAppSnackBar(context, 'Failed to update: $e');
      }
    } else {
      // Add new address
      final newAddr = Address(
        id: '0',
        nickname: _phoneCtrl.text.trim(),
        receiverName: _fullNameCtrl.text.trim(),
        line1: _streetCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        zip: _pincodeCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        type: _addrType,
      );

      final err = await ref.read(addressProvider.notifier).add(newAddr);
      if (!mounted) return;

      if (err != null) {
        showAppSnackBar(context, err);
      } else {
        showAppSnackBar(context, 'Address saved');
        setState(() => _showAddForm = false);
        _clearForm();
      }
    }
  }

  Future<void> _deleteAddress(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address'),
        content:
            const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final err =
        await ref.read(addressProvider.notifier).deleteAddress(address.id);
    if (mounted) {
      showAppSnackBar(
          context, err == null ? 'Address deleted' : 'Error: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [
          if (!_showAddForm)
            TextButton.icon(
              onPressed: _openAddForm,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Saved Addresses List ──
            if (addresses.isEmpty && !_showAddForm)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No saved addresses',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Add a new address to get started',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openAddForm,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New Address'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ...addresses.map((addr) => _buildAddressCard(context, addr)),

            if (addresses.isNotEmpty && !_showAddForm) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openAddForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],

            // ── Add/Edit Form ──
            if (_showAddForm) _buildAddressForm(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address addr) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        border: addr.isDefault
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      addr.type == 'Home'
                          ? Icons.home_outlined
                          : addr.type == 'Office'
                              ? Icons.business_outlined
                              : Icons.location_on_outlined,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(addr.type,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (addr.isDefault) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Default',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              // Edit and Delete buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openEditForm(addr),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _deleteAddress(addr),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(addr.receiverName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (addr.nickname.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(addr.nickname,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
          const SizedBox(height: 4),
          Text(addr.line1,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          if (addr.line2.isNotEmpty)
            Text(addr.line2,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          Text('${addr.city}, ${addr.state} — ${addr.zip}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          Text(addr.country,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          if (!addr.isDefault)
            GestureDetector(
              onTap: () =>
                  ref.read(addressProvider.notifier).setDefault(addr.id),
              child: Text('Set as Default',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressForm(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editingAddress != null;

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEditing ? 'Edit Address' : 'New Address',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    setState(() => _showAddForm = false);
                    _clearForm();
                  },
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Full Name
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 12),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone / Label *',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'e.g. +91 9876543210 or "Home"',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone/label is required' : null,
            ),
            const SizedBox(height: 12),

            // Street
            TextFormField(
              controller: _streetCtrl,
              decoration: const InputDecoration(
                labelText: 'Street Address *',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Street is required' : null,
            ),
            const SizedBox(height: 12),

            // City + State row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'City *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateCtrl,
                    decoration: const InputDecoration(labelText: 'State *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pincode + Country row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeCtrl,
                    decoration: const InputDecoration(labelText: 'Pincode *'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.length < 4) {
                        return 'Enter valid pincode';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _countryCtrl,
                    decoration: const InputDecoration(labelText: 'Country *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address type chips
            Text('Address Type',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: ['Home', 'Office', 'Other'].map((type) {
                final selected = _addrType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _addrType = type),
                    selectedColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isEditing ? 'Update Address' : 'Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension on AddressNotifier for edit
extension on AddressNotifier {
  Future<void> editAddress({
    required String id,
    String? receiverName,
    String? nickname,
    String? line1,
    String? city,
    String? state,
    String? zip,
    String? country,
    String? type,
  }) async {
    final service = AddressService();
    await service.editAddress(
      id: int.parse(id),
      receiverName: receiverName,
      nickname: nickname,
      line1: line1,
      city: city,
      state: state,
      zip: zip,
      country: country,
      type: type,
    );
    await fetchAddresses();
  }
}
