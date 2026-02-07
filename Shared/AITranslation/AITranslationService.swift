//
//  AITranslationService.swift
//  NetNewsWire
//
//  Created for AI Translation feature.
//

import Foundation

@MainActor
final class AITranslationService {

	static let shared = AITranslationService()

	private let apiURL = URL(string: "https://api.siliconflow.cn/v1/chat/completions")!
	private let model = "deepseek-ai/DeepSeek-V3.2"

	private var translationCache: [String: String] = [:]
	private var summaryCache: [String: String] = [:]

	private init() {}

	var apiKey: String? {
		get {
			UserDefaults.standard.string(forKey: "AITranslationAPIKey")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "AITranslationAPIKey")
		}
	}

	var hasAPIKey: Bool {
		guard let key = apiKey, !key.isEmpty else {
			return false
		}
		return true
	}

	func cachedTranslation(for articleID: String) -> String? {
		return translationCache[articleID]
	}

	func clearCache(for articleID: String) {
		translationCache.removeValue(forKey: articleID)
		summaryCache.removeValue(forKey: articleID)
	}

	func cachedSummary(for articleID: String) -> String? {
		return summaryCache[articleID]
	}

	private let maxChunkLength = 3000

	func translate(articleID: String, html: String) async throws -> String {
		if let cached = translationCache[articleID] {
			return cached
		}

		guard let key = apiKey, !key.isEmpty else {
			throw AITranslationError.noAPIKey
		}

		let cleanedHTML = cleanHTML(html)
		let chunks = splitIntoChunks(cleanedHTML)

		var translatedParts: [String] = []
		for chunk in chunks {
			let translated = try await translateChunk(chunk, key: key)
			translatedParts.append(translated)
		}

		let translatedHTML = translatedParts.joined(separator: "\n")
		translationCache[articleID] = translatedHTML
		return translatedHTML
	}

	private func cleanHTML(_ html: String) -> String {
		var cleaned = html
		let patternsToRemove = [
			" class=\"[^\"]*\"",
			" style=\"[^\"]*\"",
			" id=\"[^\"]*\"",
			" data-[a-z-]+=\"[^\"]*\"",
			" aria-[a-z-]+=\"[^\"]*\"",
			" role=\"[^\"]*\""
		]
		for pattern in patternsToRemove {
			if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
				cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
			}
		}
		cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
		return cleaned
	}

	private func splitIntoChunks(_ html: String) -> [String] {
		let blockPattern = "<(?:p|div|blockquote|h[1-6]|li|tr|section|article|figure|figcaption|pre|ul|ol|table)[\\s>]"
		guard let regex = try? NSRegularExpression(pattern: blockPattern, options: .caseInsensitive) else {
			return [html]
		}

		let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
		guard matches.count > 1 else {
			return [html]
		}

		var splitPoints: [String.Index] = []
		for match in matches {
			if let range = Range(match.range, in: html) {
				splitPoints.append(range.lowerBound)
			}
		}

		var chunks: [String] = []
		var currentChunk = ""

		for i in 0..<splitPoints.count {
			let start = splitPoints[i]
			let end = (i + 1 < splitPoints.count) ? splitPoints[i + 1] : html.endIndex
			let segment = String(html[start..<end])

			if currentChunk.count + segment.count > maxChunkLength && !currentChunk.isEmpty {
				chunks.append(currentChunk)
				currentChunk = segment
			} else {
				currentChunk += segment
			}
		}

		let prefix = String(html[html.startIndex..<splitPoints[0]])
		if !prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			if let first = chunks.first {
				chunks[0] = prefix + first
			} else {
				currentChunk = prefix + currentChunk
			}
		}

		if !currentChunk.isEmpty {
			chunks.append(currentChunk)
		}

		if chunks.isEmpty {
			return [html]
		}

		return chunks
	}

	private func translateChunk(_ chunk: String, key: String) async throws -> String {
		let systemPrompt = """
		你是一个专业的翻译助手。请将以下HTML内容翻译为中文。要求：
		1. 保持所有HTML标签和结构不变
		2. 只翻译文本内容
		3. 保持代码块中的代码不翻译
		4. 保持链接URL不变
		5. 直接返回翻译后的HTML，不要添加任何额外说明
		"""

		let requestBody: [String: Any] = [
			"model": model,
			"messages": [
				["role": "system", "content": systemPrompt],
				["role": "user", "content": chunk]
			],
			"temperature": 0.3,
			"max_tokens": 16384,
			"stream": false
		]

		var request = URLRequest(url: apiURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
		request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
		request.timeoutInterval = 180

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw AITranslationError.invalidResponse
		}

		guard httpResponse.statusCode == 200 else {
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
			throw AITranslationError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
		}

		guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
			  let choices = json["choices"] as? [[String: Any]],
			  let firstChoice = choices.first,
			  let message = firstChoice["message"] as? [String: Any],
			  let content = message["content"] as? String else {
			throw AITranslationError.invalidResponse
		}

		return content.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	func summarize(articleID: String, html: String) async throws -> String {
		if let cached = summaryCache[articleID] {
			return cached
		}

		guard let key = apiKey, !key.isEmpty else {
			throw AITranslationError.noAPIKey
		}

		let systemPrompt = """
		你是一个专业的内容总结助手。请对以下文章内容进行总结。要求：
		1. 用中文输出总结
		2. 总结要简洁明了，抓住文章核心要点
		3. 使用HTML格式输出，可以用<p>、<ul>、<li>等标签
		4. 总结长度控制在200字以内
		5. 直接返回总结内容的HTML，不要添加"总结"等标题
		"""

		let requestBody: [String: Any] = [
			"model": model,
			"messages": [
				["role": "system", "content": systemPrompt],
				["role": "user", "content": html]
			],
			"temperature": 0.3,
			"max_tokens": 2048,
			"stream": false
		]

		var request = URLRequest(url: apiURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
		request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
		request.timeoutInterval = 60

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw AITranslationError.invalidResponse
		}

		guard httpResponse.statusCode == 200 else {
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
			throw AITranslationError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
		}

		guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
			  let choices = json["choices"] as? [[String: Any]],
			  let firstChoice = choices.first,
			  let message = firstChoice["message"] as? [String: Any],
			  let content = message["content"] as? String else {
			throw AITranslationError.invalidResponse
		}

		let summaryHTML = content.trimmingCharacters(in: .whitespacesAndNewlines)
		summaryCache[articleID] = summaryHTML
		return summaryHTML
	}
}

enum AITranslationError: LocalizedError {
	case noAPIKey
	case invalidResponse
	case apiError(statusCode: Int, message: String)

	var errorDescription: String? {
		switch self {
		case .noAPIKey:
			return "Please set your SiliconFlow API Key first."
		case .invalidResponse:
			return "Invalid response from translation API."
		case .apiError(let statusCode, let message):
			return "API Error (\(statusCode)): \(message)"
		}
	}
}
