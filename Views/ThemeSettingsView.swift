import UIKit

class ThemeSettingsViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        // Register for theme updates
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(themeChanged),
                                              name: .themeChanged,
                                              object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ThemeManager.shared.apply(to: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func themeChanged() {
        ThemeManager.shared.apply(to: self)
        tableView.reloadData()
    }
    
    private func setupUI() {
        title = "Theme Settings"
        view.backgroundColor = ThemeManager.shared.currentTheme.backgroundColor
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ThemeCell")
        tableView.backgroundColor = ThemeManager.shared.currentTheme.backgroundColor
    }
}

extension ThemeSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppTheme.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeCell", for: indexPath)
        let theme = AppTheme.allCases[indexPath.row]
        
        // Configure the cell
        var configuration = cell.defaultContentConfiguration()
        configuration.text = theme.displayName
        
        // Add a colored circle view to show the theme color
        let circleSize: CGFloat = 24
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: circleSize, height: circleSize))
        circleView.backgroundColor = theme.mainColor
        circleView.layer.cornerRadius = circleSize / 2
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        containerView.addSubview(circleView)
        circleView.center = containerView.center
        
        cell.accessoryView = containerView
        
        // Show checkmark for selected theme
        if theme == ThemeManager.shared.currentTheme {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        // Apply current theme to cell
        configuration.textProperties.color = ThemeManager.shared.currentTheme.textColor
        cell.backgroundColor = ThemeManager.shared.currentTheme.backgroundColor
        cell.contentConfiguration = configuration
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedTheme = AppTheme.allCases[indexPath.row]
        ThemeManager.shared.currentTheme = selectedTheme
        
        // The themeChanged notification will trigger UI updates
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select Theme"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Choose your preferred app appearance"
    }
} 