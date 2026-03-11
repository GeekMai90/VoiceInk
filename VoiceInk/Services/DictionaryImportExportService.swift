import Foundation
import AppKit
import UniformTypeIdentifiers
import SwiftData

struct DictionaryExportData: Codable {
    let version: String
    let vocabularyWords: [String]
    let wordReplacements: [String: String]
    let exportDate: Date
}

class DictionaryImportExportService {
    static let shared = DictionaryImportExportService()

    private init() {}

    func exportDictionary(from context: ModelContext) {
        // Fetch vocabulary words from SwiftData
        var dictionaryWords: [String] = []
        let vocabularyDescriptor = FetchDescriptor<VocabularyWord>(sortBy: [SortDescriptor(\VocabularyWord.word)])
        if let items = try? context.fetch(vocabularyDescriptor) {
            dictionaryWords = items.map { $0.word }
        }

        // Fetch word replacements from SwiftData
        var wordReplacements: [String: String] = [:]
        let replacementsDescriptor = FetchDescriptor<WordReplacement>()
        if let replacements = try? context.fetch(replacementsDescriptor) {
            // Use uniquingKeysWith to handle potential duplicates gracefully (keep first occurrence)
            wordReplacements = Dictionary(replacements.map { ($0.originalText, $0.replacementText) }, uniquingKeysWith: { first, _ in first })
        }

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

        let exportData = DictionaryExportData(
            version: version,
            vocabularyWords: dictionaryWords,
            wordReplacements: wordReplacements,
            exportDate: Date()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(exportData)

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.json]
            savePanel.nameFieldStringValue = "VoiceInk_Dictionary.json"
            savePanel.title = "导出词典数据"
            savePanel.message = "选择一个位置来保存你的词汇表和词语替换规则。"

            DispatchQueue.main.async {
                if savePanel.runModal() == .OK {
                    if let url = savePanel.url {
                        do {
                            try jsonData.write(to: url)
                            self.showAlert(title: "导出成功", message: "词典数据已成功导出到 \(url.lastPathComponent)。")
                        } catch {
                            self.showAlert(title: "导出失败", message: "无法保存词典数据：\(error.localizedDescription)")
                        }
                    }
                } else {
                    self.showAlert(title: "已取消导出", message: "导出操作已取消。")
                }
            }
        } catch {
            self.showAlert(title: "导出失败", message: "无法编码词典数据：\(error.localizedDescription)")
        }
    }

    func importDictionary(into context: ModelContext) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.title = "导入词典数据"
        openPanel.message = "选择要导入的词典文件。新条目会被添加，已有条目会保留。"

        DispatchQueue.main.async {
            if openPanel.runModal() == .OK {
                guard let url = openPanel.url else {
                    self.showAlert(title: "导入失败", message: "无法获取文件 URL。")
                    return
                }

                do {
                    let jsonData = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let importedData = try decoder.decode(DictionaryExportData.self, from: jsonData)

                    // Fetch existing vocabulary words from SwiftData
                    let vocabularyDescriptor = FetchDescriptor<VocabularyWord>()
                    let existingItems = (try? context.fetch(vocabularyDescriptor)) ?? []
                    let existingWordsLower = Set(existingItems.map { $0.word.lowercased() })
                    let originalExistingCount = existingItems.count
                    var newWordsAdded = 0

                    // Import vocabulary words
                    for importedWord in importedData.vocabularyWords {
                        if !existingWordsLower.contains(importedWord.lowercased()) {
                            let newWord = VocabularyWord(word: importedWord)
                            context.insert(newWord)
                            newWordsAdded += 1
                        }
                    }

                    // Fetch existing word replacements from SwiftData
                    let replacementsDescriptor = FetchDescriptor<WordReplacement>()
                    let existingReplacements = (try? context.fetch(replacementsDescriptor)) ?? []
                    var addedCount = 0
                    var updatedCount = 0

                    // Import word replacements
                    for (importedKey, importedReplacement) in importedData.wordReplacements {
                        let normalizedImportedKey = self.normalizeReplacementKey(importedKey)
                        let importedWords = self.extractWords(from: normalizedImportedKey)

                        // Check for conflicts and update existing replacements
                        for existingReplacement in existingReplacements {
                            var existingWords = self.extractWords(from: existingReplacement.originalText)
                            var modified = false

                            for importedWord in importedWords {
                                if let index = existingWords.firstIndex(where: { $0.lowercased() == importedWord.lowercased() }) {
                                    existingWords.remove(at: index)
                                    modified = true
                                }
                            }

                            if modified {
                                if existingWords.isEmpty {
                                    context.delete(existingReplacement)
                                } else {
                                    existingReplacement.originalText = existingWords.joined(separator: ", ")
                                }
                                updatedCount += 1
                            }
                        }

                        // Add new replacement
                        let newReplacement = WordReplacement(originalText: normalizedImportedKey, replacementText: importedReplacement)
                        context.insert(newReplacement)
                        addedCount += 1
                    }

                    // Save all changes
                    try context.save()

                    var message = "已成功从 \(url.lastPathComponent) 导入词典数据。\n\n"
                    message += "词汇表：新增 \(newWordsAdded) 条，保留 \(originalExistingCount) 条\n"
                    message += "词语替换：新增 \(addedCount) 条，更新 \(updatedCount) 条"

                    self.showAlert(title: "导入成功", message: message)

                } catch {
                    // Rollback any unsaved changes to maintain consistency
                    context.rollback()
                    self.showAlert(title: "导入失败", message: "导入词典数据时出错：\(error.localizedDescription)。文件可能已损坏或格式不正确。")
                }
            } else {
                self.showAlert(title: "已取消导入", message: "导入操作已取消。")
            }
        }
    }

    private func normalizeReplacementKey(_ key: String) -> String {
        let words = extractWords(from: key)
        return words.joined(separator: ", ")
    }

    private func extractWords(from key: String) -> [String] {
        return key
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
}
