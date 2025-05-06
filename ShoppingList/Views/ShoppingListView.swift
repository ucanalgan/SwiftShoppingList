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
        title = "Alışveriş Listesi"
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
        let alert = UIAlertController(title: "Yeni Ürün", message: "Alışveriş listenize eklemek istediğiniz ürünü girin", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Ürün adı"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Ürün kategorisi (isteğe bağlı)"
        }
        
        let saveAction = UIAlertAction(title: "Ekle", style: .default) { [weak self] _ in
            guard let itemName = alert.textFields?[0].text, !itemName.isEmpty else { return }
            let category = alert.textFields?[1].text
            
            let newItem = ShoppingItem(name: itemName, category: category, isChecked: false)
            self?.items.append(newItem)
            self?.tableView.reloadData()
            // Burada Core Data'ya kaydetme işlemi yapılacak
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Data Management
    private func loadItems() {
        // Burada Core Data'dan veri çekme işlemi yapılacak
        // Şimdilik örnek veriler
        items = [
            ShoppingItem(name: "Ekmek", category: "Fırın", isChecked: false),
            ShoppingItem(name: "Süt", category: "Süt Ürünleri", isChecked: false),
            ShoppingItem(name: "Elma", category: "Meyve", isChecked: false),
            ShoppingItem(name: "Domates", category: "Sebze", isChecked: false)
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
        // Burada Core Data güncelleme işlemi yapılacak
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            // Burada Core Data silme işlemi yapılacak
        }
    }
} 