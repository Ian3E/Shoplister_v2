# Shoplister v2

**Shoplister v2** is the production iOS app in this repository — a grocery list and item library with English/Hebrew support, saved lists, and on-device backup. It evolved from [Shoplister v1](../Shoplister_v1) as a separate App Store listing with a new bundle ID.

The Xcode project is **`Shoplister_v2.xcodeproj`**; the main app target is **Shoplister_v2**. The on-device name is **Shoplister**.

| | v1 | v2 (this folder) |
|---|---|---|
| Project | `GroceryList.xcodeproj` | `Shoplister_v2.xcodeproj` |
| Bundle ID | `com.ianengelman.grocerylist` | `com.ianengelman.grocerylist.v2` |
| Share extension | `…grocerylist.ShareExtension` | `…grocerylist.v2.ShareExtension` |
| App Group | `group.com.ianengelman.grocerylist` | `group.com.ianengelman.grocerylist.v2` |

v1 and v2 can be installed side by side on the same device. They use **separate** App Group containers (register `group.com.ianengelman.grocerylist.v2` in your Apple Developer account if signing fails).

## Open & run

1. Open **`Shoplister_v2.xcodeproj`** in Xcode.
2. Select the **Shoplister_v2** scheme (main app).
3. Build and run on a simulator or device.

The app entry point is `GroceryListApp` (`Source/GroceryListApp.swift`). Resources such as `seed-library-backup-en.txt` / `seed-library-backup-he.txt` must be included in the app target for first-launch seeding.

## Layout

| Path | Role |
|------|------|
| `Source/` | Main app Swift code |
| `GroceryList/` | Info.plist, entitlements, assets, launch screen |
| `ShareExtension/` | Share extension |
| `Shoplister_v2.xcodeproj` | Xcode project |

## Features (same as v1)

| Area | Notes |
|------|--------|
| **Home** | Catalog grouped by home location; toolbar search; add to shopping list |
| **Store** | Shopping list by store sections; check off items; clear checked / clear all |
| **Share extension** | Plain text shared into Shoplister is matched to the catalog; pending ops merge when the main app opens |
| **Settings** | Text size, appearance, language, backup/restore, etc. |

## Privacy policy (GitHub Pages)

The privacy policy lives at [`docs/privacy.html`](docs/privacy.html). The app links to:

**https://ian3e.github.io/Shoplister_v2/privacy.html**

To publish after pushing to GitHub:

1. Open the repo on GitHub → **Settings** → **Pages**
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**
3. Choose branch **main** and folder **/docs**
4. Save; GitHub will serve the site at `https://ian3e.github.io/Shoplister_v2/`

Use the same URL in **App Store Connect** → App Privacy → Privacy Policy URL.

## App Store submission checklist

Complete these steps in [Apple Developer](https://developer.apple.com) and [App Store Connect](https://appstoreconnect.apple.com) after archiving from Xcode.

### Developer Portal (signing)

- App IDs: `com.ianengelman.grocerylist.v2` and `com.ianengelman.grocerylist.v2.ShareExtension`
- App Group `group.com.ianengelman.grocerylist.v2` enabled on **both** App IDs
- Provisioning profiles regenerate cleanly; **Product → Archive** succeeds for Release / Any iOS Device

### App Store Connect (new listing)

Create a **new app** for bundle ID `com.ianengelman.grocerylist.v2` (not an update to v1).

| Field | Value |
|-------|--------|
| Privacy Policy URL | `https://ian3e.github.io/Shoplister_v2/privacy.html` |
| Support | `support.shoplister@gmail.com` |

**App Privacy questionnaire (summary):**

- Grocery/library data: **not collected** (on device only)
- Photos: used for app functionality, not linked to identity, not for tracking
- No third-party SDK data collection

**Before submit:**

1. Age rating questionnaire (likely 4+)
2. iPhone portrait screenshots
3. Description, subtitle, keywords
4. Archive → Upload → TestFlight → Submit for Review
5. Export compliance: with `ITSAppUsesNonExemptEncryption` = false in Info.plist, answer **No** to custom encryption
