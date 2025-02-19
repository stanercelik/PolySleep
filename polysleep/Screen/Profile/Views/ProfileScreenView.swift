import SwiftUI

struct ProfileScreenView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Profil")
                    .font(.title)
                    .padding()
                    
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreenView()
    }
}
