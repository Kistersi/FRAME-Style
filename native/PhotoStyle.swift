import Foundation

enum PhotoStyle: String, CaseIterable, Identifiable {
    case urbanBW = "Urban B/W"
    case darkCinematic = "Dark Cinematic"
    case warmVintage = "Warm Vintage"
    case coldBlue = "Cold Blue"
    case naturalPro = "Natural Pro"
    case softMono = "Soft Mono"
    case custom = "Eigener Stil"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .urbanBW: "Urban · Kontrastreich"
        case .darkCinematic: "Dunkel · Warm · Dramatisch"
        case .warmVintage: "Analog · Golden · Weich"
        case .coldBlue: "Kühl · Klar · Modern"
        case .naturalPro: "Natürlich · Ausgewogen"
        case .softMono: "Monochrom · Sanft"
        case .custom: "Dezent · Originalnah"
        }
    }
}
