//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2019.
//  Copyright © 2019 London App Brewery. All rights reserved.
//

import UIKit
import Twift
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let sentimentClassifier: TwitterMenti = {
        do {
            let config = MLModelConfiguration()
            return try TwitterMenti(configuration: config)
        } catch {
            print(error)
            fatalError("Couldn't create sentiment classifier")
        }
    }()
    
    private var apiKey: String {
      get {
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
          fatalError("Couldn't find file 'Secrets.pilst'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "Bearer Token") as? String else {
          fatalError("Couldn't find key 'Bearer Token' in 'Secrets.pilst'.")
        }
        return value
      }
    }
    
    var client: Twift?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        client = Twift(appOnlyBearerToken: apiKey)
    }
    
    
    @IBAction func predictPressed(_ sender: Any) {
        Task {
            await fetchTweets()
        }

    }
        
    func fetchTweets() async {
        if let searchText = textField.text {
            do{
                let query = "\(searchText) lang:en"
                let results = try await client!.searchRecentTweets(query: query, maxResults: 100)

                
                var tweets = [TwitterMentiInput]()
                
                
                for tweet in results.data {
                    let tweetForClassification = TwitterMentiInput(text: tweet.text)
                    tweets.append(tweetForClassification)
                }
                
                self.makePrediction(with: tweets)

                
                
            } catch {
                print("An error occured: ", error)
            }
            
            
        }
    }
        
    func makePrediction(with tweets: [TwitterMentiInput]) {
        do {
            let predictions = try self.sentimentClassifier.predictions(inputs: tweets)

            var sentimentScore = 0

            for p in predictions {
                let sentiment = p.label

                if sentiment == "Pos" { sentimentScore += 1}
                else if sentiment == "Neg" {sentimentScore -= 1}
            }

            updateUI(with: sentimentScore)

        } catch {
            print("There was an error with the Twitter API request, \(error)")
        }
    }
        
        
    func updateUI(with sentimentScore: Int) {

            if sentimentScore > 20 {
                self.sentimentLabel.text = "😍"
            } else if sentimentScore > 10 {
                self.sentimentLabel.text = "😀"
            } else if sentimentScore > 0 {
                self.sentimentLabel.text = "🙂"
            } else if sentimentScore == 0 {
                self.sentimentLabel.text = "😐"
            } else if sentimentScore > -10 {
                self.sentimentLabel.text = "🙁"
            } else if sentimentScore > -20 {
                self.sentimentLabel.text = "😡"
            } else {
                self.sentimentLabel.text = "🤮"
            }
        }
    }
