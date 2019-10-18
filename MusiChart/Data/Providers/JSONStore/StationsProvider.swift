import UIKit

protocol StationsProviding {
    func getStationDataWithSuccess(success: @escaping ((_ metaData: Data?) -> Void))
}

final class StationsProvider: NSObject, StationsProviding {

    // MARK: - Load Stations

    func getStationDataWithSuccess(success: @escaping ((_ metaData: Data?) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {

            // Load stations data from a remote webserver
            guard let url = URL(string: stationDataURL) else { return }
            self.loadDataFromURL(url: url) { [weak self] data, _ in
                if let urlData = data {
                    success(urlData)
                } else {
                    // Load local stations data
                    self?.getDataFromFileWithSuccess { data in
                        success(data)
                    }
                }
            }
        }
    }

    // MARK: - Load local JSON Data
    
    private func getDataFromFileWithSuccess(success: (_ data: Data) -> Void) {

        if let filePath = Bundle.main.path(forResource: "stations", ofType: "json") {
            do {
                let data = try NSData(contentsOfFile: filePath,
                    options: NSData.ReadingOptions.uncached) as Data
                success(data)
            } catch {
                fatalError()
            }
        } else {
            print("The local JSON file could not be found")
        }
    }
    
    // MARK: - Load Remote Data

    private func loadDataFromURL(url: URL, completion:@escaping (_ data: Data?, _ error: Error?) -> Void) {

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.allowsCellularAccess          = true
        sessionConfig.timeoutIntervalForRequest     = 15
        sessionConfig.timeoutIntervalForResource    = 30
        sessionConfig.httpMaximumConnectionsPerHost = 1

        let session = URLSession(configuration: sessionConfig)

        // Use NSURLSession to get data from an NSURL
        let loadDataTask = session.dataTask(with: url) { data, response, error in
            
            if let responseError = error {
                
                print("API ERROR: \(String(describing: error))")
                completion(nil, responseError)
                
            } else if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode != 200 {
                    
                    let statusError = NSError(domain: "com.google",
                                              code: httpResponse.statusCode,
                                              userInfo: [NSLocalizedDescriptionKey: "HTTP status code has unexpected value."])
                    print("API: HTTP status code has unexpected value")
                    completion(nil, statusError)
                    
                } else {
                    // Success, return data
                    completion(data, nil)
                }
            }
        }

        loadDataTask.resume()
    }

    // Check if file exist at the given URL
    private func fileExistsAt(url: URL, completion: @escaping (Bool) -> Void) {
        
        let checkSession = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 1.0 // Adjust to your needs

        let task = checkSession.dataTask(with: request as URLRequest, completionHandler: { (_, response, _) -> Void in
            if let httpResp: HTTPURLResponse = response as? HTTPURLResponse {
                completion(httpResp.statusCode != 400)
            } else {
                completion(true) //for servers without specified httpMethod on the website; response will be nil
            }
        })

        task.resume()
    }
}
