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
	}

	func translate(articleID: String, html: String) async throws -> String {
		if let cached = translationCache[articleID] {
			return cached
		}

		guard let key = apiKey, !key.isEmpty else {
			throw AITranslationError.noAPIKey
		}

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
				["role": "user", "content": html]
			],
			"temperature": 0.3,
			"max_tokens": 8192,
			"stream": false
		]

		var request = URLRequest(url: apiURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
		request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
		request.timeoutInterval = 120

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

		let translatedHTML = content.trimmingCharacters(in: .whitespacesAndNewlines)
		translationCache[articleID] = translatedHTML
		return translatedHTML
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
