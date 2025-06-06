import SwiftUI

struct SnackbarView: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.white)
                .padding(.trailing, 4)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color("AccentColor"))
        .cornerRadius(12)
        .shadow(radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
        }
    }
}

struct SnackbarModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            if isPresented {
                SnackbarView(message: message, isPresented: $isPresented)
            }
        }
    }
}

extension View {
    func snackbar(isPresented: Binding<Bool>, message: String) -> some View {
        self.modifier(SnackbarModifier(isPresented: isPresented, message: message))
    }
}
