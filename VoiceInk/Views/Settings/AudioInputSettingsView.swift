import SwiftUI

struct AudioInputSettingsView: View {
    @ObservedObject var audioDeviceManager = AudioDeviceManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                mainContent
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var mainContent: some View {
        VStack(spacing: 40) {
            inputModeSection

            switch audioDeviceManager.inputMode {
            case .systemDefault:
                systemDefaultSection
            case .custom:
                customDeviceSection
            case .prioritized:
                prioritizedDevicesSection
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
    
    private var heroSection: some View {
        CompactHeroSection(
            icon: "waveform",
            title: "音频输入",
            description: "配置你的麦克风与输入设备偏好"
        )
    }
    
    private var inputModeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("输入模式")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                ForEach(AudioInputMode.allCases, id: \.self) { mode in
                    InputModeCard(
                        mode: mode,
                        isSelected: audioDeviceManager.inputMode == mode,
                        action: { audioDeviceManager.selectInputMode(mode) }
                    )
                }
            }
        }
    }
    
    private var systemDefaultSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("当前设备")
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                Image(systemName: "display")
                    .foregroundStyle(.secondary)

                Text(audioDeviceManager.getSystemDefaultDeviceName() ?? "暂无可用设备")
                    .foregroundStyle(.primary)

                Spacer()

                Label("已启用", systemImage: "wave.3.right")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
            }
            .padding()
            .background(CardBackground(isSelected: false))
        }
    }

    private var customDeviceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("可用设备")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { audioDeviceManager.loadAvailableDevices() }) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            VStack(spacing: 12) {
                ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                    DeviceSelectionCard(
                        name: device.name,
                        isSelected: audioDeviceManager.selectedDeviceID == device.id,
                        isActive: audioDeviceManager.getCurrentDevice() == device.id
                    ) {
                        audioDeviceManager.selectDevice(id: device.id)
                    }
                }
            }
        }
    }
    
    private var prioritizedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if audioDeviceManager.availableDevices.isEmpty {
                emptyDevicesState
            } else {
                prioritizedDevicesContent
                Divider().padding(.vertical, 8)
                availableDevicesContent
            }
        }
    }
    
    private var prioritizedDevicesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("优先设备")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("设备会按优先级顺序使用。如果当前设备不可用，就自动尝试下一个；如果优先列表里都不可用，则回退到内置麦克风。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if audioDeviceManager.prioritizedDevices.isEmpty {
                Text("还没有设置优先设备")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                prioritizedDevicesList
            }
        }
    }
    
    private var availableDevicesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可添加的设备")
                .font(.title2)
                .fontWeight(.semibold)
            
            availableDevicesList
        }
    }
    
    private var emptyDevicesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.circle.fill")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("没有音频输入设备")
                    .font(.headline)
                Text("连接一个音频输入设备后即可开始使用")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(CardBackground(isSelected: false))
    }
    
    private var prioritizedDevicesList: some View {
        VStack(spacing: 12) {
            ForEach(audioDeviceManager.prioritizedDevices.sorted(by: { $0.priority < $1.priority })) { device in
                devicePriorityCard(for: device)
            }
        }
    }
    
    private func devicePriorityCard(for prioritizedDevice: PrioritizedDevice) -> some View {
        let device = audioDeviceManager.availableDevices.first(where: { $0.uid == prioritizedDevice.id })
        return DevicePriorityCard(
            name: prioritizedDevice.name,
            priority: prioritizedDevice.priority,
            isActive: device.map { audioDeviceManager.getCurrentDevice() == $0.id } ?? false,
            isPrioritized: true,
            isAvailable: device != nil,
            canMoveUp: prioritizedDevice.priority > 0,
            canMoveDown: prioritizedDevice.priority < audioDeviceManager.prioritizedDevices.count - 1,
            onTogglePriority: { audioDeviceManager.removePrioritizedDevice(id: prioritizedDevice.id) },
            onMoveUp: { moveDeviceUp(prioritizedDevice) },
            onMoveDown: { moveDeviceDown(prioritizedDevice) }
        )
    }
    
    private var availableDevicesList: some View {
        let unprioritizedDevices = audioDeviceManager.availableDevices.filter { device in
            !audioDeviceManager.prioritizedDevices.contains { $0.id == device.uid }
        }
        
        return Group {
            if unprioritizedDevices.isEmpty {
                Text("没有更多可添加的设备")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(unprioritizedDevices, id: \.id) { device in
                    DevicePriorityCard(
                        name: device.name,
                        priority: nil,
                        isActive: audioDeviceManager.getCurrentDevice() == device.id,
                        isPrioritized: false,
                        isAvailable: true,
                        canMoveUp: false,
                        canMoveDown: false,
                        onTogglePriority: { audioDeviceManager.addPrioritizedDevice(uid: device.uid, name: device.name) },
                        onMoveUp: {},
                        onMoveDown: {}
                    )
                }
            }
        }
    }
    
    private func moveDeviceUp(_ device: PrioritizedDevice) {
        guard device.priority > 0,
              let currentIndex = audioDeviceManager.prioritizedDevices.firstIndex(where: { $0.id == device.id })
        else { return }
        
        var devices = audioDeviceManager.prioritizedDevices
        devices.swapAt(currentIndex, currentIndex - 1)
        updatePriorities(devices)
    }
    
    private func moveDeviceDown(_ device: PrioritizedDevice) {
        guard device.priority < audioDeviceManager.prioritizedDevices.count - 1,
              let currentIndex = audioDeviceManager.prioritizedDevices.firstIndex(where: { $0.id == device.id })
        else { return }
        
        var devices = audioDeviceManager.prioritizedDevices
        devices.swapAt(currentIndex, currentIndex + 1)
        updatePriorities(devices)
    }
    
    private func updatePriorities(_ devices: [PrioritizedDevice]) {
        let updatedDevices = devices.enumerated().map { index, device in
            PrioritizedDevice(id: device.id, name: device.name, priority: index)
        }
        audioDeviceManager.updatePriorities(devices: updatedDevices)
    }
}

