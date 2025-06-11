import Foundation

/// Repository işlemleri için hata türleri
enum RepositoryError: Error {
    case modelContextNotSet
    case userNotAuthenticated
    case invalidData
    case saveFailed
    case deleteFailed
    case fetchFailed
    case updateFailed
    case entityNotFound
    case noUndoDataAvailable
    case undoExpired
}

/// RepositoryError için yerelleştirilmiş açıklamalar
extension RepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .modelContextNotSet:
            return "Model context ayarlanmamış"
        case .userNotAuthenticated:
            return "Kullanıcı kimlik doğrulaması yapılmamış"
        case .invalidData:
            return "Geçersiz veri"
        case .saveFailed:
            return "Kaydetme işlemi başarısız"
        case .deleteFailed:
            return "Silme işlemi başarısız"
        case .fetchFailed:
            return "Veri getirme işlemi başarısız"
        case .updateFailed:
            return "Güncelleme işlemi başarısız"
        case .entityNotFound:
            return "Varlık bulunamadı"
        case .noUndoDataAvailable:
            return "Geri alma verisi bulunamadı"
        case .undoExpired:
            return "Geri alma süresi dolmuş"
        }
    }
} 