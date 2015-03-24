//
//  DetailViewController.swift
//  TwitterSearches
//
//  Created by Risako Yang on 2/26/15.
//  Copyright (c) 2015 Risako Yang. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    var detailItem: NSURL? //might stay nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        webView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated) //super = parent functioncall super to inherit the information
        if let url = self.detailItem { //NSURL --> if let 
            webView.loadRequest(NSURLRequest(URL: url))
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        webView.stopLoading()
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        webView.loadHTMLString("<html><body><p>An error occured when performing " + "the Twitter search: " + error.description + "</p><body></html>",  baseURL: nil)
    }

}

