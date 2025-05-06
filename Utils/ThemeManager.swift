import UIKit

// MARK: - Theme Definition
enum AppTheme: String, CaseIterable {
    case light, dark, blue, green, pink
    
    var mainColor: UIColor {
        switch self {
        case .light: return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        case .dark: return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        case .blue: return UIColor(red: 0.2, green: 0.6, blue: 0.86, alpha: 1.0)
        case .green: return UIColor(red: 0.15, green: 0.68, blue: 0.38, alpha: 1.0)
        case .pink: return UIColor(red: 0.85, green: 0.26, blue: 0.62, alpha: 1.0)
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .dark: return .white
        case .light: return .black
        case .blue, .green, .pink: return .white
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .light: return .white
        case .dark: return UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        case .blue: return UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        case .green: return UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
        case .pink: return UIColor(red: 1.0, green: 0.9, blue: 0.95, alpha: 1.0)
        }
    }
    
    var secondaryColor: UIColor {
        switch self {
        case .light: return UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        case .dark: return UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0)
        case .blue: return UIColor(red: 0.1, green: 0.4, blue: 0.7, alpha: 1.0)
        case .green: return UIColor(red: 0.05, green: 0.5, blue: 0.2, alpha: 1.0)
        case .pink: return UIColor(red: 0.7, green: 0.15, blue: 0.5, alpha: 1.0)
        }
    }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .blue: return "Blue"
        case .green: return "Green"
        case .pink: return "Pink"
        }
    }
}

// MARK: - Theme Manager
class ThemeManager {
    static let shared = ThemeManager()
    
    private init() {
        currentTheme = loadSavedTheme()
    }
    
    private let themeKey = "AppTheme"
    
    var currentTheme: AppTheme {
        didSet {
            saveTheme()
            NotificationCenter.default.post(name: .themeChanged, object: nil)
        }
    }
    
    private func loadSavedTheme() -> AppTheme {
        if let savedThemeRaw = UserDefaults.standard.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedThemeRaw) {
            return savedTheme
        }
        return .light
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    func apply(to viewController: UIViewController) {
        viewController.view.backgroundColor = currentTheme.backgroundColor
        
        // Apply to navigation bar if available
        if let navigationBar = viewController.navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = currentTheme.mainColor
            appearance.titleTextAttributes = [.foregroundColor: currentTheme.textColor]
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.tintColor = currentTheme.textColor
        }
        
        // Apply theme to tab bar if available
        if let tabBar = viewController.tabBarController?.tabBar {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = currentTheme.mainColor
            
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
            tabBar.tintColor = currentTheme.secondaryColor
        }
    }
}

extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
} 