import Foundation
import SwiftUI    // Import to ensure we have access to SwiftUI types if needed

enum PredefinedPrompts {
    private static let predefinedPromptsKey = "PredefinedPrompts"
    
    // Static UUIDs for predefined prompts
    static let defaultPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let assistantPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    
    static var all: [CustomPrompt] {
        // Always return the latest predefined prompts from source code
        createDefaultPrompts()
    }
    
    static func createDefaultPrompts() -> [CustomPrompt] {
        [
            CustomPrompt(
                id: defaultPromptId,
                title: "默认",
                promptText: PromptTemplates.all.first { $0.title == "系统默认" }?.promptText ?? "",
                icon: "checkmark.seal.fill",
                description: "默认模式，用于提升转写清晰度和准确度",
                isPredefined: true,
                useSystemInstructions: true
            ),
            
            CustomPrompt(
                id: assistantPromptId,
                title: "助手",
                promptText: AIPrompts.assistantMode,
                icon: "bubble.left.and.bubble.right.fill",
                description: "用 AI 助手模式直接回答你的问题",
                isPredefined: true,
                useSystemInstructions: false
            )
        ]
    }
}
