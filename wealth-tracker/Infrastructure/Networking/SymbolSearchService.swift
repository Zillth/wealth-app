import Foundation

struct SymbolResult: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let quoteType: String
}

struct SymbolSearchService {
    static func search(query: String) async throws -> [SymbolResult] {
        guard !query.isEmpty,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://finnhub.io/api/v1/search?q=\(encoded)&token=\(APIConfig.finnhubKey)")
        else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(FinnhubSearchResponse.self, from: data)

        return decoded.result
            .filter { !$0.symbol.isEmpty && !$0.description.isEmpty }
            .map {
                SymbolResult(
                    symbol: $0.symbol,
                    name: $0.description,
                    quoteType: $0.type
                )
            }
    }
}

private struct FinnhubSearchResponse: Codable {
    let result: [Result]
    struct Result: Codable {
        let symbol: String
        let description: String
        let type: String
    }
}
