
import Foundation

public protocol PNetworker {
    var environment: PEnvironment { get }
    func request<T: Model>(endpoint: PEndpoint, model: T.Type, completion: @escaping (PNetworkResponse<T>) -> Void)
}

public class PNetwork: PNetworker {
    
    public var sessionConfig: URLSessionConfiguration?
    
    private let session: URLSessionProtocol
    private let debugMode: Bool
    
    public let environment: PEnvironment
    
    public init(environment: PEnvironment, session: URLSessionProtocol = URLSession.shared, debugMode: Bool = false) {
        self.environment = environment
        self.session = session
        self.debugMode = debugMode
    }
    
    private func processResponse<T: Model>(response: URLResponse?, data: Data?, error: Error?, endpoint: PEndpoint, model: T.Type, completion: @escaping (PNetworkResponse<T>) -> Void) {
        
        //Check Response
        let callbackResponse = checkResponse(response: response, error: error, model: model)
        
        //return if have error
        guard callbackResponse.error == nil else {
            completion(callbackResponse)
            return
        }
        
        //Serialize data
        serializeData(endpoint: endpoint, data: data, callbackResponse: callbackResponse, model: model, completion: completion)
        
    }
    
    private func checkResponse<T: Model>(response: URLResponse?, error: Error?, model: T.Type) -> PNetworkResponse<T> {
        var callbackResponse: PNetworkResponse<T> = noneResponse(model: model)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            callbackResponse.error = PNetworkError.noneResponse
            return callbackResponse
        }
        
        callbackResponse.statusCode = httpResponse.statusCode
        
        //if exist error
        if let error = error {
            callbackResponse.error = PNetworkError.serviceError(message: error.localizedDescription)
            return callbackResponse
        }
        
        return callbackResponse
    }
    
    private func serializeData<T: Model>(endpoint: PEndpoint, data: Data?, callbackResponse: PNetworkResponse<T>, model: T.Type, completion: @escaping (PNetworkResponse<T>) -> Void) {
        
        var response: PNetworkResponse = callbackResponse
        
        guard let data = data else {
            response.error = PNetworkError.noContent
            completion(response)
            return
        }
            
        response.raw = data.prettyJSON()
        
        //Debug
        printDebug(endpoint: endpoint, rawResponse: response.raw)
        
        if model is EmptyModel.Type {
            completion(response)
            return
        }
        
        var dataObject = data
        
        let mappedModel: (isArray: Bool, data: Data?) = mappingModel(model: model, data: data)
        
        if let mappingData = mappedModel.data {
            dataObject = mappingData
        }
        
        var modelToDecoded: Decodable?
        
        if mappedModel.isArray {
            let modelArray = [T].self
            modelToDecoded = try? JSONDecoder.init().decode(modelArray, from: dataObject)
        } else {
            modelToDecoded = try? JSONDecoder.init().decode(model, from: dataObject)
        }
        
        guard let modelDecoded = modelToDecoded else {
            response.error = .jsonParsing
            completion(response)
            return
        }
        
        response.object = modelDecoded as? T
        completion(response)
    }
    
    public func request<T: Model>(endpoint: PEndpoint, model: T.Type, completion: @escaping (PNetworkResponse<T>) -> Void) {
        
        guard let request = getUrlRequest(endpoint: endpoint) else {
            var response: PNetworkResponse = noneResponse(model: model)
            response.error = .invalidUrl
            completion(response)
            return
        }
        
        session.dataTask(with: request) { [weak self] (data, response, error) in
            self?.processResponse(response: response, data: data, error: error, endpoint: endpoint, model: model, completion: completion)
        }.resume()
        
    }
    
}

extension PNetwork {
    
    private func getJson(data: Data) -> Any? {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return json
        }
        return nil
    }
    
    private func mappingModel<T: Model>(model: T.Type, data: Data) -> (isArray: Bool, data: Data?)  {
        var isArray: Bool = false
        let paths = model.mapJson()
        
        guard !paths.isEmpty, let json = getJson(data: data) as? [String: Any] else {
            return (false, nil)
        }
        
        var dictionary: Any = json
        
        paths.forEach {
            if let item = mapping(item: dictionary, path: $0) {
                dictionary = item
            }
        }
        
        isArray = (dictionary as? [Any]) != nil
        
        guard let newDataObject = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            return (false, nil)
        }
        
        return (isArray, newDataObject)
    }
    
    private func mapping(item: Any, path: String) -> Any? {
        guard let dictionary = item as? [String: Any]  else {
            return item
        }
        
        guard let obj = dictionary[path] as? [String: Any] else {
            return dictionary[path]
        }
        
        return obj
    }
    
    private func printDebug(endpoint: PEndpoint, rawResponse: String) {
        if debugMode {
            print("Path: (\(endpoint.path)")
            print("Header")
            print(endpoint.headers)
            print("Params:")
            print(endpoint.params)
            print("Response:")
            print(rawResponse)
        }
    }
    
    private func getUrlRequest(endpoint: PEndpoint) -> URLRequest? {
        guard let url = environment.getUrl(endpoint: endpoint) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        environment.defaultHeaders.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        endpoint.headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        if case .boundry(let (_, code)) = endpoint.postType  {
            request.setValue("multipart/form-data; boundary=\(code)", forHTTPHeaderField: "Content-Type")
        }
    
        if(endpoint.method == .post){
            request.httpBody = getParamsToPost(endpoint: endpoint)
        }
        
        return request
    }
    
    private func getParamsToPost(endpoint: PEndpoint) -> Data? {
        switch endpoint.postType {
        case .json:
            return getParamsToJsonPost(endpoint: endpoint)
        case .boundry(let (params, _)):
            return params
        default:
            return getParamsToPostString(endpoint: endpoint)
        }
    }
    
    // MARK: Private Methods
    private func getParamsToPostString(endpoint: PEndpoint) -> Data? {
        let array = endpoint.params.map {
            "\($0.key)=\($0.value)"
        }
        return array.joined(separator: "&").data(using: .utf8)
    }
    
    private func getParamsTo(boundry: String) -> Data? {
        boundry.data(using: .utf8)
    }
    
    private func getParamsToJsonPost(endpoint: PEndpoint) -> Data? {
        if !endpoint.params.isEmpty {
            if let data = try? JSONSerialization.data(withJSONObject: endpoint.params, options: .prettyPrinted) {
                return data
            }
        }
        return nil
    }
    
    private func noneResponse<T: Model>(model: T.Type) -> PNetworkResponse<T> {
        return PNetworkResponse<T>(
            statusCode: 0,
            object: nil,
            error: nil,
            raw: ""
        )
    }
    
}
