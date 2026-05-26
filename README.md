<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter 3">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/github/v/release/test-pharm/pharmacy-wms-flutter?logo=github" alt="Latest Release">
</p>

# Pharmacy WMS — Desktop App

A cross-platform desktop application for Pharmacy Warehouse Management built with Flutter. Communicates with the [backend API](https://github.com/test-pharm/pharmacy-wms-backend) deployed on Render.

---

## Screens

| Screen | Description |
|--------|-------------|
| **Dashboard** | KPIs, category distribution pie chart, recent materials, critical alerts |
| **Inventory** | Full product list with search, filters, sort, batch details |
| **Stocktake** | Physical count reconciliation with discrepancy detection |
| **Orders** | Create, view & filter orders (Material/Dispatch/Refund) |
| **Invoices** | Grouped order view by invoice number |
| **Reports** | Category breakdown, status distribution, expiry timeline, export to PDF/Excel |
| **Audit Log** | Full action history with user & timestamp |
| **Approvals** | Supervisor workflow for expiry change requests |
| **Settings** | Low-stock threshold, expiring-soon days, language toggle |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart ^3.10.0) |
| Charts | `fl_chart` (pie, bar, line) |
| HTTP | `http` package |
| PDF | `pdf` + `printing` |
| Archiving | `archive` (zip extraction for auto-updates) |
| Localization | Custom `AppLocalizations` with Arabic/English |
| State Management | `ChangeNotifier` + `InheritedWidget` |
| Auto-Update | GitHub Releases + in-app download & restart |

---

## Features

### Inventory Management
- Full CRUD for materials with SKU, category, quantity, expiry dates
- Stock batch tracking (per-batch expiry & quantity)
- Low-stock & expiring-soon visual alerts

### Order Processing
- Material orders (add to stock)
- Dispatch orders (remove from stock)
- Refund orders
- Invoice number grouping
- Order status tracking (Pending → Completed / Canceled)

### Analytics & Reporting
- **Category Breakdown** — Pie chart by item category
- **Status Distribution** — Bar chart (Good / Expiring Soon / Expired / Low Stock)
- **Expiry Timeline** — 12-month bar chart projection
- **KPI Cards** — Total materials, expiring soon, low stock, critical alerts
- **Export** — PDF reports & Excel spreadsheets

### Stock Control
- Batch-level expiry date management
- Supervisor approval workflow for expiry changes
- Physical stocktake with discrepancy detection

### User Experience
- **Bilingual** — Full Arabic / English support
- **Dark & Light themes** — Auto-follows system theme
- **Auto-update** — Checks GitHub Releases, downloads & installs in-app
- **Dashboard alerts** — Real-time critical alerts & supervisor notifications

---

## Installation

### Download
Get the latest Windows installer from [GitHub Releases](https://github.com/test-pharm/pharmacy-wms-flutter/releases/latest).

### Build from source
```bash
git clone https://github.com/test-pharm/pharmacy-wms-flutter.git
cd pharmacy-wms-flutter
flutter pub get
flutter config --enable-windows-desktop
flutter build windows --release
```

The built executable is at `build\windows\x64\runner\Release\pharmacy_wms.exe`.

---

## Architecture

```
lib/
├── main.dart                    # App entry point
├── Models/                      # Data models & providers
│   ├── materialModel.dart
│   ├── orderModel.dart
│   ├── ProductProvider.dart     # State management
│   ├── app_localizations.dart   # i18n strings
│   └── app_version.dart
├── Services/                    # API calls & business logic
│   ├── api_config.dart          # Backend URL config
│   ├── ProductService.dart
│   ├── orderService.dart
│   ├── update_service.dart      # Auto-update logic
│   ├── download_service.dart    # Zip download & install
│   └── ...
├── views/                       # UI screens
│   ├── DashboardView.dart
│   ├── InventoryView.dart
│   ├── OrdersView.dart
│   ├── ReportsPage.dart
│   └── ...
└── widgets/                     # Reusable components
    ├── UpdateDialog.dart         # Update notification dialog
    └── ...
```

---

## Auto-Update Mechanism

1. On startup, the app fetches `version.json` from GitHub raw
2. Compares remote version with bundled version in assets
3. If newer → shows "Update Available" dialog with release notes
4. User clicks "Update Now" → downloads zip from GitHub Releases
5. Extracts & replaces executable files in-place
6. Launches new version & exits old process

---

## Configuration

Edit `lib/Services/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://pharmacy-wms-backend.onrender.com/api';
}
```

---

## Related

- [Backend Repository](https://github.com/test-pharm/pharmacy-wms-backend) — ASP.NET Core 8.0 API
- [Render Dashboard](https://dashboard.render.com) — Backend hosting
- [Prometheus Metrics](https://pharmacy-wms-backend.onrender.com/metrics) — Live metrics
