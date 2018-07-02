import MongoSwiftMobile
import Foundation

/**
 * A class providing the core functionality necessary to make authenticated function call requests for a particular
 * Stitch service.
 */
public protocol CoreStitchServiceClient {
    func callFunctionInternal(withName name: String, withArgs args: [BsonValue], withRequestTimeout requestTimeout: TimeInterval?) throws
    
    func callFunctionInternal<T: Decodable>(withName name: String, withArgs args: [BsonValue], withRequestTimeout requestTimeout: TimeInterval?) throws -> T
}
