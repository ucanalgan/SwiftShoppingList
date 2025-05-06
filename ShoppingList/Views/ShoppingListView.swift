import UIKit

class ShoppingListViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var items: [ShoppingItem] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadItems()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Shopping List"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let alert = UIAlertController(title: "New Item", message: "Enter the item you want to add to your shopping list", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Item name"
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
        
        if let category = item.category, !category.isEmpty {
            content.secondaryText = category
        }
        
        cell.contentConfiguration = content
        cell.accessoryType = item.isChecked ? .checkmark : .none
        
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
} 