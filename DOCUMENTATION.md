# TeaVerse Project Documentation

## 1. Project Overview
**TeaVerse** is a Flutter-based mobile application designed for tea e-commerce. It features a dual-role system accommodating both Administrators and VIP Customers, powered by a Supabase backend.

## 2. Tech Stack
-   **Frontend Framework**: [Flutter](https://flutter.dev/) (SDK ^3.9.0)
-   **Language**: Dart
-   **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) (^2.6.1)
-   **Backend & Authentication**: [Supabase](https://supabase.com/) (supabase_flutter ^2.12.0)
-   **Database**: PostgreSQL (managed by Supabase)
-   **Key Libraries**:
    -   `printing` & `pdf`: for generating invoices/documents.
    -   `google_fonts`: for typography.
    -   `cached_network_image`: for efficient image loading.
    -   `flutter_svg`: for SVG asset rendering.
    -   `carousel_slider`: for UI carousels.

## 3. Project Structure
The project follows a feature-based folder structure within the `lib` directory:

### Core Directories
-   **`lib/main.dart`**: Application entry point. Handles initialization (Supabase, Riverpod) and uses `AuthGate` to route users based on authentication state and role.
-   **`lib/auth/`**: Authentication logic.
    -   `auth_service.dart`: Supabase auth interactions.
    -   `auth_controller.dart`: Riverpod controller for auth state.
    -   `login_page.dart`: Login UI.
-   **`lib/core/`**: Core utilities, Supabase config, and App Theme.

### Feature Modules

#### A. Admin Module (`lib/admin/`)
Designed for store administrators to manage the business.
-   **Dashboard** (`admin_dashboard_tab.dart`): Overview of business metrics.
-   **Product Management**:
    -   `admin_products_tab.dart`: List products.
    -   `add_product_page.dart` / `edit_product_page.dart`: Create and update tea products.
-   **Order Management**:
    -   `admin_orders_tab.dart`: View and manage customer orders.
    -   `order_detail_page.dart`: Detailed view of specific orders.
-   **Communication**:
    -   `admin_announcements_tab.dart`: Broadcast announcements.
    -   `admin_chat_tab.dart`: Chat with customers.

#### B. VIP / Customer Module (`lib/vip/`)
The main interface for customers.
-   **Navigation** (`vip_bottom_nav.dart`): Bottom navigation bar for easy access to validation logic.
-   **Home**: Landing page (`home_page.dart`).
-   **Shopping**:
    -   `product_page.dart`: Product details.
    -   `cart_page.dart`: Shopping cart and checkout.
-   **Profile & Wallet**:
    -   `lib/wallet/wallet_page.dart`: Manage user funds/credits.
    -   `lib/profile/`: User profile management.

### Services (`lib/services/`)
-   **`invoice_service.dart`**: Logic for generating PDF invoices for orders.

## 4. Database & Setup
-   **SQL Migrations**: root directory contains SQL files (`tea_products_seed.sql`, `setup_variants.sql`, etc.) for setting up the Supabase database schema.
-   **Environment**: `.env` file (asset) is used for configuration.

## 5. Getting Started
1.  **Prerequisites**: Flutter SDK installed.
2.  **Setup**:
    -   Clone the repository.
    -   Run `flutter pub get` to install dependencies.
    -   Ensure Supabase project is set up and `SupabaseConfig` in `lib/core/` is pointing to the correct URL/Key (or `.env` is configured).
3.  **Run**:
    -   `flutter run`
