import MongoSwiftMobile
import StitchCoreSDK
import Foundation

/**
 * A protocol representing a MongoDB Stitch service, with methods for executing functions on that service.
 * A class implementing this protocol for a service with known functions and return values may implement
 * concrete methods that use these methods internally.
 */
public protocol StitchServiceClient: CoreStitchServiceClient {

    // swiftlint:disable line_length

    /**
     * Calls the MongoDB Stitch function with the provided name and arguments. Also accepts a timeout. Use this for
     * function that may run longer than the client-wide default timeout (15 seconds by default).
     *
     * - parameters:
     *     - withName: The name of the Stitch function to be called.
     *     - withArgs: The `BSONArray` of arguments to be provided to the function.
     *     - completionHandler: The completion handler to call when the function call is complete.
     *                          This handler is executed on a non-main global `DispatchQueue`.
     *
     */
    func callFunction(withName name: String, withArgs args: [BsonValue], withRequestTimeout requestTimeout: TimeInterval, _ completionHandler: @escaping (StitchResult<Void>) -> Void)

    /**
     * Calls the function for this service with the provided name and arguments, as well as with a specified timeout.
     * Use this for functions that may run longer than the client-wide default timeout (15 seconds by default).
     *
     * - parameters:
     *     - withName: The name of the function to be called.
     *     - withArgs: The `BSONArray` of arguments to be provided to the function.
     *     - withRequestTimeout: The number of seconds the client should wait for a response from the server before
     *                           failing with an error.
     *     - completionHandler: The completion handler to call when the function call is complete.
     *                          This handler is executed on a non-main global `DispatchQueue`.
     *     - result: The result of the function call as `T`, or `nil` if the function call failed.
     *     - error: An error object that indicates why the function call failed, or `nil` if the function call was
     *              successful.
     *
     */
    func callFunction<T: Decodable>(withName name: String, withArgs args: [BsonValue], withRequestTimeout requestTimeout: TimeInterval, _ completionHandler: @escaping (StitchResult<T>) -> Void)
    // swiftlint:enable line_length
}
