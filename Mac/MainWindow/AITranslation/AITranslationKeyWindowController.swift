//
//  AITranslationKeyWindowController.swift
//  NetNewsWire
//
//  Created for AI Translation feature.
//

import AppKit

@MainActor
final class AITranslationKeyWindowController: NSWindowController {

	private var apiKeyTextField: NSTextField!
	private var completionHandler: ((Bool) -> Void)?

	convenience init() {
		let window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 450, height: 180),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: true
		)
		window.title = NSLocalizedString("AI Translation Settings", comment: "AI Translation Settings")
		window.isReleasedWhenClosed = false
		self.init(window: window)
		setupUI()
	}

	func showSheet(on parentWindow: NSWindow, completion: @escaping (Bool) -> Void) {
		completionHandler = completion
		apiKeyTextField.stringValue = AITranslationService.shared.apiKey ?? ""
		parentWindow.beginSheet(window!) { [weak self] response in
			self?.completionHandler?(response == .OK)
		}
	}

	private func setupUI() {
		guard let window = window else { return }

		let contentView = NSView(frame: window.contentView!.bounds)
		contentView.autoresizingMask = [.width, .height]

		// Icon
		let iconView = NSImageView(frame: NSRect(x: 20, y: 110, width: 48, height: 48))
		if let image = NSImage(systemSymbolName: "key.fill", accessibilityDescription: "API Key") {
			iconView.image = image
			iconView.contentTintColor = .controlAccentColor
		}
		contentView.addSubview(iconView)

		// Title label
		let titleLabel = NSTextField(labelWithString: NSLocalizedString("SiliconFlow API Key", comment: "SiliconFlow API Key"))
		titleLabel.frame = NSRect(x: 76, y: 130, width: 350, height: 20)
		titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
		contentView.addSubview(titleLabel)

		// Description label
		let descLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("Enter your SiliconFlow API key for AI translation. Get one at siliconflow.cn", comment: "API Key description"))
		descLabel.frame = NSRect(x: 76, y: 105, width: 350, height: 30)
		descLabel.font = NSFont.systemFont(ofSize: 12)
		descLabel.textColor = .secondaryLabelColor
		contentView.addSubview(descLabel)

		// API Key text field
		apiKeyTextField = NSTextField(frame: NSRect(x: 20, y: 65, width: 410, height: 24))
		apiKeyTextField.placeholderString = "sk-..."
		apiKeyTextField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
		contentView.addSubview(apiKeyTextField)

		// Cancel button
		let cancelButton = NSButton(title: NSLocalizedString("Cancel", comment: "Cancel"), target: self, action: #selector(cancel(_:)))
		cancelButton.frame = NSRect(x: 250, y: 20, width: 80, height: 32)
		cancelButton.bezelStyle = .rounded
		cancelButton.keyEquivalent = "\u{1b}" // Escape
		contentView.addSubview(cancelButton)

		// Save button
		let saveButton = NSButton(title: NSLocalizedString("Save", comment: "Save"), target: self, action: #selector(save(_:)))
		saveButton.frame = NSRect(x: 340, y: 20, width: 90, height: 32)
		saveButton.bezelStyle = .rounded
		saveButton.keyEquivalent = "\r" // Return
		contentView.addSubview(saveButton)

		window.contentView = contentView
	}

	@objc private func save(_ sender: Any?) {
		let key = apiKeyTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		AITranslationService.shared.apiKey = key
		window?.sheetParent?.endSheet(window!, returnCode: .OK)
	}

	@objc private func cancel(_ sender: Any?) {
		window?.sheetParent?.endSheet(window!, returnCode: .cancel)
	}
}
