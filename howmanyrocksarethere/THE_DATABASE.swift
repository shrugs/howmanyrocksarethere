//
//  THE_DATABASE.swift
//  howmanyrocksarethere
//
//  Created by Matt Condon on 9/10/16.
//  Copyright © 2016 howmanyrocksarethere. All rights reserved.
//

import Alamofire

class THE_DATABASE {

  static let sharedDatabase = THE_DATABASE()

  var token : String? {
    get {
      return NSUserDefaults.standardUserDefaults().objectForKey("token") as? String
    }
    set {
      let defaults = NSUserDefaults.standardUserDefaults()
      defaults.setObject(newValue, forKey: "token")
      defaults.synchronize()
    }
  }

  var clarifaiAuthToken : String?

  let baseUrl = "http://howmanyrocks.ngrok.io"


  func refreshClarifaiAccessToken() {
    Alamofire.request(.POST, "https://api.clarifai.com/v1/token/", parameters: [
      "client_id": Clarifai.ClientId,
      "client_secret": Clarifai.ClientSecret,
      "grant_type": "client_credentials"
    ])
    .responseJSON { resp in
      switch resp.result {
      case .Success(let JSON):
        let ret = JSON as! [String: AnyObject]
        self.clarifaiAuthToken = ret["access_token"] as? String
        print("Authenticated with Clarifai")
      default:
        print("Clarifai Authentication Failed")
        print(resp)
      }
    }
  }

  func createUser(username: String, cb: () -> Void) {
    // create the user
    // store the token in nsuserdefaults
    Alamofire.request(.POST, "\(baseUrl)/users", headers: [
      "Accept": "application/json"
    ], parameters: [
      "username": username
    ], encoding: .JSON)
    .responseJSON { resp in
      switch resp.result {
      case .Success(let JSON):
        let data = JSON as! [String: String]
        self.token = data["token"]!
        cb()
      default:
        debugPrint(resp)
      }
    }
  }

  func submitRock(params: [String: AnyObject], cb: () -> Void) {
    Alamofire.request(.POST, "\(baseUrl)/rocks", headers: [
      "Authorization": "Token token=\(self.token ?? "")",
      "Accept": "application/json"
    ], parameters: params, encoding: .JSON)
    .responseJSON { resp in
      switch resp.result {
      case .Success:
        cb()
      default:
        debugPrint(resp)
      }
    }
  }

  func getRocks(cb: ([[String: AnyObject]]) -> Void) {
    Alamofire.request(.GET, "\(baseUrl)/rocks")
      .responseJSON { resp in
        switch resp.result {
        case .Success(let JSON):
          let rocks = JSON as! [[String: AnyObject]]
          cb(rocks)
        default:
           print(resp)
        }
      }
  }
}