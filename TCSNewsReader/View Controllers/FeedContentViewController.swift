//
//  FeedContentViewController.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import UIKit
import WebKit

class FeedContentViewController: UIViewController, WKNavigationDelegate {

    // MARK: - Private variables
    
    private var _content: String?
    
    // MARK: - Public variables
    
    public var content: String? {
        get {
            return _content
        }
        
        set {
            _content = newValue
            
            if isViewLoaded {
                loadContent()
            }
        }
    }
    
    public var errorMessage: String?
    
    // MARK: - Outlets
    
    @IBOutlet weak var webView: WKWebView!
    
    // MARK: - Private methods
    
    private func loadContent() {
        if let content = content {
            DispatchQueue.main.async { [unowned self] in
                self.webView.loadHTMLString(content, baseURL: nil)
            }
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        
        loadContent()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let errorMessage = errorMessage {
            let alertController = UIAlertController(title: ERROR_TITLE, message: errorMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: ERROR_ALERT_ACTION, style: .default, handler: {
                [unowned self] (_) in
                self.navigationController?.popViewController(animated: true)
            })
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - WKNavigationDelegate methods
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

}