struct InputModeCard: View {
    let mode: AudioInputMode
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch mode {
        case .systemDefault: return "display"
        case .custom: return "mic.circle.fill"
        case .prioritized: return "list.number"
        }
    }

    private var description: String {
        switch mode {
        case .systemDefault: return "使用 Mac 当前的默认输入设备"
        case .custom: return "手动选择一个固定输入设备"
        case .prioritized: return "按顺序设置设备优先级"
        }
    }

    private var title: String {
        switch mode {
        case .systemDefault: return "系统默认"
        case .custom: return "自定义设备"
        case .prioritized: return "优先级模式"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(CardBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }
}

struct DeviceSelectionCard: View {
    let name: String
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.system(size: 18))
                
                Text(name)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isActive {
                    Label("已启用", systemImage: "wave.3.right")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.green.opacity(0.1))
                        )
                }
            }
            .padding()
            .background(CardBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }
}

struct DevicePriorityCard: View {
    let name: String
    let priority: Int?
    let isActive: Bool
    let isPrioritized: Bool
    let isAvailable: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onTogglePriority: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    
    var body: some View {
        HStack {
            // Priority number or dash
            if let priority = priority {
                Text("\(priority + 1)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            } else {
                Text("-")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }
            
            // Device name
            Text(name)
                .foregroundStyle(isAvailable ? .primary : .secondary)
            
            Spacer()
            
            // Status and Controls
            HStack(spacing: 12) {
                // Active status
                if isActive {
                    Label("已启用", systemImage: "wave.3.right")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.green.opacity(0.1))
                        )
                } else if !isAvailable && isPrioritized {
                    Label("不可用", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.windowBackgroundColor).opacity(0.4))
                        )
                }
                
                // Priority controls (only show if prioritized)
                if isPrioritized {
                    HStack(spacing: 2) {
                        Button(action: onMoveUp) {
                            Image(systemName: "chevron.up")
                                .foregroundStyle(canMoveUp ? .blue : .secondary.opacity(0.5))
                        }
                        .disabled(!canMoveUp)
                        
                        Button(action: onMoveDown) {
                            Image(systemName: "chevron.down")
                                .foregroundStyle(canMoveDown ? .blue : .secondary.opacity(0.5))
                        }
                        .disabled(!canMoveDown)
                    }
                }
                
                // Toggle priority button
                Button(action: onTogglePriority) {
                    Image(systemName: isPrioritized ? "minus.circle.fill" : "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isPrioritized ? .red : .blue)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(CardBackground(isSelected: false))
    }
} 
