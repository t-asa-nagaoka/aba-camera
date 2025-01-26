//
//  SwitchHistory.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

enum SwitchHistoryExtractStatus: Int {
    case none = 0
    case success = 1
    case failed = 2
}

struct SwitchHistory : SwitchHistoryProtocol {
    var id: Int
    var happend: Date
    var subjective: Bool
    var status: SwitchHistoryExtractStatus
    
    init(id: Int, happend: Date, subjective: Bool) {
        self.id = id
        self.happend = happend
        self.subjective = subjective
        self.status = .none
    }
    
    init(id: Int, switchHistory: SwitchHistoryProtocol) {
        self.id = id
        self.happend = switchHistory.happend
        self.subjective = switchHistory.subjective
        self.status = .none
    }
    
    static func fetch(url: String, start: Date, end: Date) async -> [SwitchHistory]? {
        let query: String = "?start=" + DateHelper.toISOString(date: start) + "&end=" + DateHelper.toISOString(date: end)
        
        guard let endpoint = URL(string: url + query) else {
            print("-- SwitchHistory.fetch : URL Initialize Error --")
            print("url: " + url + query)
            return nil
        }
        
        // リクエストの作成
        var request: URLRequest = .init(url: endpoint)
        request.httpMethod = "Get"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // リクエストの送信
        guard let data = await SwitchHistory.sendRequest(request: request) else {
            return nil
        }
        
        // JSONをパース
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as! [String: Any]
            let histories = jsonDict["switchHistories"] as! [[String: Any]]
            var switchHistories: [SwitchHistory] = []
            
            for history in histories {
                let dateString = history["date"] as! String
                let date: Date = DateHelper.fromISOString(string: dateString)
                
                //let subjectiveString = history["subjective"] as! String
                //let subjective: Bool = subjectiveString.lowercased() == "true"
                let subjective: Bool = history["subjective"] as! Bool
                
                let switchHistory: SwitchHistory = .init(id: 0, happend: date, subjective: subjective)
                
                switchHistories.append(switchHistory)
            }
            
            return switchHistories
        } catch {
            print("-- SwitchHistory.fetch : JSON Parse Error --")
            print("url: " + url + query)
            print(error)
            return nil
        }
    }
    
    private static func sendRequest(request: URLRequest) async -> Data? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let response = response as? HTTPURLResponse {
                if !(200...299).contains(response.statusCode) {
                    print("-- SwitchHistory.sendRequest : Invalid Status --")
                    print("status: \(response.statusCode)")
                    return nil
                }
            }
            
            return data
        } catch {
            print("-- SwitchHistory.sendRequest : Error --")
            print("url: " + (request.url?.absoluteString ?? "nil"))
            print(error)
            return nil
        }
    }
}
