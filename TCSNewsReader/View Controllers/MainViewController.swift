//
//  MainViewController.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController {
    
    // MARK: - Variables
    
    var feedManager = FeedsManager.shared
    
    // MARK: - View lifesycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Новости"
        
        let feedCount = feedManager.feedFetchedResultsController.fetchedObjects?.count ?? 0
        
        if feedCount == 0 {
            loadNewFeeds()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func refreshAction(_ sender: Any) {
        feedManager.deleteAllFeeds()
        tableView.reloadData()
        loadNewFeeds()
        tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: - Private methods
    
    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: ERROR_TITLE, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: ERROR_ALERT_ACTION, style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func loadNewFeeds() {
        guard let fetchedObjects = feedManager.feedFetchedResultsController.fetchedObjects else { return }
        
        WebManager.shared.getNewFeeds(first: fetchedObjects.count, completionHandler: {
            [unowned self] (newFeeds, error) in
            
            guard error == nil else {
                print(error!)

                if let nsError = error as NSError? {
                    print(nsError.code)
                    if nsError.code == -1003 {
                        self.showErrorAlert(message: ERROR_DESCRIPTION_SERVER_NOT_RESPONDING)
                    } else if nsError.code == -1009 {
                        self.showErrorAlert(message: ERROR_DESCRIPTION_NO_INTERNET)
                    }
                }
                
                return
            }
            
            guard let newFeeds = newFeeds else { return }
            
            if newFeeds.count > 0 {
                do {
                    try self.feedManager.importFeedsFromJSONModelArray(newFeeds, completion: {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    })
                }
                catch {
                    return
                }
            }
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedManager.feedFetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if let feed = feedManager.feedFetchedResultsController.fetchedObjects?[indexPath.row] {
            if let titleLabel = cell.viewWithTag(1) as? UILabel {
                titleLabel.text = feed.text
            }
            
            if let dateLabel = cell.viewWithTag(2) as? UILabel {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy hh:mm"
                let dateString = dateFormatter.string(from: feed.publicationDate)
                dateLabel.text = dateString
            }
            
            if let countLabel = cell.viewWithTag(3) as? UILabel {
                let count =
                    feedManager.watchedCountFetchedResultController.fetchedObjects?.first(where: { (feedWatchedCount) -> Bool in
                        return feedWatchedCount.id == feed.id
                    })?.count ?? 0
                
                countLabel.text = "Просмотров: \(count)"
            }
        }

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let fetchedObjects = feedManager.feedFetchedResultsController.fetchedObjects else { return }
        
        if indexPath.row == fetchedObjects.count - 1 {
            loadNewFeeds()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let row = tableView.indexPathForSelectedRow?.row else { return }

        if segue.identifier == "WatchFeed" {
            guard let feed = feedManager.feedFetchedResultsController.fetchedObjects?[row] else { return }
            feedManager.incrementWatchedCountFor(feed: feed)
            
            guard let feedContentViewController = segue.destination as? FeedContentViewController else { return }
            
            
            if let feedContent = feedManager.getContentFor(feed: feed) {
                feedContentViewController.content = feedContent.content
                return
            }
            
            WebManager.shared.getContentForFeed(feed: feed, completionHandler: {
                [unowned self, weak feedContentViewController] (content, error) in
                
                guard error == nil else {
                    print(error!)
                    
                    if let nsError = error as NSError? {
                        print(nsError.code)
                        if nsError.code == -1003 {
                            feedContentViewController?.errorMessage = ERROR_DESCRIPTION_SERVER_NOT_RESPONDING
                        } else if nsError.code == -1009 {
                            feedContentViewController?.errorMessage = ERROR_DESCRIPTION_NO_INTERNET
                        }
                    }
                    
                    return
                }
                
                guard let content = content else {
                    feedContentViewController?.errorMessage = ERROR_DESCRIPTION_WRONG_DATA
                    return
                }
                
                self.feedManager.addContentFor(feed: feed, content: content)
                feedContentViewController?.content = content
            })
        }
    }

}
