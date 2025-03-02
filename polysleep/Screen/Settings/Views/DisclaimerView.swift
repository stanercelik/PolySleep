import SwiftUI

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("disclaimer.title", tableName: "Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("disclaimer.content", tableName: "Profile")
                    .font(.body)
                
                Text("disclaimer.medical", tableName: "Profile")
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Text("disclaimer.medical.content", tableName: "Profile")
                    .font(.body)
                
                Text("disclaimer.liability", tableName: "Profile")
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Text("disclaimer.liability.content", tableName: "Profile")
                    .font(.body)
                
                Text("disclaimer.contact", tableName: "Profile")
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Text("disclaimer.contact.content", tableName: "Profile")
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("settings.other.disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DisclaimerView()
        }
    }
}
