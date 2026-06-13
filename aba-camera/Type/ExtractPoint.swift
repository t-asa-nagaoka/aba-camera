//
//  ExtractPoint.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

enum ExtractStatus: Int {
    case none = 0
    case success = 1
    case failed = 2
}

struct ExtractPoint : ExtractPointProtocol {
    var id: Int
    var happend: Date
    var subjective: Bool?
    var status: ExtractStatus
    
    init(id: Int, happend: Date, subjective: Bool?) {
        self.id = id
        self.happend = happend
        self.subjective = subjective
        self.status = .none
    }
    
    init(id: Int, extractPoint: ExtractPointProtocol) {
        self.id = id
        self.happend = extractPoint.happend
        self.subjective = extractPoint.subjective
        self.status = .none
    }
    
    static func fetch(apiUrl: String, subjective: Bool, start: Date, end: Date) async -> [ExtractPoint]? {
        let endpoint: String = subjective ? "icon/list" : "switch-history/list"
        let query: String = "?start=" + DateHelper.toISOString(date: start) + "&end=" + DateHelper.toISOString(date: end)
        
        guard let url = URL(string: apiUrl + endpoint + query) else {
            print("-- ExtractPoint.fetch : URL Initialize Error --")
            print("url: " + apiUrl + endpoint + query)
            return nil
        }
        
        // リクエストの作成
        var request: URLRequest = .init(url: url)
        request.httpMethod = "Get"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // リクエストの送信
        guard let data = await ExtractPoint.sendRequest(request: request) else {
            return nil
        }
        
        // JSONをパース
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as! [String: Any]
            let points = jsonDict[subjective ? "icons" : "switchHistories"] as! [[String: Any]]
            var extractPoints: [ExtractPoint] = []
            
            for point in points {
                let dateString = point["date"] as! String
                let date: Date = DateHelper.fromISOString(string: dateString)
                
                let extractPoint: ExtractPoint = .init(id: 0, happend: date, subjective: subjective)
                
                extractPoints.append(extractPoint)
            }
            
            return extractPoints
        } catch {
            print("-- ExtractPoint.fetch : JSON Parse Error --")
            print("url: " + apiUrl + endpoint + query)
            print(error)
            return nil
        }
    }
    
    private static func sendRequest(request: URLRequest) async -> Data? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let response = response as? HTTPURLResponse {
                if !(200...299).contains(response.statusCode) {
                    print("-- ExtractPoint.sendRequest : Invalid Status --")
                    print("status: \(response.statusCode)")
                    return nil
                }
            }
            
            return data
        } catch {
            print("-- ExtractPoint.sendRequest : Error --")
            print("url: " + (request.url?.absoluteString ?? "nil"))
            print(error)
            return nil
        }
    }
}
