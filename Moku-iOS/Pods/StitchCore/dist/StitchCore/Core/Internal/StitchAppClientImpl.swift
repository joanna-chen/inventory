import StitchCoreSDK
import MongoSwiftMobile
import Foundation

/**
 * The implementation of the `StitchAppClient` protocol.
 */
internal final class StitchAppClientImpl: StitchAppClient {

    // MARK: Properties

    /**
     * The client's underlying authentication state, publicly exposed as a `StitchAuth` interface.
     */
    public var auth: StitchAuth {
        return _auth
    }

    /**
     * The client's underlying push notification component.
     */
    public var push: StitchPush

    /**
     * The client's underlying authentication state.
     */
    private var _auth: StitchAuthImpl

    /**
     * The core `CoreStitchAppClient` used by the client to make function call requests.
     */
    private let coreClient: CoreStitchAppClient

    /**
     * The operation dispatcher used to dispatch asynchronous operations made by this client and its underlying
     * objects.
     */
    private let dispatcher: OperationDispatcher

    /**
     * A `StitchAppClientInfo` describing the basic properties of this app client.
     */
    internal let info: StitchAppClientInfo

    /**
     * The API routes on the Stitch server to perform actions for this particular app.
     */
    private let routes: StitchAppRoutes

    // MARK: Initializer

    /**
     * Initializes the app client with the provided configuration, and with an operation dispatcher that runs on
     * the provided `DispatchQueue` (the default global `DispatchQueue` by default).
     */
    public init(withClientAppID clientAppID: String,
                withConfig config: ImmutableStitchAppClientConfiguration,
                withDispatchQueue queue: DispatchQueue = DispatchQueue.global()) throws {
        self.dispatcher = OperationDispatcher.init(withDispatchQueue: queue)
        self.routes = StitchAppRoutes.init(clientAppID: clientAppID)
        self.info = StitchAppClientInfo(clientAppID: clientAppID,
                                        dataDirectory: config.dataDirectory,
                                        localAppName: config.localAppName,
                                        localAppVersion: config.localAppVersion
        )

        let internalAuth =
            try StitchAuthImpl.init(
                requestClient: StitchRequestClientImpl.init(baseURL: config.baseURL,
                                                            transport: config.transport,
                                                            defaultRequestTimeout: config.defaultRequestTimeout),
                authRoutes: self.routes.authRoutes,
                storage: config.storage,
                dispatcher: self.dispatcher,
                appInfo: self.info)

        self._auth = internalAuth
        self.push = StitchPushImpl.init(
            requestClient: self._auth,
            pushRoutes: self.routes.pushRoutes,
            dispatcher: self.dispatcher
        )
        self.coreClient = CoreStitchAppClient.init(authRequestClient: internalAuth, routes: routes)
    }

    // MARK: Services

    /**
     * Retrieves the service client associated with the Stitch service with the specified name and type.
     *
     * - parameters:
     *     - fromFactory: An `AnyNamedServiceClientFactory` object which contains a `NamedServiceClientFactory`
     *                    class which will provide the client for this service.
     *     - withName: The name of the service as defined in the MongoDB Stitch application.
     * - returns: a service client whose type is determined by the `T` type parameter of the
     *            `AnyNamedServiceClientFactory` passed in the `fromFactory` parameter.
     */
    public func serviceClient<T>(fromFactory factory: AnyNamedServiceClientFactory<T>,
                                 withName serviceName: String) -> T {
        return factory.client(
            forService: StitchServiceClientImpl.init(requestClient: self._auth,
                                                     routes: self.routes.serviceRoutes,
                                                     name: serviceName, dispatcher: self.dispatcher),
            withClientInfo: self.info
        )
    }

    /**
     * Retrieves the service client associated with the service type specified in the argument.
     *
     * - parameters:
     *     - fromFactory: An `AnyServiceClientProvider` object which contains a `ServiceClientFactory`
     *                    class which will provide the client for this service.
     * - returns: a service client whose type is determined by the `T` type parameter of the
     *            `AnyNamedServiceClientFactory` passed in the `fromFactory` parameter.
     */
    public func serviceClient<T>(fromFactory factory: AnyNamedServiceClientFactory<T>) -> T {
        return factory.client(
            forService: StitchServiceClientImpl.init(requestClient: self._auth,
                                                     routes: self.routes.serviceRoutes,
                                                     name: "", dispatcher: self.dispatcher),
            withClientInfo: self.info
        )
    }

