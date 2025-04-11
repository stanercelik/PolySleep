import SwiftUI

struct FilterMenuView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStartDate = Date().addingTimeInterval(-7*24*60*60) // Bir hafta önce
    @State private var selectedEndDate = Date()
    @State private var showCustomDatePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Başlık
                    Text("Filtreleme Seçenekleri")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("TextColor"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Zaman filtresi
                            FilterSection(
                                title: "Zaman Aralığı",
                                systemImage: "calendar",
                                accentColor: Color("PrimaryColor")
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                                        FilterOptionButton(
                                            title: LocalizedStringKey(filter.rawValue),
                                            isSelected: !viewModel.isCustomFilterVisible && viewModel.selectedFilter == filter,
                                            accentColor: Color("PrimaryColor")
                                        ) {
                                            viewModel.setFilter(filter)
                                            dismiss()
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, 8)
                                    
                                    CustomDateRangeSection(
                                        isVisible: $showCustomDatePicker,
                                        isSelected: viewModel.isCustomFilterVisible,
                                        startDate: $selectedStartDate,
                                        endDate: $selectedEndDate,
                                        accentColor: Color("PrimaryColor"),
                                        onApply: {
                                            viewModel.setDateRange(selectedStartDate...selectedEndDate)
                                            dismiss()
                                        }
                                    )
                                }
                            }
                            
                            // Uyku tipi filtresi
                            FilterSection(
                                title: "Uyku Tipi",
                                systemImage: "bed.double.fill",
                                accentColor: Color("AccentColor")
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(SleepTypeFilter.allCases, id: \.self) { filter in
                                        FilterOptionButton(
                                            title: LocalizedStringKey(filter.rawValue),
                                            icon: filter == .core ? "bed.double.fill" : 
                                                  filter == .nap ? "powersleep" : "moon.stars.fill",
                                            iconColor: filter == .core ? Color("PrimaryColor") : 
                                                      filter == .nap ? .orange : .purple,
                                            isSelected: viewModel.selectedSleepTypeFilter == filter,
                                            accentColor: filter == .core ? Color("PrimaryColor") : 
                                                       filter == .nap ? .orange : .purple
                                        ) {
                                            viewModel.setSleepTypeFilter(filter)
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            
                            // Kapama butonu
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Kapat")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("CardBackground"))
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let systemImage: String
    var accentColor: Color = Color("AccentColor")
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("TextColor"))
            }
            
            content
                .padding(.leading, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct FilterOptionButton: View {
    let title: LocalizedStringKey
    var icon: String? = nil
    var iconColor: Color = Color("AccentColor")
    let isSelected: Bool
    var accentColor: Color = Color("AccentColor")
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .white : iconColor)
                        .frame(width: 24)
                }
                
                Text(title, tableName: "History")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color("TextColor"))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accentColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color("SecondaryTextColor").opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct CustomDateRangeSection: View {
    @Binding var isVisible: Bool
    let isSelected: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    var accentColor: Color = Color("AccentColor")
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterOptionButton(
                title: "Özel Tarih Aralığı",
                icon: "calendar.badge.clock",
                iconColor: accentColor,
                isSelected: isSelected,
                accentColor: accentColor
            ) {
                withAnimation {
                    isVisible.toggle()
                }
            }
            
            if isVisible {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Başlangıç Tarihi")
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        DatePicker(
                            "",
                            selection: $startDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bitiş Tarihi")
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        DatePicker(
                            "",
                            selection: $endDate,
                            in: startDate...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(accentColor)
                    }
                    
                    Button(action: onApply) {
                        Text("Uygula")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(accentColor)
                                    .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("CardBackground").opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("SecondaryTextColor").opacity(0.1), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct FilterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = HistoryViewModel()
        FilterMenuView(viewModel: viewModel)
    }
}
