import UIKit

class ShoppingListViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var items: [ShoppingItem] = []
    private let settingsButton = UIButton(type: .system)
    private let voiceButton = UIButton(type: .system)
    private let voiceStatusLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadItems()
        setupVoiceRecognition()
        
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
        VoiceCommandManager.shared.stopListening()
    }
    
    @objc private func themeChanged() {
        ThemeManager.shared.apply(to: self)
        tableView.reloadData()
        updateVoiceButtonAppearance()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Shopping List"
        view.backgroundColor = ThemeManager.shared.currentTheme.backgroundColor
        
        // Add button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // Settings button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped)
        )
        
        // Voice command button
        setupVoiceCommandButton()
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    private func setupVoiceCommandButton() {
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        voiceButton.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        voiceButton.tintColor = ThemeManager.shared.currentTheme.mainColor
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        
        // Voice status label
        voiceStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        voiceStatusLabel.text = "Voice: Off"
        voiceStatusLabel.textColor = ThemeManager.shared.currentTheme.textColor
        voiceStatusLabel.font = UIFont.systemFont(ofSize: 12)
        voiceStatusLabel.isHidden = true
        
        // Add to toolbar
        let voiceButtonItem = UIBarButtonItem(image: UIImage(systemName: "mic.circle.fill"), style: .plain, target: self, action: #selector(voiceButtonTapped))
        
        // Update navigation items
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped)),
            UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditingMode)),
            voiceButtonItem
        ]
    }
    
    private func updateVoiceButtonAppearance() {
        let imageName = VoiceCommandManager.shared.isListening ? "mic.fill" : "mic"
        navigationItem.rightBarButtonItems?[2] = UIBarButtonItem(
            image: UIImage(systemName: imageName),
            style: .plain,
            target: self,
            action: #selector(voiceButtonTapped)
        )
        
        // Update voice status label
        voiceStatusLabel.text = VoiceCommandManager.shared.isListening ? "Voice: On" : "Voice: Off"
        voiceStatusLabel.textColor = VoiceCommandManager.shared.isListening ? 
            ThemeManager.shared.currentTheme.mainColor : 
            ThemeManager.shared.currentTheme.textColor.withAlphaComponent(0.7)
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        // Enable drag and drop reordering
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        // Set editing mode
        tableView.isEditing = false
        
        // Edit/Done button
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(addButtonTapped)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(toggleEditingMode)
            )
        ]
    }
    
    // MARK: - Voice Command Setup
    private func setupVoiceRecognition() {
        VoiceCommandManager.shared.delegate = self
        
        // Request permission
        VoiceCommandManager.shared.requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            if !authorized {
                DispatchQueue.main.async {
                    self.showVoicePermissionAlert()
                }
            }
        }
    }
    
    private func showVoicePermissionAlert() {
        let alert = UIAlertController(
            title: "Speech Recognition Permission",
            message: "Please enable speech recognition in Settings to use voice commands.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func voiceButtonTapped() {
        VoiceCommandManager.shared.toggleListening()
        updateVoiceButtonAppearance()
    }
    
    @objc private func toggleEditingMode() {
        tableView.isEditing = !tableView.isEditing
        
        // Change the button based on editing state
        let editButton = UIBarButtonItem(
            barButtonSystemItem: tableView.isEditing ? .done : .edit,
            target: self,
            action: #selector(toggleEditingMode)
        )
        
        // Keep voice button when updating the edit button
        let voiceButtonItem = navigationItem.rightBarButtonItems?[2]
        
        navigationItem.rightBarButtonItems = [
            navigationItem.rightBarButtonItems![0],
            editButton,
            voiceButtonItem
        ].compactMap { $0 }
    }
    
    @objc private func settingsButtonTapped() {
        let themeSettingsVC = ThemeSettingsViewController()
        navigationController?.pushViewController(themeSettingsVC, animated: true)
    }
    
    @objc private func addButtonTapped() {
        showAddItemAlert()
    }
    
    private func showAddItemAlert(withItemName itemName: String? = nil) {
        let alert = UIAlertController(title: "New Item", message: "Enter the item you want to add to your shopping list", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Item name"
            if let itemName = itemName {
                textField.text = itemName
            }
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Item category (optional)"
        }
        
        let saveAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let itemName = alert.textFields?[0].text, !itemName.isEmpty else { return }
            let category = alert.textFields?[1].text
            
            let newItem = ShoppingItem(name: itemName, category: category, isChecked: false)
            self?.items.append(newItem)
            self?.tableView.reloadData()
            // Save to Core Data here
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Voice Command Handling
    private func handleAddItemCommand(_ itemName: String) {
        showAddItemAlert(withItemName: itemName)
    }
    
    private func handleDeleteItemCommand(_ itemName: String) {
        if let index = items.firstIndex(where: { $0.name.lowercased().contains(itemName.lowercased()) }) {
            items.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            // Remove from Core Data here
        }
    }
    
    private func handleCheckItemCommand(_ itemName: String) {
        if let index = items.firstIndex(where: { $0.name.lowercased().contains(itemName.lowercased()) }) {
            items[index].isChecked = true
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            // Update in Core Data here
        }
    }
    
    private func handleUncheckItemCommand(_ itemName: String) {
        if let index = items.firstIndex(where: { $0.name.lowercased().contains(itemName.lowercased()) }) {
            items[index].isChecked = false
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            // Update in Core Data here
        }
    }
    
    private func handleClearListCommand() {
        let alert = UIAlertController(
            title: "Clear List",
            message: "Are you sure you want to clear the entire shopping list?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.items.removeAll()
            self?.tableView.reloadData()
            // Clear Core Data here
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Data Management
    private func loadItems() {
        // Fetch from Core Data here
        // Sample data for now
        items = [
            ShoppingItem(name: "Bread", category: "Bakery", isChecked: false),
            ShoppingItem(name: "Milk", category: "Dairy", isChecked: false),
            ShoppingItem(name: "Apple", category: "Fruit", isChecked: false),
            ShoppingItem(name: "Tomato", category: "Vegetable", isChecked: false)
        ]
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate
extension ShoppingListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = item.name
        content.textProperties.color = ThemeManager.shared.currentTheme.textColor
        
        if let category = item.category, !category.isEmpty {
            content.secondaryText = category
            content.secondaryTextProperties.color = ThemeManager.shared.currentTheme.textColor.withAlphaComponent(0.7)
        }
        
        cell.contentConfiguration = content
        cell.accessoryType = item.isChecked ? .checkmark : .none
        cell.backgroundColor = ThemeManager.shared.currentTheme.backgroundColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].isChecked.toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        // Update Core Data here
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            // Delete from Core Data here
        }
    }
    
    // Support moving rows
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Reorder the data source
        let movedItem = items.remove(at: sourceIndexPath.row)
        items.insert(movedItem, at: destinationIndexPath.row)
        
        // Update Core Data here to save the new order
    }
}