    /**
     * Retrieves the service client associated with the service type specified in the argument.
     *
     * - parameters:
     *     - fromFactory: An `AnyThrowingServiceClientFactory` object which contains a `ThrowingServiceClientFactory`
     *                    class which will provide the client for this service.
     * - returns: a service client whose type is determined by the `T` type parameter of the
     *            `AnyThrowingServiceClientFactory` passed in the `fromFactory` parameter.
     */
    public func serviceClient<T>(fromFactory factory: AnyThrowingServiceClientFactory<T>) throws -> T {
        return try factory.client(
            forService: StitchServiceClientImpl.init(requestClient: self._auth,
                                                     routes: self.routes.serviceRoutes,
                                                     name: "", dispatcher: self.dispatcher),
            withClientInfo: self.info
        )
    }

    // MARK: Functions
    /**
     * Calls the MongoDB Stitch function with the provided name and arguments.
     *
     * - parameters:
     *     - withName: The name of the Stitch function to be called.
     *     - withArgs: The `BSONArray` of arguments to be provided to the function.
     *     - completionHandler: The completion handler to call when the function call is complete.
     *                          This handler is executed on a non-main global `DispatchQueue`.
     */
    public func callFunction(withName name: String,
                             withArgs args: [BsonValue],
                             _ completionHandler: @escaping (StitchResult<Void>) -> Void) {
        self.dispatcher.run(withCompletionHandler: completionHandler) {
            return try self.coreClient.callFunctionInternal(withName: name, withArgs: args)
        }
    }

    /**
     * Calls the MongoDB Stitch function with the provided name and arguments, and decodes the result of the function
     * into a `Decodable` type as specified by the `T` type parameter.
     *
     * - parameters:
     *     - withName: The name of the Stitch function to be called.
     *     - withArgs: The `BSONArray` of arguments to be provided to the function.
     *     - completionHandler: The completion handler to call when the function call is complete.
     *                          This handler is executed on a non-main global `DispatchQueue`. If the operation is
     *                          successful, the result will contain a `T` representing the decoded result of the
     *                          function call.
     *
     */
    public func callFunction<T: Decodable>(withName name: String,
                                           withArgs args: [BsonValue],
                                           _ completionHandler: @escaping (StitchResult<T>) -> Void) {
        dispatcher.run(withCompletionHandler: completionHandler) {
            return try self.coreClient.callFunctionInternal(withName: name,
                                                            withArgs: args)
        }
    }

    /**
     * Calls the MongoDB Stitch function with the provided name and arguments. Also accepts a timeout. Use this for
     * function that may run longer than the client-wide default timeout (15 seconds by default).
     *
     * - parameters:
     *     - withName: The name of the Stitch function to be called.
     *     - withArgs: The `BSONArray` of arguments to be provided to the function.
     *     - withRequestTimeout: The number of seconds the client should wait for a response from the server before
     *                           failing with an error.
     *     - completionHandler: The completion handler to call when the function call is complete.
     *                          This handler is executed on a non-main global `DispatchQueue`.
     *
     */
    public func callFunction(withName name: String,
                             withArgs args: [BsonValue],
                             withRequestTimeout requestTimeout: TimeInterval,
                             _ completionHandler: @escaping (StitchResult<Void>) -> Void) {
        self.dispatcher.run(withCompletionHandler: completionHandler) {
            return try self.coreClient.callFunctionInternal(withName: name,
                                                            withArgs: args,
                                                            withRequestTimeout: requestTimeout
            )
        }
    }

    /**
     * Calls the MongoDB Stitch function with the provided name and arguments, and decodes the result of the function
     * into a `Decodable` type as specified by the `T` type parameter. Also accepts a timeout. Use this for functions
     * that may run longer than the client-wide default timeout (15 seconds by default).
     *
     * - parameters:
     *     - withName: The name of the Stitch function to be called.
     *     - withArgs: The `BSONArray` of arguments to be provided to the function.
     *     - withRequestTimeout: The number of seconds the client should wait for a response from the server before
     *                           failing with an error.
     *     - completionHandler: The completion handler to call when the function call is complete.
     *                          This handler is executed on a non-main global `DispatchQueue`. If the operation is
     *                          successful, the result will contain a `T` representing the decoded result of the
     *                          function call.
     */
    public func callFunction<T: Decodable>(withName name: String,
                                           withArgs args: [BsonValue],
                                           withRequestTimeout requestTimeout: TimeInterval,
                                           _ completionHandler: @escaping (StitchResult<T>) -> Void) {
        dispatcher.run(withCompletionHandler: completionHandler) {
            return try self.coreClient.callFunctionInternal(withName: name,
                                                            withArgs: args,
                                                            withRequestTimeout: requestTimeout)
        }
    }
}
