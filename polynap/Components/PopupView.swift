import SwiftUI

struct PopupView<Content: View>: View {
    let content: Content
    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isPresented {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }
                    
                    // Popup
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                    .background(Color("CardBackground"))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 8)
                        }
                        
                        content
                            .padding(.horizontal, 8)
                    }
                    .background(Color("CardBackground"))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 16)
                    .frame(width: min(geometry.size.width - 40, 320))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
        }
    }
}
