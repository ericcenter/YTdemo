//
//  ViewController.swift
//  YTDemo
//
//  Created by Gabriel Theodoropoulos on 27/6/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tblVideos: UITableView!
    
    @IBOutlet weak var segDisplayedContent: UISegmentedControl!
    
    @IBOutlet weak var viewWait: UIView!
    
    @IBOutlet weak var txtSearch: UITextField!
    
    
    //新增之頻道變數
    var apiKey = "AIzaSyByypsUlVB793PjYoSIgjP742XmouboDog"
    
    var desiredChannelsArray = ["Apple", "Google", "Microsoft"]
    
    var channelIndex = 0
    
    var channelsDataArray: Array<Dictionary<NSObject, AnyObject>> = []
    
    //影片變數
    var videosArray: Array<Dictionary<NSObject, AnyObject>> = []

    var selectedVideoIndex: Int!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tblVideos.delegate = self
        tblVideos.dataSource = self
        txtSearch.delegate = self
        
        //呼叫函式
        getChannelDetails(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: IBAction method implementation
    
    @IBAction func changeContent(sender: AnyObject) {
        
        tblVideos.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
        
    }
    
    
    // MARK: UITableView method implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
   
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //指定表格視圖的資料列數目
        if segDisplayedContent.selectedSegmentIndex == 0 {
            return channelsDataArray.count
        }
        else {
            
            return videosArray.count
        }
        
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //在表格視圖中顯示對應的儲存格資料
        var cell: UITableViewCell!
        
        if segDisplayedContent.selectedSegmentIndex == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("idCellChannel", forIndexPath: indexPath)
            
            //從每個儲存格中將這些子視圖「抽取」出來，以便將擷取到的資料填進去
            let channelTitleLabel = cell.viewWithTag(10) as! UILabel
            let channelDescriptionLabel = cell.viewWithTag(11) as! UILabel
            let thumbnailImageView = cell.viewWithTag(12) as! UIImageView
            
            //取得每個頻道的詳情，並且指派給這些子視圖
            let channelDetails = channelsDataArray[indexPath.row]
            channelTitleLabel.text = channelDetails["title"] as? String
            channelDescriptionLabel.text = channelDetails["description"] as? String
            thumbnailImageView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: (channelDetails["thumbnail"] as? String)!)!)!)
            
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("idCellVideo", forIndexPath: indexPath)
            
            let videoTitle = cell.viewWithTag(10) as! UILabel
            let videoThumbnail = cell.viewWithTag(11) as! UIImageView
            
            let videoDetails = videosArray[indexPath.row]
            videoTitle.text = videoDetails["title"] as? String
            videoThumbnail.image = UIImage(data: NSData(contentsOfURL: NSURL(string: (videoDetails["thumbnail"] as? String)!)!)!)
            
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 140.0
    }
    
    
    // MARK: UITextFieldDelegate method implementation
    // 隱藏鍵盤，以及根據分段元件的選取索引來決定搜尋類型
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        viewWait.hidden = false
        
        // 指定搜尋類型（頻道或影片）
        var type = "channel"
        if segDisplayedContent.selectedSegmentIndex == 1 {
            type = "video"
            videosArray.removeAll(keepCapacity: false)
        }
        
        // 產生要求的 URL 字串
        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(textField.text)&type=\(type)&key=\(apiKey)"
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        // 根據上述字串建立 NSURL 物件
        let targetURL = NSURL(string: urlString)

        
        // 取得結果
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                // 將 JSON 資料轉換成字典物件
                do {
                    let resultsDict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! Dictionary<NSObject, AnyObject>
                    
                    // 取得所有的搜尋結果項目（ items 陣列）
                    let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                    
                    // 以迴圈迭代處理所有的搜尋結果，並且只保留所需的資料
                    for var i=0; i<items.count; ++i {
                        let snippetDict = items[i]["snippet"] as! Dictionary<NSObject, AnyObject>
                        
                        // 根據搜尋的目標是頻道或影片來收集正確的資料
                        if self.segDisplayedContent.selectedSegmentIndex == 0 {
                            
                            // 記住頻道 ID
                            self.desiredChannelsArray.append(snippetDict["channelId"] as! String)
                            
                        }
                        else {
                            
                            // 建立新的字典，用來儲存影片詳情
                            var videoDetailsDict = Dictionary<NSObject, AnyObject>()
                            videoDetailsDict["title"] = snippetDict["title"]
                            videoDetailsDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                            videoDetailsDict["videoID"] = (items[i]["id"] as! Dictionary<NSObject, AnyObject>)["videoId"]
                            
                            // 將 desiredPlaylistItemDataDict 字典附加到影片陣列當中
                            self.videosArray.append(videoDetailsDict)
                            
                            // 重新載入表格視圖
                            self.tblVideos.reloadData()
                            
                            
                        }
                    }
                    
                    // 呼叫 getChannelDetails(...) 函式以便擷取頻道
                    if self.segDisplayedContent.selectedSegmentIndex == 0 {
                        self.getChannelDetails(true)
                    }
                
                
                } catch {
                    print(error)
                }
                
            }
            
            else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel videos: \(error)")
            }
            
            // 隱藏活動指示器
            self.viewWait.hidden = true
            
        })
        
        return true
    }
    
    
    // 擷取網頁資料，並且以非同步的方式處理，使用dispatch_async
    func performGetRequest(targetURL: NSURL!, completion: (data: NSData?, HTTPStatusCode: Int, error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL: targetURL)
        request.HTTPMethod = "GET"
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: sessionConfiguration)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data: data, HTTPStatusCode: (response as! NSHTTPURLResponse).statusCode, error: error)
            })
        })
        
        task.resume()
    }
    
    
    
    //處理頻道儲存格的點擊事件
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if segDisplayedContent.selectedSegmentIndex == 0 {
            // 在本例中，頻道就是要顯示的內容
            // 所選頻道的影片將被擷取並顯示出來
            
            // 將分段元件切換成「 Videos 」
            segDisplayedContent.selectedSegmentIndex = 1
            
            // 顯示活動指示器
            viewWait.hidden = false
            
            // 移除 videosArray 陣列中全部舊有的影片詳情
            videosArray.removeAll(keepCapacity: false)
            
            // 針對點擊的頻道，擷取其影片詳情
            getVideosForChannelAtIndex(indexPath.row)
        }
        else {
            
            selectedVideoIndex = indexPath.row
            performSegueWithIdentifier("idSeguePlayer", sender: self)
            
        }
    }
    
    //取得所選頻道的播放清單 ID 。接著會指定剛才提過的參數，以便產生正確的 URL 字串，接著我們會建立 NSURL 物件，以便發出要求
    func getVideosForChannelAtIndex(index: Int!) {
        // 從 channelsDataArray 陣列取得所選頻道的 playlistID 數值，並用來擷取正確的影片播放清單
        let playlistID = channelsDataArray[index]["playlistID"] as! String
        
        // 產生要求 URL 的字串
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(playlistID)&key=\(apiKey)"
        
        // 根據上述字串產生 NSURL 物件
        let targetURL = NSURL(string: urlString)
        
        // 從 Google 取得播放清單
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                do {
                    // 將 JSON 資料轉換成字典
                    let resultsDict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! Dictionary<NSObject, AnyObject>
                    
                    // 取得所有的播放清單項目（形成 items 陣列）
                    let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                    
                    // 利用迴圈來處理所有的影片項目
                    for var i=0; i<items.count; ++i {
                        let playlistSnippetDict = (items[i] as Dictionary<NSObject, AnyObject>)["snippet"] as! Dictionary<NSObject, AnyObject>
                        
                        // 初始化新的字典，並且儲存感興趣的資料
                        var desiredPlaylistItemDataDict = Dictionary<NSObject, AnyObject>()
                        
                        desiredPlaylistItemDataDict["title"] = playlistSnippetDict["title"]
                        desiredPlaylistItemDataDict["thumbnail"] = ((playlistSnippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                        desiredPlaylistItemDataDict["videoID"] = (playlistSnippetDict["resourceId"] as! Dictionary<NSObject, AnyObject>)["videoId"]
                        
                        // 將 desiredPlaylistItemDataDict 字典附加到影片陣列中
                        self.videosArray.append(desiredPlaylistItemDataDict)
                        
                        // 重新載入表格視圖
                        self.tblVideos.reloadData()
                    }
                } catch {
                    print(error)
                }
            }
            
            else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel videos: \(error)")
            }
            
            // 隱藏活動指示器
            self.viewWait.hidden = true
            
        })
    }
    
    
    
    // 使用YouTube API函式，設定參數，指定或篩選要傳回的資料
    // 我們針對此參數的設定是 snippet, contentDetails （以逗號分隔數值），其中 snippet 可以為我們提供頻道的詳情（我們會在稍後加以顯示），而 contentDetails 則會傳回該頻道所擁有的上傳影片的播放清單 ID 。在基於使用者名稱來擷取頻道的情況當中，我們還會使用到 forUsername 參數，並且使用 id 參數來取得該 ID 所代表的頻道的資訊。
    
    func getChannelDetails(useChannelIDParam: Bool) {
        var urlString: String!
        if !useChannelIDParam {
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&forUsername=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
        }
        else {
            
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&id=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
            
        }
        
        let targetURL = NSURL(string: urlString)
    
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                
                do {
                    // 將 JSON 資料轉換成字典
                    let resultsDict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! Dictionary<NSObject, AnyObject>
                    
                    // 從傳回的資料中取得第一筆字典記錄（通常也只會有一筆記錄）
                    let items: AnyObject! = resultsDict["items"] as AnyObject!
                    let firstItemDict = (items as! Array<AnyObject>)[0] as! Dictionary<NSObject, AnyObject>
                    
                    // 取得包含所需資料的 snippet 字典
                    let snippetDict = firstItemDict["snippet"] as! Dictionary<NSObject, AnyObject>
                    
                    // 建立新的字典，只儲存我們想要知道的數值
                    var desiredValuesDict: Dictionary<NSObject, AnyObject> = Dictionary<NSObject, AnyObject>()
                    desiredValuesDict["title"] = snippetDict["title"]
                    desiredValuesDict["description"] = snippetDict["description"]
                    desiredValuesDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                    
                    // 儲存頻道的上傳影片的播放清單 ID
                    desiredValuesDict["playlistID"] = ((firstItemDict["contentDetails"] as! Dictionary<NSObject, AnyObject>)["relatedPlaylists"] as! Dictionary<NSObject, AnyObject>)["uploads"]
                    
                    
                    // 將 desiredValuesDict 字典新增到陣列中
                    self.channelsDataArray.append(desiredValuesDict)
                    
                    
                    // 重新載入表格視圖
                    self.tblVideos.reloadData()
                    
                    // 載入下一個頻道資料（如果有的話）
                    ++self.channelIndex
                    if self.channelIndex < self.desiredChannelsArray.count {
                        self.getChannelDetails(useChannelIDParam)
                    }
                    else {
                        self.viewWait.hidden = true
                    }
                    
                    
                } catch {
                    print(error)
                }
                
            }
            
            else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel details: \(error)")
            }
            
        })
    
    
    
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "idSeguePlayer" {
            let playerViewController = segue.destinationViewController as! PlayerViewController
            playerViewController.videoID = videosArray[selectedVideoIndex]["videoID"] as! String
        }
    }
   
}

