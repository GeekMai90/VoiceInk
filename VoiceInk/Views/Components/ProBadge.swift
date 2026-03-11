import SwiftUI

struct ProBadge: View {
    var body: some View {
        Text("Ultra")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
            )
    }
}

#Preview {
    ProBadge()
} 
