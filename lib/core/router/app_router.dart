import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/categories/subcategory_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/order_success/order_success_screen.dart';
import '../../features/orders/my_orders_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/write_review_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_products_screen.dart';
import '../../features/admin/screens/admin_product_editor_screen.dart';
import '../../features/admin/screens/admin_categories_screen.dart';
import '../../features/admin/screens/admin_category_editor_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Future<String?> _adminRouteRedirect(Ref ref) async {
  var authState = ref.read(authProvider);

  // If auth isn't initialized yet (e.g. deep-link/refresh on /admin),
  // try to load the stored token before deciding where to redirect.
  if (authState.status != AuthStatus.authenticated) {
    await ref.read(authProvider.notifier).autoLogin();
    authState = ref.read(authProvider);

    if (authState.status != AuthStatus.authenticated) {
      return '/login';
    }
  }

  if (!authState.isAdmin) {
    return '/';
  }

  return null;
}

GoRouter createAppRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // ─── Pre-auth routes (no bottom nav) ───
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ─── Main app with bottom navigation ───
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Categories
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                name: 'categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),

          // Branch 2: Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),

          // Branch 3: Wishlist
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wishlist',
                name: 'wishlist',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─── Full-screen routes (over bottom nav) ───
      GoRoute(
        path: '/product/:id',
        name: 'product_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success/:orderId',
        name: 'order_success',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderSuccessScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        name: 'order_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/review/:orderId/:productId',
        name: 'write_review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          final productId = state.pathParameters['productId']!;
          return WriteReviewScreen(orderId: orderId, productId: productId);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/addresses',
        name: 'addresses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/categories/:category',
        name: 'subcategory',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          return SubcategoryScreen(category: category);
        },
      ),

      // ─── Admin routes (full-screen, no bottom nav) ───
      GoRoute(
        path: '/admin',
        name: 'admin_dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => _adminRouteRedirect(ref),
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        name: 'admin_products',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => _adminRouteRedirect(ref),
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/products/new',
        name: 'admin_product_new',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => _adminRouteRedirect(ref),
        builder: (context, state) {
          String? initialCategoryId;
          final extra = state.extra;
          if (extra is Map && extra['categoryId'] != null) {
            initialCategoryId = extra['categoryId'].toString();
          }
          return AdminProductEditorScreen(
            productId: null,
            initialCategoryId: initialCategoryId,
          );
        },
      ),
      GoRoute(
        path: '/admin/products/:id',
        name: 'admin_product_edit',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => _adminRouteRedirect(ref),
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          String? initialCategoryId;
          final extra = state.extra;
          if (extra is Map && extra['categoryId'] != null) {
            initialCategoryId = extra['categoryId'].toString();
          }
          return AdminProductEditorScreen(
            productId: id,
            initialCategoryId: initialCategoryId,
          );
        },
      ),
      GoRoute(
        path: '/admin/categories',
        name: 'admin_categories',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => _adminRouteRedirect(ref),
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/categories/new',
        name: 'admin_category_new',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => _adminRouteRedirect(ref),
        builder: (context, state) =>
            const AdminCategoryEditorScreen(categoryId: null),
      ),
      GoRoute(
        path: '/admin/categories/:id',
        name: 'admin_category_edit',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => _adminRouteRedirect(ref),
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminCategoryEditorScreen(categoryId: id);
        },
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return createAppRouter(ref);
});
