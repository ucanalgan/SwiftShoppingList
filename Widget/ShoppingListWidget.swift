import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct ShoppingListEntry: TimelineEntry {
    let date: Date
    let items: [ShoppingItem]
}

// MARK: - Provider
struct ShoppingListProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShoppingListEntry {
        ShoppingListEntry(
            date: Date(),
            items: [
                ShoppingItem(name: "Bread", category: "Bakery", isChecked: false),
                ShoppingItem(name: "Milk", category: "Dairy", isChecked: true),
                ShoppingItem(name: "Eggs", category: "Dairy", isChecked: false)
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ShoppingListEntry) -> Void) {
        let entry = ShoppingListEntry(
            date: Date(),
            items: [
                ShoppingItem(name: "Bread", category: "Bakery", isChecked: false),
                ShoppingItem(name: "Milk", category: "Dairy", isChecked: true),
                ShoppingItem(name: "Eggs", category: "Dairy", isChecked: false),
                ShoppingItem(name: "Coffee", category: "Beverages", isChecked: false)
            ]
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ShoppingListEntry>) -> Void) {
        // In a real implementation, fetch data from CoreData
        // For now, use sample data
        let currentDate = Date()
        let items = [
            ShoppingItem(name: "Bread", category: "Bakery", isChecked: false),
            ShoppingItem(name: "Milk", category: "Dairy", isChecked: true),
            ShoppingItem(name: "Eggs", category: "Dairy", isChecked: false),
            ShoppingItem(name: "Coffee", category: "Beverages", isChecked: false),
            ShoppingItem(name: "Apples", category: "Fruit", isChecked: false)
        ]
        
        let entry = ShoppingListEntry(date: currentDate, items: items)
        
        // Refresh every hour
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}

// MARK: - Widget View
struct ShoppingListWidgetEntryView: View {
    var entry: ShoppingListProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Shopping List")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(uncheckedItemsCount) left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)
            
            if entry.items.isEmpty {
                Text("Your shopping list is empty")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
            } else {
                itemsList
            }
        }
        .padding()
    }
    
    var itemsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(itemsToShow) { item in
                HStack {
                    Circle()
                        .fill(item.isChecked ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 14, height: 14)
                    
                    Text(item.name)
                        .font(.system(size: 14))
                        .foregroundColor(item.isChecked ? .secondary : .primary)
                        .strikethrough(item.isChecked)
                    
                    Spacer()
                    
                    if let category = item.category, !category.isEmpty {
                        Text(category)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if entry.items.count > maxItemsToShow {
                Text("+ \(entry.items.count - maxItemsToShow) more...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
    
    var maxItemsToShow: Int {
        switch widgetFamily {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 5
        case .systemLarge:
            return 10
        default:
            return 3
        }
    }
    
    var itemsToShow: [ShoppingItem] {
        // Show unchecked items first
        let sortedItems = entry.items.sorted { 
            if $0.isChecked == $1.isChecked {
                return true
            }
            return !$0.isChecked && $1.isChecked
        }
        
        return Array(sortedItems.prefix(maxItemsToShow))
    }
    
    var uncheckedItemsCount: Int {
        entry.items.filter { !$0.isChecked }.count
    }
}

// MARK: - Widget Configuration
struct ShoppingListWidget: Widget {
    private let kind = "ShoppingListWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: ShoppingListProvider()
        ) { entry in
            ShoppingListWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Shopping List")
        .description("Quickly see your shopping list items.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Extensions
extension ShoppingItem: Identifiable {
    var id: String {
        return UUID().uuidString
    }
}

// MARK: - Preview
struct ShoppingListWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = ShoppingListEntry(
            date: Date(),
            items: [
                ShoppingItem(name: "Bread", category: "Bakery", isChecked: false),
                ShoppingItem(name: "Milk", category: "Dairy", isChecked: true),
                ShoppingItem(name: "Eggs", category: "Dairy", isChecked: false),
                ShoppingItem(name: "Coffee", category: "Beverages", isChecked: false),
                ShoppingItem(name: "Apples", category: "Fruit", isChecked: false)
            ]
        )
        
        return Group {
            ShoppingListWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            ShoppingListWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            ShoppingListWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
} 