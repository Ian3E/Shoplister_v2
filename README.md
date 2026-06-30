# Shoplister v2 (UX experiment branch)

**Shoplister v2** is a copy of [Shoplister v1](../Shoplister_v1) for trying significant UX changes without affecting the main project.

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
