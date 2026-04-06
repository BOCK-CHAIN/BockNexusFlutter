# 🛒 BockNexus Flutter E-Commerce App

> **Agent Reference Document** — Read this before making any changes to this project.

---

## 📋 Project Overview

| Property | Value |
|---|---|
| **Platform** | Flutter (Mobile — Android & iOS) |
| **Focus** | Frontend only (UI + State) |
| **State Management** | Riverpod (StateNotifier) |
| **Navigation** | GoRouter (named routes + deep linking) |
| **Design** | Material 3, Google Fonts, Light + Dark mode |
| **Backend** | BockNexusServer (Node.js + Express 5 + Prisma + PostgreSQL) |
| **Auth** | JWT Bearer Token (stored in SharedPreferences) |
| **Payments** | Razorpay (flutter_razorpay plugin) |
| **Build Status** | ✅ All 3 stages complete + backend integrated |

---

## 📁 Folder Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + GoRouter setup
├── core/
│   ├── theme/
│   │   ├── app_theme.dart            # lightTheme + darkTheme
│   │   ├── app_colors.dart           # color constants
│   │   └── app_text_styles.dart      # typography scale
│   ├── router/
│   │   └── app_router.dart           # all named GoRouter routes
│   ├── network/
│   │   ├── api_client.dart           # Dio HTTP client wrapper
│   │   ├── token_manager.dart        # JWT token read/write/clear
│   │   └── exceptions.dart           # custom exception classes
│   ├── utils/
│   │   └── id_generator.dart         # generateHexId (SHA-512 utility)
│   └── widgets/
│       ├── app_button.dart           # filled / outlined / text variants
│       ├── app_text_field.dart       # with validation + obscure toggle
│       ├── shimmer_loader.dart       # shimmer skeleton + ShimmerProductCard
│       ├── product_card.dart         # used in grids + horizontals
│       ├── rating_stars.dart
│       └── price_tag.dart
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── product_size_model.dart
│   ├── cart_item_model.dart
│   ├── order_model.dart
│   ├── address_model.dart
│   ├── category_model.dart
│   ├── wishlist_item_model.dart
│   ├── transaction_model.dart
│   └── review_model.dart
└── features/
    ├── splash/
    ├── onboarding/
    ├── auth/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── forgot_password_screen.dart
    │   └── auth_notifier.dart
    ├── home/
    ├── search/
    ├── product/
    ├── cart/
    ├── wishlist/
    ├── checkout/
    ├── orders/
    ├── profile/
    ├── categories/
    └── notifications/
```

---

## 🎨 Design System

### Colors (`app_colors.dart`)

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#3D2C8D` | Deep Indigo — buttons, active states |
| `accent` | `#FF6B6B` | Coral — badges, sale tags, CTAs |
| `surface` | `#F8F8FF` | Card backgrounds |
| `success` | `#4CAF50` | Order delivered, in stock |
| `warning` | `#FF9800` | Low stock, expiring deals |
| `error` | `#E53935` | Errors, out of stock |
| `darkBg` | `#121212` | Dark mode background |
| `darkSurface` | `#1E1E1E` | Dark mode card surface |

### Typography (`app_text_styles.dart`)

| Style | Font | Usage |
|---|---|---|
| `displayLarge` | Playfair Display | Hero headings |
| `headlineMedium` | Playfair Display | Screen titles |
| `titleLarge` | Playfair Display | Section headers |
| `bodyLarge` | Lato | Product descriptions |
| `bodyMedium` | Lato | General body text |
| `labelLarge` | Lato | Button labels |
| `caption` | Lato | Timestamps, metadata |

### Reusable Widgets

| Widget | Props |
|---|---|
| `AppButton` | `variant` (filled/outlined/text), `isLoading`, `onPressed` |
| `AppTextField` | `label`, `hint`, `prefixIcon`, `suffixIcon`, `obscureText`, `validator` |
| `ShimmerLoader` | `width`, `height`, `borderRadius` |
| `ProductCard` | `product`, `onTap`, `onWishlistTap`, `showBadge` |
| `RatingStars` | `rating`, `count`, `size` |
| `PriceTag` | `price`, `originalPrice`, `discountPercent` |

---

## 🔐 Authentication

### generateHexId (`lib/core/utils/id_generator.dart`)

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateHexId(
  String email, String password,
  String firstName, String lastName,
  String dob, String gender,
) {
  final input = email + password + firstName + lastName + dob + gender;
  final bytes = utf8.encode(input);
  final digest = sha512.convert(bytes);
  return digest.toString().substring(0, 16);
}
```

> ⚠️ **Legacy use only.** This was used as a mock local user ID before backend integration.
> After full backend integration, the real `id` comes from the server response.
> This function is kept for reference — do NOT remove it.

### JWT Flow

```
Register → POST /user/register → receive token → save via TokenManager
Login    → POST /user/login    → receive token → save via TokenManager
App Start → getToken() exists → GET /user/profile → populate authProvider
401 Anywhere → clearToken() → redirect to Login + show session expired snackbar
```

### TokenManager (`lib/core/network/token_manager.dart`)

| Method | Description |
|---|---|
| `saveToken(String token)` | Save JWT to SharedPreferences |
| `getToken()` | Returns `String?` from SharedPreferences |
| `clearToken()` | Remove token (logout) |
| `isLoggedIn()` | Returns `bool` |

---

## 🌐 Backend API Reference

**Base URL:** `http://localhost:3000` *(replace with production URL on deploy)*

