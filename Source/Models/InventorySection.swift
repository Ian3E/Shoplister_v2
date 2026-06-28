import Foundation

enum InventorySection: String, CaseIterable, Codable, Identifiable {
    case pantry
    case fridge
    case freezer
    case produceBowl
    case spiceRack
    case bakingDrawer
    case snacks
    case beverages
    case cleaning
    case toiletries
    case pets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pantry: return "Pantry"
        case .fridge: return "Fridge"
        case .freezer: return "Freezer"
        case .produceBowl: return "Produce Bowl"
        case .spiceRack: return "Spice Rack"
        case .bakingDrawer: return "Baking Drawer"
        case .snacks: return "Snacks"
        case .beverages: return "Beverages"
        case .cleaning: return "Cleaning"
        case .toiletries: return "Toiletries"
        case .pets: return "Pets"
        }
    }

    var hebrewTitle: String {
        switch self {
        case .pantry: return "מזווה"
        case .fridge: return "מקרר"
        case .freezer: return "מקפיא"
        case .produceBowl: return "קערת ירקות"
        case .spiceRack: return "מדף תבלינים"
        case .bakingDrawer: return "מגירת אפייה"
        case .snacks: return "חטיפים"
        case .beverages: return "משקאות"
        case .cleaning: return "ניקיון"
        case .toiletries: return "היגיינה אישית"
        case .pets: return "חיות מחמד"
        }
    }
}

