import Foundation

struct StockPriceService {
    static func fetchCurrentPrice(for symbol: String) async throws -> Double {
        // Strip exchange suffix if present (e.g. "GOOGL:USD" → "GOOGL")
        let ticker = symbol.components(separatedBy: ":").first ?? symbol

        guard let encoded = ticker.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(encoded)&token=\(APIConfig.finnhubKey)")
        else { throw StockPriceError.invalidSymbol }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw StockPriceError.priceNotFound
        }

        let quote = try JSONDecoder().decode(FinnhubQuote.self, from: data)
        guard quote.c > 0 else { throw StockPriceError.priceNotFound }
        return quote.c
    }

    static func fetchLogoURL(for symbol: String) async throws -> String {
        let ticker = symbol.components(separatedBy: ":").first ?? symbol
        guard let encoded = ticker.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://finnhub.io/api/v1/stock/profile2?symbol=\(encoded)&token=\(APIConfig.finnhubKey)")
        else { return "" }
        let (data, _) = try await URLSession.shared.data(from: url)
        let profile = try JSONDecoder().decode(FinnhubProfile.self, from: data)
        return profile.logo ?? ""
    }
}

enum StockPriceError: Error, LocalizedError {
    case invalidSymbol
    case priceNotFound

    var errorDescription: String? {
        switch self {
        case .invalidSymbol:  return "Invalid ticker symbol."
        case .priceNotFound:  return "Could not retrieve price. Check the symbol and try again."
        }
    }
}

private struct FinnhubQuote: Codable {
    let c: Double   // current price
}

private struct FinnhubProfile: Codable {
    let logo: String?
}
