import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mock_data.dart';
import 'providers/order_providers.dart';
import '../../core/utils/snackbar_utils.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(ordersProvider.notifier).getById(orderId);
    final theme = Theme.of(context);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download Invoice',
            onPressed: () {
              showAppSnackBar(context, 'Invoice downloaded (mock)');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(order.statusLabel,
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.bold, fontSize: 13,
                  )),
            ),
            const SizedBox(height: 16),

            // ─── Timeline ───
            Text('Order Timeline', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...order.timeline.asMap().entries.map((entry) {
              final i = entry.key;
              final event = entry.value;
              final isLast = i == order.timeline.length - 1;
              return _buildTimelineStep(theme, event, isLast);
            }),

            const SizedBox(height: 20),

            // ─── Items ───
            Text('Items (${order.itemCount})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...order.items.map((item) => _buildItemRow(context, theme, item, order)),

            const Divider(height: 24),

            // ─── Delivery Address ───
            Text('Delivery Address', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.surface,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.deliveryAddress.receiverName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${order.deliveryAddress.line1}, ${order.deliveryAddress.city}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  Text('${order.deliveryAddress.state} - ${order.deliveryAddress.zip}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Payment Method ───
            Text('Payment Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 10),
                  Text(order.paymentMethod, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Price Summary ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ],
              ),
            ),

            if (order.trackingId != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Tracking: ${order.trackingId}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ─── Action Buttons ───
            ..._buildActions(context, ref, theme, order),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(ThemeData theme, TimelineEvent event, bool isLast) {
    final color = event.completed ? theme.colorScheme.primary : Colors.grey.shade300;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event.completed ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: event.completed
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: color),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: event.completed ? null : Colors.grey,
                      )),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(event.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                  if (event.completed) ...[
                    const SizedBox(height: 2),
                    Text(_formatDateTime(event.dateTime),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, ThemeData theme, OrderItem item, Order order) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.product.imageUrl,
              width: 56, height: 56, fit: BoxFit.cover,
              errorWidget: (c1, c2, c3) => Container(
                width: 56, height: 56, color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (item.selectedSize != null || item.selectedColor != null)
                  Text(
                    [if (item.selectedSize != null) 'Size: ${item.selectedSize}',
                     if (item.selectedColor != null) 'Color: ${item.selectedColor}']
                        .join(' | '),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
                Text('Qty: ${item.quantity}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Text('${item.totalPrice.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref, ThemeData theme, Order order) {
    final widgets = <Widget>[];

    switch (order.status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed:
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        widgets.add(SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCancelSheet(context, ref, order.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel Order'),
          ),
        ));
        // Contact support for stuck orders
        if (order.status == OrderStatus.placed) {
          widgets.add(const SizedBox(height: 10));
          widgets.add(SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showAppSnackBar(context, 'Contacting support...');
              },
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text('Contact Support'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ));
        }
        break;

      case OrderStatus.delivered:
        final hasReturnEligible = order.items.any((i) => i.returnEligible);
        if (hasReturnEligible) {
          widgets.add(SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(ordersProvider.notifier).requestReturn(order.id, order.items.first.product.id);
                showAppSnackBar(context, 'Return request submitted');
              },
              icon: const Icon(Icons.assignment_return_outlined, size: 18),
              label: const Text('Return / Exchange'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ));
        } else {
          widgets.add(Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Return window has expired for this order',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 13)),
                ),
              ],
            ),
          ));
        }
        widgets.add(const SizedBox(height: 10));
        widgets.add(Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/review/${order.id}/${order.items.first.product.id}'),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Write Review'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  showAppSnackBar(context, 'Added to cart!');
                },
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Buy Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ));
        break;

      case OrderStatus.cancelled:
        widgets.add(SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              showAppSnackBar(context, 'Items added to cart for reorder!');
            },
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Reorder'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ));
        break;

      case OrderStatus.returned:
        widgets.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Refund has been processed to your account',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
              ),
            ],
          ),
        ));
        break;
    }
    return widgets;
  }

  void _showCancelSheet(BuildContext context, WidgetRef ref, String orderId) {
    final reasons = [
      'Changed my mind',
      'Found a better price',
      'Ordered by mistake',
      'Delivery taking too long',
      'Other',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Cancel Reason',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ...reasons.map((reason) => ListTile(
                  title: Text(reason),
                  leading: const Icon(Icons.radio_button_unchecked, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(ordersProvider.notifier).cancelOrder(orderId, reason);
                    showAppSnackBar(context, 'Order cancelled');
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery: return Colors.orange;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.returned: return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}
