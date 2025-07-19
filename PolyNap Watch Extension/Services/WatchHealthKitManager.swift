import Foundation
import HealthKit
import OSLog

@MainActor
class WatchHealthKitManager: ObservableObject {
    static let shared = WatchHealthKitManager()
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.polynap.healthkit", category: "WatchHealthKitManager")
    
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isHealthDataAvailable: Bool = false
    
    private init() {
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        Task {
            await checkInitialAuthorizationStatus()
        }
    }
    
    // MARK: - Data Types
    
    private var readTypes: Set<HKObjectType> {
        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type for reading")
            return Set()
        }
        return [sleepAnalysisType]
    }
    
    private var shareTypes: Set<HKSampleType> {
        guard let sleepAnalysisType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type for sharing")
            return Set()
        }
        return [sleepAnalysisType]
    }
    
    // MARK: - Authorization
    
    private func checkInitialAuthorizationStatus() async {
        guard isHealthDataAvailable else { return }
        
        await getAuthorizationStatus { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }
    
    func requestAuthorization() async -> Result<Bool, WatchHealthKitError> {
        guard isHealthDataAvailable else {
            logger.error("HealthKit is not available on this device")
            return .failure(.healthKitNotAvailable)
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            
            return await withCheckedContinuation { continuation in
                getAuthorizationStatus { [weak self] status in
                    DispatchQueue.main.async {
                        self?.authorizationStatus = status
                    }
                    
                    switch status {
                    case .sharingAuthorized:
                        self?.logger.info("HealthKit authorization granted")
                        continuation.resume(returning: .success(true))
                    case .sharingDenied:
                        self?.logger.warning("HealthKit authorization denied")
                        continuation.resume(returning: .failure(.authorizationDenied))
                    default:
                        self?.logger.warning("HealthKit authorization status undetermined")
                        continuation.resume(returning: .failure(.authorizationNotDetermined))
                    }
                }
            }
        } catch {
            logger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
            return .failure(.requestFailed(error))
        }
    }
    
    func getAuthorizationStatus(completion: @escaping (HKAuthorizationStatus) -> Void) {
        guard let sleepType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type for authorization check")
            completion(.notDetermined)
            return
        }
        
        let status = healthStore.authorizationStatus(for: sleepType)
        completion(status)
    }
    
    // MARK: - Sleep Data Writing
    
    func saveSleepAnalysis(
        startDate: Date,
        endDate: Date,
        sleepType: WatchSleepAnalysisType = .asleep
    ) async -> Result<Void, WatchHealthKitError> {
        guard isHealthDataAvailable else {
            return .failure(.healthKitNotAvailable)
        }
        
        guard authorizationStatus == .sharingAuthorized else {
            return .failure(.authorizationDenied)
        }
        
        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type")
            return .failure(.invalidDataType)
        }
        
        // Create sleep sample
        let sleepSample = HKCategorySample(
            type: sleepAnalysisType,
            value: sleepType.healthKitValue,
            start: startDate,
            end: endDate
        )
        
        do {
            try await healthStore.save(sleepSample)
            logger.info("Successfully saved sleep analysis to HealthKit: \(startDate) - \(endDate)")
            return .success(())
        } catch {
            logger.error("Failed to save sleep analysis: \(error.localizedDescription)")
            return .failure(.saveFailed(error))
        }
    }
}

// MARK: - Supporting Types

enum WatchHealthKitError: LocalizedError {
    case healthKitNotAvailable
    case authorizationDenied
    case authorizationNotDetermined
    case requestFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case invalidDataType
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit bu cihazda kullanılamıyor"
        case .authorizationDenied:
            return "HealthKit erişim izni reddedildi"
        case .authorizationNotDetermined:
            return "HealthKit erişim izni henüz belirlenmedi"
        case .requestFailed(let error):
            return "İzin isteği başarısız: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Veri kaydetme başarısız: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Veri çekme başarısız: \(error.localizedDescription)"
        case .invalidDataType:
            return "Geçersiz veri tipi"
        }
    }
}

enum WatchSleepAnalysisType: CaseIterable {
    case inBed
    case asleep
    case awake
    case core
    case deep
    case rem
    
    var healthKitValue: Int {
        switch self {
        case .inBed:
            return HKCategoryValueSleepAnalysis.inBed.rawValue
        case .asleep:
            return HKCategoryValueSleepAnalysis.asleep.rawValue
        case .awake:
            return HKCategoryValueSleepAnalysis.awake.rawValue
        case .core:
            if #available(watchOS 9.0, *) {
                return HKCategoryValueSleepAnalysis.asleepCore.rawValue
            } else {
                return HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        case .deep:
            if #available(watchOS 9.0, *) {
                return HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            } else {
                return HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        case .rem:
            if #available(watchOS 9.0, *) {
                return HKCategoryValueSleepAnalysis.asleepREM.rawValue
            } else {
                return HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        }
    }
    
    init?(healthKitValue: Int) {
        if #available(watchOS 9.0, *) {
            switch healthKitValue {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                self = .inBed
            case HKCategoryValueSleepAnalysis.asleep.rawValue:
                self = .asleep
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                self = .awake
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                self = .core
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                self = .deep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                self = .rem
            default:
                return nil
            }
        } else {
            switch healthKitValue {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                self = .inBed
            case HKCategoryValueSleepAnalysis.asleep.rawValue:
                self = .asleep
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                self = .awake
            default:
                return nil
            }
        }
    }
    
    var displayName: String {
        switch self {
        case .inBed:
            return "Yatakta"
        case .asleep:
            return "Uykuda"
        case .awake:
            return "Uyanık"
        case .core:
            return "Hafif Uyku"
        case .deep:
            return "Derin Uyku"
        case .rem:
            return "REM Uyku"
        }
    }
}