**Auth Header:** `Authorization: Bearer <token>`

### User Endpoints

| Method | Endpoint | Auth | Used In |
|---|---|---|---|
| POST | `/user/register` | ❌ | Register screen |
| POST | `/user/login` | ❌ | Login screen |
| GET | `/user/profile` | ✅ | App start auto-login |
| PUT | `/user/profile` | ✅ | Edit profile screen |
| PUT | `/user/change-password` | ✅ | Profile menu |
| DELETE | `/user/delete` | ✅ | Profile menu |

### Product Endpoints (all public)

| Method | Endpoint | Used In |
|---|---|---|
| GET | `/product` | All products listing |
| GET | `/product/random-products` | Home screen |
| GET | `/product/:productId` | Product detail |
| GET | `/product/category/:categoryId` | Category screen |
| GET | `/product/search?q=` | Search screen |
| GET | `/product/filter` | Filter bottom sheet |
| GET | `/product/brands?categoryId=` | Filter options |
| GET | `/product/colours?categoryId=` | Filter options |
| GET | `/product/sizes?categoryId=` | Filter options |

### Cart Endpoints (all JWT protected)

| Method | Endpoint | Body |
|---|---|---|
| GET | `/cart` | — |
| POST | `/cart/add` | `{ productId, productSizeId?, quantity }` |
| PUT | `/cart/:cartItemId` | `{ quantity }` |
| DELETE | `/cart/:cartItemId` | — |
| DELETE | `/cart/clear` | — |

### Wishlist Endpoints (all JWT protected)

| Method | Endpoint | Body |
|---|---|---|
| GET | `/wishlist` | — |
| POST | `/wishlist/add` | `{ productId, productSizeId?, quantity }` |
| PUT | `/wishlist/:wishlistItemId` | `{ quantity }` |
| DELETE | `/wishlist/:wishlistItemId` | — |
| DELETE | `/wishlist/clear` | — |

### Address Endpoints (all JWT protected)

| Method | Endpoint | Body |
|---|---|---|
| GET | `/address/:userId` | — |
| POST | `/address` | `{ nickname, line1, line2?, city, state, zip, country, receiverName, isDefault, type }` |
| PUT | `/address/:id` | same fields, all optional |

### Orders & Checkout

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/orders/transaction` | ❌ | Create Razorpay order |
| POST | `/orders/create` | ❌ | Create order after payment |
| GET | `/orders/my-orders` | ✅ | Get current user orders |

### Reviews

| Method | Endpoint | Body |
|---|---|---|
| POST | `/review` | `{ productId, userId, rating, title, body }` |

---

## 💳 Razorpay Payment Flow

```
1. User taps Place Order
2. POST /orders/transaction  →  { amount (paise), currency: "INR" }
3. Receive { orderId, amount, currency } from server
4. Open Razorpay checkout with flutter_razorpay plugin
5. On SUCCESS callback:
   POST /orders/create  →  { userId, addressId, paymentId, orderRefId, items[], amount }
6. Navigate to Order Success screen
7. On FAILURE → show Payment Failed dialog with Retry button
```

---

## 📱 Screens Reference

| Screen | Route Name | Auth Required |
|---|---|---|
| Splash | `/` | ❌ |
| Onboarding | `/onboarding` | ❌ |
| Login | `/login` | ❌ |
| Register | `/register` | ❌ |
| Forgot Password | `/forgot-password` | ❌ |
| Home | `/home` | ❌ |
| Search | `/search` | ❌ |
| Product Detail | `/product/:id` | ❌ |
| Categories | `/categories` | ❌ |
| Cart | `/cart` | ✅ |
| Wishlist | `/wishlist` | ✅ |
| Checkout | `/checkout` | ✅ |
| Order Success | `/order-success` | ✅ |
| My Orders | `/orders` | ✅ |
| Order Detail | `/orders/:id` | ✅ |
| Profile | `/profile` | ✅ |
| Notifications | `/notifications` | ✅ |
| Write Review | `/review/:productId` | ✅ |

---

## 🗂️ Riverpod Providers

| Provider | Type | State |
|---|---|---|
| `authProvider` | `StateNotifier<AuthState>` | user, token, isLoading, error, isLoggedIn |
| `categoryProvider` | `FutureProvider` | `List<CategoryModel>` — cached |
| `productProvider` | `StateNotifier<ProductState>` | allProducts, randomProducts, currentProduct |
| `filterProvider` | `StateNotifier<FilterState>` | filters, filteredProducts, dynamicOptions |
| `cartProvider` | `StateNotifier<CartState>` | items, itemCount (badge), totalPrice |
| `wishlistProvider` | `StateNotifier<WishlistState>` | items, isWishlisted(productId) |
| `addressProvider` | `StateNotifier<AddressState>` | addresses, selectedAddress |
| `orderProvider` | `StateNotifier<OrderState>` | orders, currentOrder |

---

## 📦 Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter_riverpod: latest
  go_router: latest
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  google_fonts: latest
  shimmer: latest
  cached_network_image: latest
  flutter_rating_bar: latest
  smooth_page_indicator: latest
  flutter_animate: latest
  badges: latest
  lottie: latest
  intl: latest
  image_picker: latest
  crypto: ^3.0.3
  flutter_razorpay: ^1.3.6
```

