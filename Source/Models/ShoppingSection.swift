import Foundation

enum ShoppingSection: String, CaseIterable, Codable, Identifiable {
    case produce
    case bakery
    case dairy
    case meatSeafood
    case deli
    case frozen
    case pantry
    case beverages
    case snacks
    case household
    case personalCare
    case pets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .produce: return "Produce"
        case .bakery: return "Bakery"
        case .dairy: return "Dairy"
        case .meatSeafood: return "Meat & Seafood"
        case .deli: return "Deli"
        case .frozen: return "Frozen"
        case .pantry: return "Pantry"
        case .beverages: return "Beverages"
        case .snacks: return "Snacks"
        case .household: return "Household"
        case .personalCare: return "Personal Care"
        case .pets: return "Pets"
        }
    }

    var hebrewTitle: String {
        switch self {
        case .produce: return "ירקות ופירות"
        case .bakery: return "מאפים"
        case .dairy: return "מוצרי חלב"
        case .meatSeafood: return "בשר ודגים"
        case .deli: return "דליקטסן"
        case .frozen: return "קפואים"
        case .pantry: return "מזווה"
        case .beverages: return "משקאות"
        case .snacks: return "חטיפים"
        case .household: return "משק בית"
        case .personalCare: return "טיפוח אישי"
        case .pets: return "חיות מחמד"
        }
    }
}

