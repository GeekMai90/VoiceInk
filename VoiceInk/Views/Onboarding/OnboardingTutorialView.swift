import SwiftUI
import KeyboardShortcuts

struct OnboardingTutorialView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @State private var scale: CGFloat = 0.8
    @State private var opacity: CGFloat = 0
    @State private var transcribedText: String = ""
    @State private var isTextFieldFocused: Bool = false
    @State private var showingShortcutHint: Bool = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Reusable background
                OnboardingBackgroundView()
                
                HStack(spacing: 0) {
                    // Left side - Tutorial instructions
                    VStack(alignment: .leading, spacing: 40) {
                        // Title and description
                        VStack(alignment: .leading, spacing: 16) {
                            Text("试试看")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("来测试一下你的 VoiceInk 设置。")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)
                        }
                        
                        // Keyboard shortcut display
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("你的快捷键")
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                
                            }
                            
                            if hotkeyManager.selectedHotkey1 == .custom,
                               let shortcut = KeyboardShortcuts.getShortcut(for: .toggleMiniRecorder) {
                                KeyboardShortcutView(shortcut: shortcut)
                                    .scaleEffect(1.2)
                            } else if hotkeyManager.selectedHotkey1 != .none && hotkeyManager.selectedHotkey1 != .custom {
                                Text(hotkeyManager.selectedHotkey1.displayName)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(1...4, id: \.self) { step in
                                instructionStep(number: step, text: getInstructionText(for: step))
                            }
                        }
                        
                        Spacer()
                        
                        // Continue button
                        Button(action: {
                            hasCompletedOnboarding = true
                        }) {
                            Text("完成设置")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.accentColor)
                                .cornerRadius(25)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .opacity(transcribedText.isEmpty ? 0.5 : 1)
                        .disabled(transcribedText.isEmpty)
                        
                        SkipButton(text: "暂时跳过") {
                            hasCompletedOnboarding = true
                        }
                    }
                    .padding(60)
                    .frame(width: geometry.size.width * 0.5)
                    
                    // Right side - Interactive area
                    VStack {
                        // Magical text editor area
                        ZStack {
                            // Glowing background
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .overlay(
                                    // Subtle gradient overlay
                                    LinearGradient(
                                        colors: [
                                            Color.accentColor.opacity(0.05),
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.accentColor.opacity(0.1), radius: 15, x: 0, y: 0)
                            
                            // Text editor with custom styling
                            TextEditor(text: $transcribedText)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .focused($isFocused)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.white)
                                .padding(20)
                            
                            // Placeholder text with magical appearance
                            if transcribedText.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white.opacity(0.3))
                                    
                                    Text("点击这里，然后开始说话…")
                                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .allowsHitTesting(false)
                            }
                            
                            // Subtle animated border
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.accentColor.opacity(isFocused ? 0.4 : 0.1),
                                            Color.accentColor.opacity(isFocused ? 0.2 : 0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .animation(.easeInOut(duration: 0.3), value: isFocused)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(60)
                    .frame(width: geometry.size.width * 0.5)
                }
            }
        }
        .onAppear {
            animateIn()
            isFocused = true
        }
    }
    
    private func getInstructionText(for step: Int) -> String {
        switch step {
        case 1: return "点击右侧文本区域"
        case 2: return "按下你的快捷键"
        case 3: return "说一句话"
        case 4: return "再次按下快捷键"
        default: return ""
        }
    }
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(spacing: 20) {
            Text("\(number)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.accentColor.opacity(0.2)))
                .overlay(
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            
            Text(text)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1
            opacity = 1
        }
    }
} 
