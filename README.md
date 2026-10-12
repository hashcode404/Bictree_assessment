# YumQuick: Food Delivery App (Bictree Flutter task)

A Flutter food delivery app built from the provided Figma kit: log in, browse
food, view details, manage a cart and place an order. Data comes from
[DummyJSON](https://dummyjson.com) (auth and recipes), so no backend is needed.

## Setup and run

- **Flutter version:** `<fill in: output of flutter --version>`
- **flutter_riverpod:** 2.6.x

```bash
flutter pub get
flutter run                      # Android required, iOS optional
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
```

Test user: `emilys` / `emilyspass`.

## Tests

```bash
flutter test
```

| File | What it covers |
|---|---|
| `test/features/cart/cart_controller_test.dart` | Cart logic: add and merge, quantity limits, remove and undo, totals, persistence across a restart |
| `test/features/food/recipe_repository_test.dart` | Repository: parsing, mock price, offline fallback to the cached first page, typed failures (401, 5xx, malformed body), search, detail, filtering and sorting |
| `test/features/auth/login_screen_test.dart` | Widget test: login form validation and submit |
| `test/features/cart/cart_screen_test.dart` | Widget test: cart screen empty state, totals, quantity change, undo |

Tests use fakes and a stubbed HTTP adapter, so they need no network.

## Architecture

Layered per feature (`data` / `domain` / `presentation`) with the repository
pattern. The UI only talks to Riverpod providers; providers talk to
repository interfaces; repositories are the only code that touches Dio or
Hive.

```
lib/
  core/
    error/      Failure types (typed, no raw exceptions reach the UI)
    network/    Dio client + auth interceptor
    storage/    Secure storage for the logged-in user and tokens
    router/     go_router config, auth redirect, bottom-bar shell
    theme/      Colors, Material 3 theme, status bar styles
    widgets/    Shared UI (error/empty views, offline banner, yellow page...)
  features/
    auth/       login, auto-login, logout; welcome, onboarding, signup UI
    food/       recipes list, menu, search and filter, detail
    cart/       cart, confirm order
```

Key flows:

- **Login:** `AuthController` holds the session status, the user, loading and
  error. The user and both tokens are stored as one JSON entry in
  `flutter_secure_storage`. On start the saved user is read (auto-login) while
  the splash shows.
- **401 handling:** the Dio auth interceptor adds the bearer token and, on any
  401 from a protected request, calls `logout()`. The router redirect then
  sends the user to Log In from wherever they are.
- **Route guard:** `go_router` redirects on the auth status only (not on
  loading/error), so the login form is never rebuilt by navigation.
- **Food list:** `RecipesController` (an `AsyncNotifier`) loads pages of 20
  with `limit`/`skip`, supports pull-to-refresh and a retry for a failed
  "load more". Home, Menu and Search share it.
- **Offline:** the first page is saved to Hive on every successful load. If
  the first-page request fails because of the network, the saved page is
  returned and an offline banner is shown with a Retry button.
- **Cart:** `CartController` is a `Notifier` that saves to Hive after every
  change, so the cart survives restarts. Swipe to delete (or decrement the
  last unit) shows an Undo snackbar.
- **Order:** Confirm Order shows the summary; Place Order is local only (no API
  call): it shows a confirmation, clears the cart and returns Home.

## Why Riverpod

The app is mostly async data (login, paginated lists, detail) plus a small
amount of local state (cart, filters). Riverpod's `AsyncNotifier` models
loading, error and data directly, providers can be overridden with fakes in
tests without extra wiring, and there is less boilerplate than Bloc's
event/state classes for a two-day build. No code generation is used, so there
is no `build_runner` step.

## Mock prices

The recipes API has no price, so a stable price is derived from the item id:

```dart
double mockPriceFor(int id) => (800 + (id * 379) % 1200) / 100;
```

This gives a value from 8.00 to 19.99 that never changes for the same id. The
price slider range (8 to 20) matches it. Cart tax is a fixed 8%, the service
fee is 1.50 and delivery is 2.99 (none of these apply to an empty cart).

## Category mapping

The mapping lives in one place, `features/food/domain/food_category.dart`:

| Design category | API rule |
|---|---|
| Snacks | `mealType` is Snack, Appetizer or Side Dish |
| Meal | `mealType` is Breakfast, Lunch or Dinner |
| Vegan | `tags` contains Vegan or Vegetarian. **The API has no "Vegan" tag**, so Vegetarian is used; this is a known approximation. |
| Dessert | `mealType` is Dessert |
| Drinks | `mealType` is Beverage or Drink, or `tags` contains Smoothie, Lassi, Cocktail, Mojito or Caipirinha |

Category, sort and price filtering run on the client over the loaded items,
because the API has no price field and cannot combine these filters. The Menu
keeps loading pages while a filter shows only a few items, so a rare category
still fills the screen.

## Decisions and trade-offs

- **Search** calls `/recipes/search` (debounced 400 ms). Category, sort and
  price are then applied to those results on the client.
- **Hero tags are unique per screen** (`home-`, `menu-`, `search-`), because
  Home and Menu live in the same tab shell and duplicate tags would break the
  transition.
- **Tabs:** Home, Menu and Cart share one bottom bar and keep their own state.
- **Token on the `User` entity:** the user and both tokens are stored as one
  secure-storage entry for simplicity. A stricter design would use a separate
  `Session` object.
- **Core imports the auth feature:** `dio_client.dart` reads the auth
  controller so a 401 can log the user out. The reference is only used when a
  request fails.
- **Failures** are typed (`NetworkFailure`, `UnauthorizedFailure`,
  `ServerFailure`, `CacheFailure`, `UnknownFailure`). Repositories catch every
  exception and throw one of these.

## Skipped or simplified

- Out of scope per the brief: profile, orders, tracking, payments, help,
  favorites, notifications.
- Sign Up, Set Password and Set Fingerprint screens exist as UI only; they do
  not create accounts (DummyJSON cannot create a real user). Forget Password
  and the social buttons show a "Not available" message.
- Refresh tokens are stored but not used: on a 401 the user is logged out.
- The Best Seller row is "top rated among the loaded items" (there is no
  sales data). The 30% OFF banner is static.
- Category icons use Material icons instead of the Figma icon set.
- The offline cache holds the first page only. Detail is not cached.
- Menu, Search, Cart, Confirm Order and Food Detail layouts are my own in the
  style of the Figma file; they were designed without the original frames.

## What I would improve with more time

- Use the refresh token to renew the session instead of logging out.
- Cache more than the first page and the detail responses.
- Use real connectivity detection (for example `connectivity_plus`) to show
  the offline banner immediately.
- Add integration tests for the full login-to-order flow and golden tests for
  the main screens.
- Export the Figma icons as SVG and match spacing pixel by pixel.
- Add localization and dark theme.

