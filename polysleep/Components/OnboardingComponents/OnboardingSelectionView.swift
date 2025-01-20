import SwiftUI

struct OnboardingSelectionView<T: Identifiable & LocalizableEnum & Hashable>: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let options: [T]
    @Binding var selectedOption: T?
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        options: [T],
        selectedOption: Binding<T?>
    ) {
        self.title = title
        self.description = description
        self.options = options
        self._selectedOption = selectedOption
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingTitleView(title: title, description: description)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(options) { option in
                        SelectionButton(
                            title: NSLocalizedString(option.localizedKey, comment: ""),
                            isSelected: selectedOption.map { $0 == option } ?? false,
                            action: { 
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedOption = option
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct OnboardingBoolSelectionView: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    @Binding var selectedValue: Bool?
    let yesText: LocalizedStringKey
    let noText: LocalizedStringKey
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        selectedValue: Binding<Bool?>,
        yesText: LocalizedStringKey = "onboarding.yes",
        noText: LocalizedStringKey = "onboarding.no"
    ) {
        self.title = title
        self.description = description
        self._selectedValue = selectedValue
        self.yesText = yesText
        self.noText = noText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingTitleView(title: title, description: description)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 12) {
                SelectionButton(
                    title: NSLocalizedString(String(describing: yesText), comment: ""),
                    isSelected: selectedValue == true,
                    action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedValue = true
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
                
                SelectionButton(
                    title: NSLocalizedString(String(describing: noText), comment: ""),
                    isSelected: selectedValue == false,
                    action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedValue = false
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

struct OnboardingMultiSelectionView<T: Identifiable & LocalizableEnum & Hashable>: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let options: [T]
    @Binding var selectedOptions: Set<T>
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        options: [T],
        selectedOptions: Binding<Set<T>>
    ) {
        self.title = title
        self.description = description
        self.options = options
        self._selectedOptions = selectedOptions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingTitleView(title: title, description: description)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(options) { option in
                        MultiSelectionButton(
                            title: NSLocalizedString(option.localizedKey, comment: ""),
                            isSelected: selectedOptions.contains(option),
                            action: { 
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedOptions.contains(option) {
                                        selectedOptions.remove(option)
                                    } else {
                                        selectedOptions.insert(option)
                                    }
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 32) {
        OnboardingSelectionView(
            title: "Single Selection",
            description: "Please select one option",
            options: PreviewOption.allCases.map { $0 },
            selectedOption: .constant(nil)
        )
        
        OnboardingBoolSelectionView(
            title: "Yes/No Question",
            description: "Please answer the question",
            selectedValue: .constant(nil)
        )
        
        OnboardingMultiSelectionView(
            title: "Multi Selection",
            description: "Select multiple options",
            options: PreviewOption.allCases.map { $0 },
            selectedOptions: .constant([])
        )
    }
    .padding()
    .background(Color("BackgroundColor"))
}

private enum PreviewOption: String, CaseIterable, Identifiable, LocalizableEnum {
    case option1 = "Option 1"
    case option2 = "Option 2"
    case option3 = "Option 3"
    
    var id: String { rawValue }
    var localizedKey: String { rawValue }
}
