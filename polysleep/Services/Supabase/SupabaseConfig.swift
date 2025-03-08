import Foundation

/// Supabase konfigürasyon bilgileri
enum SupabaseConfig {
    /// Supabase URL
    static let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://zbujftmhbgqpeidmnzra.supabase.co"
    
    /// Supabase API anahtarı
    static let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_API_KEY"] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpidWpmdG1oYmdxcGVpZG1uenJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4MzY4MzMsImV4cCI6MjA1NjQxMjgzM30.xJjen3v3dpNjmU24rk5tubEa2jMh6cTQ2GucNOHB31w"
}
