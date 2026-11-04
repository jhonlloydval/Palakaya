import Foundation

/// Today's weather and sea conditions for the fisher's town, from Open-Meteo (free, no API key).
struct SeaConditions {
    enum Verdict { case good, careful, stayAshore }

    var place: String
    var temperature: Double
    var weatherCode: Int
    var windNow: Double
    var gustNow: Double
    var windMax: Double
    var rainChance: Int
    var waveNow: Double?
    var waveMax: Double?
    var sunrise: Date?
    var sunset: Date?

    /// A rough guide for small municipal boats (bancas). PAGASA gale warnings always come first.
    var verdict: Verdict {
        let wave = waveMax ?? 0
        if wave >= 2.0 || windMax >= 39 || gustNow >= 60 { return .stayAshore }
        if wave >= 1.25 || windMax >= 29 || gustNow >= 45 || rainChance >= 80 { return .careful }
        return .good
    }

    var sky: (label: String, symbol: String) {
        switch weatherCode {
        case 0: return ("Clear", "sun.max.fill")
        case 1, 2: return ("Partly cloudy", "cloud.sun.fill")
        case 3: return ("Cloudy", "cloud.fill")
        case 45, 48: return ("Fog", "cloud.fog.fill")
        case 51...57: return ("Drizzle", "cloud.drizzle.fill")
        case 61...67, 80...82: return ("Rain", "cloud.rain.fill")
        case 95...99: return ("Thunderstorm", "cloud.bolt.rain.fill")
        default: return ("Mixed", "cloud.sun.fill")
        }
    }
}

enum WeatherService {
    private struct GeoResponse: Decodable {
        struct Place: Decodable { let name: String; let latitude: Double; let longitude: Double; let admin2: String? }
        let results: [Place]?
    }
    private struct Forecast: Decodable {
        struct Current: Decodable { let temperature_2m: Double; let wind_speed_10m: Double; let wind_gusts_10m: Double; let weather_code: Int }
        struct Daily: Decodable {
            let precipitation_probability_max: [Int?]
            let wind_speed_10m_max: [Double?]
            let sunrise: [String]
            let sunset: [String]
        }
        let current: Current
        let daily: Daily
    }
    private struct Marine: Decodable {
        struct Current: Decodable { let wave_height: Double? }
        struct Daily: Decodable { let wave_height_max: [Double?] }
        let current: Current?
        let daily: Daily?
    }

    enum WeatherError: Error { case placeNotFound }

    /// Looks up the town (preferring one in the fisher's province), then fetches the forecast and sea state.
    static func today(municipality: String, province: String) async throws -> SeaConditions {
        let town = municipality.isEmpty ? provinceName(province) : municipality
        let (lat, lon, name) = try await locate(town: town, province: provinceName(province))
        let common = "latitude=\(lat)&longitude=\(lon)&timezone=Asia%2FManila&forecast_days=1"
        async let forecastData = get("https://api.open-meteo.com/v1/forecast?\(common)&current=temperature_2m,wind_speed_10m,wind_gusts_10m,weather_code&daily=precipitation_probability_max,wind_speed_10m_max,sunrise,sunset")
        // Marine data is missing for inland points; the card then shows weather only.
        async let marineData = try? get("https://marine-api.open-meteo.com/v1/marine?\(common)&current=wave_height&daily=wave_height_max")

        let forecast = try JSONDecoder().decode(Forecast.self, from: try await forecastData)
        let marine = await marineData.flatMap { try? JSONDecoder().decode(Marine.self, from: $0) }

        let time = DateFormatter()
        time.dateFormat = "yyyy-MM-dd'T'HH:mm"
        time.timeZone = TimeZone(identifier: "Asia/Manila")
        return SeaConditions(
            place: name,
            temperature: forecast.current.temperature_2m,
            weatherCode: forecast.current.weather_code,
            windNow: forecast.current.wind_speed_10m,
            gustNow: forecast.current.wind_gusts_10m,
            windMax: forecast.daily.wind_speed_10m_max.first.flatMap { $0 } ?? forecast.current.wind_speed_10m,
            rainChance: forecast.daily.precipitation_probability_max.first.flatMap { $0 } ?? 0,
            waveNow: marine?.current?.wave_height,
            waveMax: marine?.daily?.wave_height_max.first.flatMap { $0 },
            sunrise: forecast.daily.sunrise.first.flatMap(time.date(from:)),
            sunset: forecast.daily.sunset.first.flatMap(time.date(from:)))
    }

    private static func locate(town: String, province: String) async throws -> (Double, Double, String) {
        let cacheKey = "geo:\(town)|\(province)"
        if let cached = UserDefaults.standard.array(forKey: cacheKey) as? [Any], cached.count == 3,
           let lat = cached[0] as? Double, let lon = cached[1] as? Double, let name = cached[2] as? String {
            return (lat, lon, name)
        }
        guard let query = town.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), !town.isEmpty else {
            throw WeatherError.placeNotFound
        }
        let data = try await get("https://geocoding-api.open-meteo.com/v1/search?name=\(query)&count=10&countryCode=PH")
        let places = try JSONDecoder().decode(GeoResponse.self, from: data).results ?? []
        let match = places.first { $0.admin2?.localizedCaseInsensitiveCompare(province) == .orderedSame } ?? places.first
        guard let match else { throw WeatherError.placeNotFound }
        UserDefaults.standard.set([match.latitude, match.longitude, match.name], forKey: cacheKey)
        return (match.latitude, match.longitude, match.name)
    }

    private static func get(_ url: String) async throws -> Data {
        guard let url = URL(string: url) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }
}
