import SwiftUI

struct LicenseView: View {
    @StateObject private var licenseViewModel = LicenseViewModel()
    
    var body: some View {
        VStack(spacing: 15) {
            Text("许可证管理")
                .font(.headline)
            
            if case .licensed = licenseViewModel.licenseState {
                VStack(spacing: 10) {
                    Text("Ultra 权益已激活")
                        .foregroundColor(.green)
                    
                    Button(role: .destructive, action: {
                        licenseViewModel.removeLicense()
                    }) {
                        Text("移除许可证")
                    }
                }
            } else {
                TextField("输入许可证密钥", text: $licenseViewModel.licenseKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                
                Button(action: {
                    Task {
                        await licenseViewModel.validateLicense()
                    }
                }) {
                    if licenseViewModel.isValidating {
                        ProgressView()
                    } else {
                        Text("激活许可证")
                    }
                }
                .disabled(licenseViewModel.isValidating)
            }
            
            if let message = licenseViewModel.validationMessage {
                Text(message)
                    .foregroundColor(licenseViewModel.licenseState == .licensed ? .green : .red)
                    .font(.caption)
            }
        }
        .padding()
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView()
    }
} 
