// OnboardingViewDirectUpdate.swift
// polynap
//
// How to directly update the existing OnboardingView.swift to add circular transition

/*

Bu dosya, mevcut OnboardingView.swift'i nasıl güncelleyeceğini gösterir.
Aşağıdaki değişiklikleri mevcut dosyaya uygulayabilirsin:

1. IMPORT EKLE:
   - Dosyanın başına import SwiftData ekle (zaten var)

2. STATE EKLE:
   @State private var skipButtonPosition: CGPoint = .zero
   @State private var startSkipTransition = false

3. SKIP BUTTON POSITION TRACKING:
   Skip butonuna GeometryReader ekle:

   .toolbar {
       ToolbarItem(placement: .navigationBarTrailing) {
           Button(L("general.skip", table: "Common")) {
               showSkipAlert = true
           }
           .tint(Color.appPrimary)
           .background(
               GeometryReader { proxy in
                   Color.clear
                       .onAppear {
                           // Skip button position calculation
                           let screenBounds = UIScreen.main.bounds
                           skipButtonPosition = CGPoint(
                               x: screenBounds.width - 40, // Right side
                               y: 60 // Navigation bar area  
                           )
                       }
               }
           )
       }
   }

4. CIRCULAR TRANSITION WRAPPER:
   Ana body content'i şu şekilde wrap et:

   var body: some View {
       NavigationStack {
           mainContent
               .circularTransition(
                   to: mainScreenAfterSkip,
                   startPosition: skipButtonPosition,
                   isActive: $startSkipTransition,
                   primaryColor: .appPrimary,
                   backgroundColor: .appBackground
               )
               .navigationBarTitleDisplayMode(.inline)
       }
   }

5. MEVCUT CONTENT'İ AYIR:
   Mevcut ZStack content'ini ayrı bir computed property'ye taşı:

   private var mainContent: some View {
       ZStack {
           // ... mevcut tüm content burada
       }
   }

6. DESTINATION VIEW EKLE:
   private var mainScreenAfterSkip: some View {
       // Ana ekrana geçiş için placeholder
       VStack {
           Text("Ana Ekran")
               .font(.largeTitle)
           Text("Onboarding atlandı!")
               .foregroundColor(.secondary)
       }
       .frame(maxWidth: .infinity, maxHeight: .infinity)
       .background(Color.appBackground)
       .onAppear {
           // Completion notification
           NotificationCenter.default.post(
               name: NSNotification.Name("OnboardingCompleted"),
               object: nil
           )
       }
   }

7. SKIP ALERT GÜNCELLEMESİ:
   Skip alert'teki confirm action'ı güncelle:

   .alert(...) {
       Button(L("onboarding.skip.confirm", table: "Onboarding"), role: .destructive) {
           Task {
               // Mevcut skip logic
               await viewModel.skipOnboarding()
               
               // Transition başlat
               await MainActor.run {
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                       startSkipTransition = true
                   }
               }
           }
       }
       Button(L("general.cancel", table: "Common"), role: .cancel) {}
   }

ÖRNEK COMPLETE IMPLEMENTATION:
*/

import SwiftUI
import SwiftData

