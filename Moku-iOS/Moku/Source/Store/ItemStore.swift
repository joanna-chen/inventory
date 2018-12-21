import Observable

public class ItemStore {
    // Singleton instance of the item store
    static let store = ItemStore()
    
    let change: Observable<[Item]>
    var items: [Item]
    
    private init() {
        items = []
        change = Observable(items)
    }
}