---

## ⚠️ Global Edge Cases (Implemented Everywhere)

| Case | Handling |
|---|---|
| No internet | Top banner + cached content |
| Loading state | Shimmer skeletons (never full-screen spinners) |
| Empty state | Unique illustration + CTA per screen |
| Error state | Retry button + friendly message |
| 401 Unauthorized | Auto logout + session expired snackbar |
| 400 Validation | Inline field errors with shake animation |
| 500 Server error | "Something went wrong" + retry |
| Double-tap | Button disabled until action completes |
| Keyboard overlap | `resizeToAvoidBottomInset` + scrollable forms |
| Long text | Ellipsis, no pixel overflow |
| Out of stock | Disable Add to Cart, show Notify Me |
| Back from checkout | Confirm dialog: "Leave checkout?" |
| Font scaling | No hardcoded pixel heights for text containers |
| Safe area | `SafeArea` widget on all screens |

---

## 🗄️ Backend Data Models (Prisma)

### Key Enums

```
OrderStatus:       ORDER_PLACED | SHIPPING | OUT_FOR_DELIVERY | DELIVERED | CANCELLED
TransactionStatus: Success | Failed | Pending
TypeOfAddress:     Home | Office | Other
SizeType:          NONE | GENERIC | SHOES_UK_MEN | SHOES_UK_WOMEN | NUMERIC |
                   VOLUME_ML | WEIGHT_G | ONE_SIZE | WAIST_INCH
```

### SizeType Display Logic

```dart
switch (product.sizeType) {
  case 'NONE':      // hide size selector entirely
  case 'ONE_SIZE':  // show "One Size" label, no chips
  default:          // show size chips from sizes list
                    // stock == 0 → grey out that chip
}
```

---

## 🔧 Environment / Config

| Variable | Where | Value |
|---|---|---|
| `BASE_URL` | `api_client.dart` | `http://localhost:3000` |
| `RAZORPAY_KEY_ID` | `checkout` screen | from `.env` or constants file |
| `JWT_SECRET` | Backend only | never in Flutter app |

---

## 🚫 Agent Rules — DO NOT

- ❌ Do NOT rebuild or regenerate existing UI screens
- ❌ Do NOT change existing navigation or GoRouter routes
- ❌ Do NOT add a backend — this is frontend only
- ❌ Do NOT remove `id_generator.dart` (kept for legacy reference)
- ❌ Do NOT use `http` package — use `Dio` only
- ❌ Do NOT store token anywhere except `SharedPreferences`
- ❌ Do NOT hardcode any user ID — always use server response
- ❌ Do NOT use full-screen `CircularProgressIndicator` — use shimmer
- ❌ Do NOT use `localStorage` or browser APIs
- ❌ Do NOT change `pubspec.yaml` package versions without confirming

---

## ✅ Agent Rules — ALWAYS DO

- ✅ Read this README before making any changes
- ✅ Only touch files directly relevant to the requested change
- ✅ Preserve all existing animations, themes, and design tokens
- ✅ Wire all loading/error states to provider state (not local setState)
- ✅ Use `TokenManager` for all token operations
- ✅ Use `ApiClient` for all HTTP calls
- ✅ Add `Authorization: Bearer <token>` for all protected routes
- ✅ Handle 401 globally → clearToken + redirect to Login
- ✅ Keep shimmer skeletons during real API loading
- ✅ Maintain existing edge case handling on all screens

---

## 🔄 Completed Build Stages

| Stage | Status | Contents |
|---|---|---|
| Stage 1 | ✅ Done | Setup, Design System, Auth, Home, Search, Filter |
| Stage 2 | ✅ Done | Product Detail, Wishlist, Cart, Checkout, Order Success |
| Stage 3 | ✅ Done | Profile, Orders, Reviews, Notifications, Categories |
| Integration | ✅ Done | BockNexusServer API replacing all mock data |
| generateHexId | ✅ Done | Added to `lib/core/utils/id_generator.dart` |
