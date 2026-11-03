import Foundation

struct FairPriceInfo {
    var low: Int
    var high: Int
    var mid: Int
    var week: Double
    var history: [Int]
}

let FAIR_DB: [String: FairPriceInfo] = [
    "Galunggong": FairPriceInfo(low: 180, high: 205, mid: 192, week: 6.2, history: [176, 182, 188, 185, 192, 190, 192]),
    "Tamban":     FairPriceInfo(low: 150, high: 170, mid: 160, week: -1.1, history: [163, 162, 160, 161, 159, 158, 160]),
    "Tulingan":   FairPriceInfo(low: 198, high: 215, mid: 210, week: 2.8, history: [203, 205, 206, 208, 209, 211, 210]),
    "Bisugo":     FairPriceInfo(low: 190, high: 215, mid: 202, week: 1.0, history: [199, 200, 201, 200, 203, 204, 202]),
    "Bangus":     FairPriceInfo(low: 170, high: 185, mid: 178, week: -1.3, history: [181, 180, 179, 178, 177, 179, 178]),
    "Alumahan":   FairPriceInfo(low: 160, high: 180, mid: 170, week: 0.5, history: [168, 169, 170, 171, 169, 170, 170]),
]

let RECENT_SPECIES = ["Galunggong", "Tamban", "Tulingan", "Bisugo"]
let ALL_SPECIES = Array(FAIR_DB.keys).sorted()

struct OtherListing: Identifiable {
    var id: String
    var species: String
    var weight: Double
    var price: Int
    var seller: String
    var rating: Double
    var site: String
    var distance: String
    var fair: Bool
    var fresh: Bool = false
}

let OTHER_LISTINGS: [OtherListing] = [
    OtherListing(id: "m1", species: "Tulingan", weight: 18, price: 205, seller: "Mang Roberto", rating: 4.8, site: "Batangas City", distance: "2.4 km", fair: true),
    OtherListing(id: "m2", species: "Bangus", weight: 15, price: 178, seller: "Aling Fely", rating: 4.6, site: "Anilao", distance: "3.1 km", fair: true, fresh: true),
    OtherListing(id: "m3", species: "Galunggong", weight: 9, price: 168, seller: "Kuya Dindo", rating: 4.9, site: "Mabini", distance: "4.7 km", fair: false),
]

struct Buyer: Identifiable, Hashable {
    var id: String
    var name: String
    var verified: Bool
    var rating: Double
    var trans: Int
    var offer: Int
    var distance: String
    var fair: Bool
    var type: String
}

let BUYERS: [Buyer] = [
    Buyer(id: "b1", name: "Liza's Seafood Stall", verified: true, rating: 4.8, trans: 127, offer: 198, distance: "1.8 km", fair: true, type: "Retailer"),
    Buyer(id: "b2", name: "Coastal Fresh Trading", verified: true, rating: 4.5, trans: 64, offer: 165, distance: "3.5 km", fair: false, type: "Cooperative"),
]

struct NotificationItem: Identifiable {
    var id: String
    var kind: String
    var text: String
    var time: String
}

let NOTIFS: [NotificationItem] = [
    NotificationItem(id: "n1", kind: "PRICE UPDATE", text: "Galunggong prices increased 6% this week.", time: "1h ago"),
    NotificationItem(id: "n2", kind: "BUYER INTEREST", text: "Liza's Seafood Stall is interested in your Tulingan listing.", time: "3h ago"),
    NotificationItem(id: "n3", kind: "SALE", text: "Your Tamban sale has been recorded.", time: "5h ago"),
    NotificationItem(id: "n4", kind: "SYNC", text: "3 offline catch records were successfully synced.", time: "Yesterday"),
]

let ADVISOR_SUGGESTIONS = [
    "Magkano ang fair price ng Galunggong ngayon?",
    "Aling fishing ground ang madalas kong magandang huli?",
    "Bakit mababa ang presyo ng huling benta ko?",
    "Anong isda ang mataas ang presyo ngayong linggo?",
]
