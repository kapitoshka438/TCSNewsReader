//
//  WebManager.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import Foundation

class WebManager: NSObject {
    
    // MARK: - Constants
    
    let FEED_CONTENT_URL = "https://api.tinkoff.ru/v1/news_content?id=%d"
    let FEEDS_URL = "https://api.tinkoff.ru/v1/news?first=%d&last=%d"
    
    let PAGE_FEED_COUNT = 20

    // MARK: - Singleton
    
    private override init() { }
    
    private static var webManager: WebManager = {
        let webManager = WebManager()
        return webManager
    }()

    class var shared: WebManager {
        return webManager
    }
    
    // MARK: - Public methods
    
    func getNewFeeds(first: Int, completionHandler: @escaping (Array<FeedJSONModel>?, Error?) -> Swift.Void) {
        let urlString = String.init(format: FEEDS_URL,
                                    first,
                                    first + PAGE_FEED_COUNT)
        let url = URL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard error == nil else {
                print(error!)
                completionHandler(nil, error)
                return
            }
        
            guard let responseData = data else {
                let err = JSONParseError.init(description: "Did not receive data", code: .nullData)
                completionHandler(nil, err)
                return
            }

            do {
                guard let todo = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        let err = JSONParseError.init(description: "Error trying to convert data to JSON", code: .serialization)
                        completionHandler(nil, err)
                        return
                }
                
                guard let todoTitle = todo["payload"] as? [[String: Any]] else {
                    let err = JSONParseError.init(description: "Could not get payload", code: .keyNotFound)
                    completionHandler(nil, err)
                    return
                }
                
                var newFeeds: Array<FeedJSONModel> = []
                if todoTitle.count > 0 {
                    for i in 0...todoTitle.count - 1 {
                        let item = todoTitle[i]
                        
                        guard let id = item["id"] as? String else {
                            let err = JSONParseError.init(description: "Could not get id", code: .keyNotFound)
                            completionHandler(nil, err)
                            continue
                        }
                        
                        guard let publicationDate = item["publicationDate"] as? [String: Any] else {
                            let err = JSONParseError.init(description: "Could not get publicationDate", code: .keyNotFound)
                            completionHandler(nil, err)
                            continue
                        }
                        
                        guard let milliseconds = publicationDate["milliseconds"] as? Int else {
                            let err = JSONParseError.init(description: "Could not get milliseconds", code: .keyNotFound)
                            completionHandler(nil, err)
                            continue
                        }
                        
                        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
                        
                        guard let text = item["text"] as? String else {
                            let err = JSONParseError.init(description: "Could not get text", code: .keyNotFound)
                            completionHandler(nil, err)
                            continue
                        }
                        
                        let idInt = Int(id)
                        
                        let feed = FeedJSONModel(order: first + i,
                                             id: idInt!,
                                             text: text,
                                             publicationDate: dateVar)
                        
                        newFeeds.append(feed)
                    }
                }
                
                completionHandler(newFeeds, nil)
            } catch  {
                let err = JSONParseError.init(description: "Error trying to convert data to JSON", code: .serialization)
                completionHandler(nil, err)
                return
            }
        }
        
        task.resume()
    }
    
    func getContentForFeed(feed: Feed, completionHandler: @escaping (String?, Error?) -> Swift.Void) {
        let urlString = String.init(format: FEED_CONTENT_URL, feed.id)
        let url = URL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            guard let responseData = data else {
                let err = JSONParseError.init(description: "Did not receive data", code: .nullData)
                completionHandler(nil, err)
                return
            }

            do {
                guard let todo = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        let err = JSONParseError.init(description: "Error trying to convert data to JSON", code: .serialization)
                        completionHandler(nil, err)
                        return
                }
                
                guard let todoTitle = todo["payload"] as? [String: Any] else {
                    let err = JSONParseError.init(description: "Could not get payload", code: .keyNotFound)
                    completionHandler(nil, err)
                    return
                }
                
                guard let content = todoTitle["content"] as? String else {
                    let err = JSONParseError.init(description: "Could not get content", code: .keyNotFound)
                    completionHandler(nil, err)
                    return
                }
                
                completionHandler(content, nil)
            } catch  {
                let err = JSONParseError.init(description: "Error trying to convert data to JSON", code: .serialization)
                completionHandler(nil, err)
                return
            }
        }
        
        task.resume()
    }

}
