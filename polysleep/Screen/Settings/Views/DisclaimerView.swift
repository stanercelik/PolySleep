import SwiftUI

struct DisclaimerView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("disclaimer.title", table: "Profile"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text(L("disclaimer.content", table: "Profile"))
                    .font(.body)
                
                Text(L("disclaimer.medical", table: "Profile"))
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Text(L("disclaimer.medical.content", table: "Profile"))
                    .font(.body)
                
                Text(L("disclaimer.liability", table: "Profile"))
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Text(L("disclaimer.liability.content", table: "Profile"))
                    .font(.body)
                
                Text(L("disclaimer.contact", table: "Profile"))
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Text(L("disclaimer.contact.content", table: "Profile"))
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(L("settings.other.disclaimer", table: "Profile"))
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
