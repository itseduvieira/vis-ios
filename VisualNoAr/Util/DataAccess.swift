//
//  DataAccess.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 19/08/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

import Alamofire
import FirebaseAuth
import PromiseKit

class DataAccess {
    private let url = "https://vis-api.herokuapp.com/m/v1"
    
    var sessionManager: SessionManager!
    
    static let instance = DataAccess()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8
        sessionManager = Alamofire.SessionManager(configuration: configuration)
        sessionManager.retrier = VnaRetryHandler()
    }
    
    private func createExtRequest(_ path: String, method: HTTPMethod, parameters: Parameters) -> Promise<Any> {
        let headers = [
            "Accept": "application/json"
        ]
        
        let fullUrl = "\(url)/\(path)"
        
        print("\(String(method.rawValue)) \(fullUrl)")
        
        return Promise { seal in
            firstly {
                sessionManager.request(fullUrl, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON()
                }.done { (json, response) in
                    
                    seal.fulfill(json)
                }.catch { error in
                    print("ERR \(String(method.rawValue)) \(fullUrl)")
                    
                    seal.reject(error)
            }
        }
    }
    
    private func createRequest(_ path: String, method: HTTPMethod, parameters: Parameters) -> Promise<Any> {
        let headers = [
            "Authorization": "Bearer \(Auth.auth().currentUser!.uid)",
            "Accept": "application/json"
        ]
        
        let fullUrl = "\(url)/\(path)"
        
        print("\(String(method.rawValue)) \(fullUrl)")
        
        return Promise { seal in
            firstly {
                sessionManager.request(fullUrl, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON()
                }.done { (json, response) in
                    
                    seal.fulfill(json)
                }.catch { error in
                    print("ERR \(String(method.rawValue)) \(fullUrl)")
                    
                    seal.reject(error)
            }
        }
    }
    
    func getImage(_ url: String) -> Promise<Data> {
        let headers = [
            "Authorization": "Bearer \(Auth.auth().currentUser!.uid)"
        ]
        
        print("GET \(url)")
        
        return Promise { seal in
            firstly {
                sessionManager.request(url, encoding: URLEncoding.default, headers: headers).responseData()
            }.done { (data, response) in
                seal.fulfill(data)
            }.catch { error in
                print("ERR GET \(url)")
                
                seal.reject(error)
            }
        }
    }
    
    private func createRequest(_ path: String, method: HTTPMethod) -> Promise<Any> {
        let parameters: Parameters = [:]
        
        return createRequest(path, method: method, parameters: parameters)
    }
    
    func getUser() -> Promise<Void> {        
        return Promise { seal in
            firstly {
                createRequest("users/\(Auth.auth().currentUser!.uid)", method: .get)
            }.done { response in
                guard let json = response as? [String: Any] else {
                    return seal.reject(AFError.responseValidationFailed(reason: .dataFileNil))
                }
                
                UserDefaults.standard.set(json["name"] as! String, forKey: "name")
                
                let company = json["company"] as! [String: Any]
                UserDefaults.standard.set(company["name"] as! String, forKey: "company")
                UserDefaults.standard.set(company["_id"] as! String, forKey: "companyId")
                
                seal.fulfill(())
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func sendFCMToken(_ token: String) -> Promise<Void> {
        let parameters: Parameters = [
            "token": token
        ]
        
        return Promise { seal in
            firstly {
                createRequest("users/\(Auth.auth().currentUser!.uid)/token", method: .post, parameters: parameters)
            }.done { response in
                seal.fulfill(())
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func getPlace(_ placeId: String) -> Promise<Place> {
        return Promise { seal in
            firstly {
                createRequest("places/\(placeId)", method: .get)
            }.done { response in
                guard let json = response as? [String: Any] else {
                    return seal.reject(AFError.responseValidationFailed(reason: .dataFileNil))
                }
                
                let place = Place()
                place.title = json["title"] as? String
                place.locations = json["locations"] as? [String]
                place.urls = json["urls"] as? [[String:String]]
                
                seal.fulfill(place)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func listCampaigns() -> Promise<[Campaign]> {
        guard let companyId = UserDefaults.standard.string(forKey: "companyId") else {
            return Promise(error: PromiseErrors.general)
        }
        
        return Promise { seal in
            firstly {
                createRequest("campaigns/company/\(companyId)", method: .get)
            }.done { response in
                guard let json = response as? [[String: Any]] else {
                    return seal.reject(AFError.responseValidationFailed(reason: .dataFileNil))
                }
                
                var campaigns: [Campaign] = []
                
                for jsonCampaign in json {
                    let campaign = Campaign()
                    campaign.name = jsonCampaign["name"] as? String
                    
                    if let place = jsonCampaign["place"] as? [String:Any] {
                        campaign.place = Place()
                        campaign.place.title = place["title"] as? String
                        campaign.place.urls = place["urls"] as? [[String:String]]
                    }
                    
                    if let jsonPlane = jsonCampaign["plane"] as? [String:Any] {
                        campaign.plane = jsonPlane["prefix"] as? String
                    }
                    
                    campaigns.append(campaign)
                }
                
                seal.fulfill(campaigns)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func sendForgotPassword(_ email: String) -> Promise<Void> {
        let parameters: Parameters = [
            "email": email
        ]
        
        return Promise { seal in
            firstly {
                createExtRequest("users/forgot", method: .post, parameters: parameters)
            }.done { response in
                seal.fulfill(())
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}

class VnaRetryHandler: RequestRetrier {
    var retryCount = 0
    
    public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        
        if error._code == NSURLErrorTimedOut && retryCount < 3 {
            retryCount += 1
            completion(true, 1.0) // retry after 1 second
        } else {
            retryCount = 0
            completion(false, 0.0) // don't retry
        }
    }
}

enum PromiseErrors: Error {
    case general
}
