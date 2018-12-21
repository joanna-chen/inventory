import Alamofire

public class MokuAPI {
    static func getUsers() {
        Alamofire.request(MokuRoutes.get_users).responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
        
            if let json = response.result.value {
            print("JSON: \(json)") // serialized json response
            }
        
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
            print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }
    
    static func getItems() {
        Alamofire.request(MokuRoutes.get_items).responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let resp = response.result.value as? Dictionary<String,[Dictionary<String, String>]> {
                let itemsDic = resp["items"]
                var items: [Item] = []
                for dic in itemsDic! {
                    if let name = dic["name"] {
                        items.append(Item(name: name))
                    }
                }
                ItemStore.store.change.value = items
                ItemStore.store.items = items
            }
        }
    }
}