// MARK: - UITableViewDragDelegate
extension ShoppingListViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = items[indexPath.row]
        let itemProvider = NSItemProvider(object: item.name as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
}

// MARK: - UITableViewDropDelegate
extension ShoppingListViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // Allow moving items within this table
        if session.localDragSession != nil {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UITableViewDropProposal(operation: .forbidden)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        // Handle one item at a time
        for dropItem in coordinator.items {
            guard let sourceIndexPath = dropItem.sourceIndexPath else { continue }
            
            // Update the data model
            let movedItem = items.remove(at: sourceIndexPath.row)
            items.insert(movedItem, at: destinationIndexPath.row)
            
            // Update the tableView
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            
            // Update Core Data here to save the new order
        }
    }
}

// MARK: - VoiceCommandDelegate
extension ShoppingListViewController: VoiceCommandDelegate {
    func voiceCommandDetected(_ command: VoiceCommandType) {
        switch command {
        case .addItem(let itemName):
            handleAddItemCommand(itemName)
        case .deleteItem(let itemName):
            handleDeleteItemCommand(itemName)
        case .checkItem(let itemName):
            handleCheckItemCommand(itemName)
        case .uncheckItem(let itemName):
            handleUncheckItemCommand(itemName)
        case .clearList:
            handleClearListCommand()
        case .showChecked:
            // Implementation for showing checked items
            break
        case .hideChecked:
            // Implementation for hiding checked items
            break
        case .unknown:
            break
        }
    }
    
    func voiceRecognitionStatusChanged(isActive: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.updateVoiceButtonAppearance()
        }
    }
    
    func voiceRecognitionError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showErrorAlert(message: error.localizedDescription)
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Voice Recognition Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
} 