public class Item {
    public init(name: String = "Random") {
        self.name = name
    }
    
    private(set) var name: String = ""
}
