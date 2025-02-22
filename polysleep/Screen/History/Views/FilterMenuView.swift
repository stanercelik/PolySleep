import SwiftUI

struct FilterMenuView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(LocalizedStringKey("Filtreler"))) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            viewModel.setFilter(filter)
                            dismiss()
                        }) {
                            HStack {
                                Text(LocalizedStringKey(filter.rawValue))
                                    .foregroundColor(Color("TextColor"))
                                Spacer()
                                if !viewModel.isCustomFilterVisible && viewModel.selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("AccentColor"))
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text(LocalizedStringKey("Uyku Tipi"))) {
                    ForEach(SleepTypeFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            viewModel.setSleepTypeFilter(filter)
                            dismiss()
                        }) {
                            HStack {
                                Text(LocalizedStringKey(filter.rawValue))
                                    .foregroundColor(Color("TextColor"))
                                Spacer()
                                if viewModel.selectedSleepTypeFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("AccentColor"))
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text(LocalizedStringKey("Özel Tarih Aralığı"))) {
                    Button(action: {
                        viewModel.isCalendarPresented = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(LocalizedStringKey("Tarih Seç"))
                            Spacer()
                            if viewModel.isCustomFilterVisible {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AccentColor"))
                            }
                        }
                        .foregroundColor(Color("TextColor"))
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(Text(LocalizedStringKey("Filtrele")))
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Text(LocalizedStringKey("Tamam"))
                    .foregroundColor(Color("AccentColor"))
            })
        }
    }
}
