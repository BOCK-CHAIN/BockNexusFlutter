import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_layout.dart';
import '../home/providers/shopping_providers.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).activeItems.length;
    final wishlistCount = ref.watch(wishlistProvider).length;
    final useRail = AppBreakpoints.useSideRail(context);

    void onSelect(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    final destinations = <({Widget icon, Widget selectedIcon, String label})>[
      (
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: 'Home',
      ),
      (
        icon: const Icon(Icons.category_outlined),
        selectedIcon: const Icon(Icons.category),
        label: 'Categories',
      ),
      (
        icon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount', style: const TextStyle(fontSize: 10)),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount', style: const TextStyle(fontSize: 10)),
          child: const Icon(Icons.shopping_cart),
        ),
        label: 'Cart',
      ),
      (
        icon: Badge(
          isLabelVisible: wishlistCount > 0,
          label: Text('$wishlistCount', style: const TextStyle(fontSize: 10)),
          child: const Icon(Icons.favorite_outline),
        ),
        selectedIcon: Badge(
          isLabelVisible: wishlistCount > 0,
          label: Text('$wishlistCount', style: const TextStyle(fontSize: 10)),
          child: const Icon(Icons.favorite),
        ),
        label: 'Wishlist',
      ),
      (
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              minWidth: 72,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: onSelect,
        animationDuration: const Duration(milliseconds: 400),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
            ),
        ],
      ),
    );
  }
}

// Wrapper to preserve scroll state for each tab
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