struct OnboardingViewUpdatedExample: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    @StateObject private var viewModel = OnboardingViewModel()
    
    @State private var showSkipAlert = false
    // ✅ YENİ: Circular transition için state'ler
    @State private var skipButtonPosition: CGPoint = .zero
    @State private var startSkipTransition = false
    
    var body: some View {
        NavigationStack {
            // ✅ YENİ: Circular transition wrapper
            mainContent
                .circularTransition(
                    to: mainScreenAfterSkip,
                    startPosition: skipButtonPosition,
                    isActive: $startSkipTransition,
                    primaryColor: .appPrimary,
                    backgroundColor: .appBackground
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // ✅ YENİ: Mevcut content ayrı property'ye taşındı
    private var mainContent: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: PSSpacing.lg) {
                // ProgressView -> 11 Pages
                ProgressView(value: Double(viewModel.currentPage + 1), total: Double(viewModel.totalPages))
                    .tint(Color.appPrimary)
                    .padding(.horizontal, PSSpacing.lg)
                    .accessibilityValue(String(format: L("accessibility.progressPages", table: "Onboarding"), viewModel.currentPage + 1, viewModel.totalPages))
                
                ScrollView {
                    VStack(spacing: PSSpacing.xl) {
                        switch viewModel.currentPage {
                        case 0:
                            OnboardingSelectionView(
                                title: LocalizedStringKey("onboarding.sleepExperience"),
                                description: LocalizedStringKey("onboarding.sleepExperienceQuestion"),
                                options: PreviousSleepExperience.allCases,
                                selectedOption: $viewModel.previousSleepExperience
                            )
                        // ... diğer case'ler (aynı)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(PSSpacing.lg)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)
                }
                
                // Navigation buttons
                OnboardingNavigationButtons(
                    canMoveNext: viewModel.canMoveNext,
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    onNext: viewModel.moveNext,
                    onBack: viewModel.movePrevious
                )
                .padding(.horizontal, PSSpacing.lg)
                .padding(.bottom, PSSpacing.md)
            }
            .padding(.top, PSSpacing.lg)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("general.skip", table: "Common")) {
                        showSkipAlert = true
                    }
                    .tint(Color.appPrimary)
                    // ✅ YENİ: Position tracking
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    let screenBounds = UIScreen.main.bounds
                                    skipButtonPosition = CGPoint(
                                        x: screenBounds.width - 40, // Sağ taraf
                                        y: 60 // Navigation bar area
                                    )
                                }
                        }
                    )
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                analyticsManager.logOnboardingStarted()
                analyticsManager.logScreenView(screenName: "onboarding_screen", screenClass: "OnboardingViewUpdatedExample")
            }
            .onChange(of: viewModel.currentPage) { oldValue, newValue in
                // Analytics tracking (aynı)
                let stepNames = [
                    0: "sleep_experience",
                    // ... diğerleri
                ]
                
                if let stepName = stepNames[newValue] {
                    analyticsManager.logOnboardingStepCompleted(step: newValue + 1, stepName: stepName)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showLoadingView) {
            // Loading view (aynı)
            LoadingRecommendationView(
                progress: $viewModel.recommendationProgress,
                statusMessage: $viewModel.recommendationStatusMessage,
                isComplete: $viewModel.recommendationComplete,
                navigateToMainScreen: $viewModel.navigateToMainScreen
            )
        }
        // ✅ YENİ: Skip alert güncellendi
        .alert(L("onboarding.skip.title", table: "Onboarding"), isPresented: $showSkipAlert) {
            Button(L("onboarding.skip.confirm", table: "Onboarding"), role: .destructive) {
                Task {
                    // Mevcut skip logic
                    await viewModel.skipOnboarding()
                    
                    // ✅ YENİ: Circular transition başlat
                    await MainActor.run {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            startSkipTransition = true
                        }
                    }
                }
            }
            Button(L("general.cancel", table: "Common"), role: .cancel) {}
        } message: {
            Text(L("onboarding.skip.message", table: "Onboarding"))
        }
        .alert(L("general.error", table: "Common"), isPresented: $viewModel.showError) {
            Button(L("general.ok", table: "Common"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
                .font(PSTypography.body)
        }
    }
    
    // ✅ YENİ: Skip sonrası hedef ekran
    private var mainScreenAfterSkip: some View {
        VStack {
            Text("Ana Ekran")
                .font(.largeTitle)
                .padding()
            
            Text("Onboarding başarıyla atlandı!")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .onAppear {
            // Completion notification
            NotificationCenter.default.post(
                name: NSNotification.Name("OnboardingCompleted"),
                object: nil
            )
        }
    }
}

#Preview {
    OnboardingViewUpdatedExample()
}

/*
ÖZET:
1. 2 yeni @State değişkeni ekle
2. Skip butonuna position tracking ekle  
3. Ana content'i ayrı computed property'ye taşı
4. Circular transition wrapper ekle
5. Destination view oluştur
6. Skip alert'i güncelle

Animasyon süreleri tamamen aynı:
- Button fade out: 0.3s
- Primary circle delay: 0.2s  
- Primary circle animation: 0.7s
- Background circle delay: 0.8s
- Background circle animation: 0.7s
- Destination fade in delay: 1.4s
- Destination fade in: 0.6s

Skip butonu sağ üstten (navigation bar'dan) animasyon başlar ve
aynı timing ile ana ekrana geçiş yapar!
*/