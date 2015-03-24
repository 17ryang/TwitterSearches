// Model.swift
// Manges the Twitter Searches area
import Foundation

// delegate protocol that enables Model to notify view controller when the data changes
protocol ModelDelegate {
    func modelDataChanged() // going to be implemented in viewcontrol
}

// manages the saved searches --> NSUserDefaults keeps all daya even after quitting app
class Model { //making constants (let) and variables (var)
    // keys used for storing app's data in app's NSUserDefaults
    private let pairsKey = "TwitterSearchesKVPairs" // for tag-query pairs, private only lets creator of file to use it, get in NSUserDefaults to get information our of later. specific keys are required to extract information, returns searches using this NSUserFeaults
    private let tagsKey = "TwitterSearchesKeyOrder" // tagsKey is a query for the actual tags we are calling (pairsKey), gets the tags and extrafts the infromation, one is not enough because we
    
    //data structure for tags, data structure is only going to exist as long as app is running
    private var searches: [String: String] = [:] // stores tag-query pairs, twitter handle and returns dictionary of search: [cbb, casti b-ball] (becomes self.searhes in app) use key to look into NSUserDefaults
    private var tags: [String] = [] // stores tags in user-specified order, specifying the array as strings, initializing it to be mepty
    
    private let delegate: ModelDelegate // delegate is MasterViewController, reference to the delegate
    
    init(delegate: ModelDelegate) {//getting called when instantiated
        self.delegate = delegate //allow model to call view controller's model data change method when necessary (passing userinput the becomes delegate)
        
        let userDefaults = NSUserDefaults.standardUserDefaults() // the persistent storage on your device, userdefaults is a class, a dot, and the one of its methods. in a classs, you can have calss methods and instance methods. class method can be called without using an object of type NSUserDefaults (w/o an object instantiated). instance method requires an object of the class before you can say instance.methodname
        
        if let pairs = userDefaults.dictionaryForKey(pairsKey){ //asking dictionary to look if tag is in it
            //if let gets something, assigns something, and then checks if it is nil
            self.searches = pairs as [String:String] //if we have a dictionary of tags and twitter searches, then we can assume that the key value strings and source value strings are String:String dictionary,userDefaults is persistent so even if it closes, it will store, so it will only be nil the first time you use the app since oyu have not entered any twitter searches at that point
        }
        if let tags = userDefaults.arrayForKey(tagsKey){
            self.tags = tags as [String]
        
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSearches", name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification, object: NSUbiquitousKeyValueStore.defaultStore())  //initializer to register for all data changes, notification, etc.forces eveyrthing to be an array of strings self is the model,
            //implement this later
        }
    }
    
    func synchronize() {
        NSUbiquitousKeyValueStore.defaultStore().synchronize()//keeping in sync with the cloud, registers any changes and send notifications to pass through, NSUbiquitousKeyValueStore.defaultStore() is the only object we care baout hearing changes frmo. there will be lots of access but only care if its an external notification and the object that provoces is NSUbiquitousKeyValueStore.defaultStore()
    
    }// all methods that access data stored in model
    
    // the following methods are for getting information out of the model
    
    func tagAtIndex(index: Int) -> String{ //returns the string for the tag at the specfified index in the tags Array
        return tags[index] //tag is array, searches is dictionary
    }
    
    func queryForTag(tag: String) -> String{
        return searches[tag]! // pass the key and it reutrns the value that goes with the key
    }
    
    func queryForTagAtIndex(index: Int) -> String? {
        return searches[tags[index]]
    }
    
    // returns the number of tags
    var count: Int {
        return tags.count
    }
    
    // the following methods are for changing the model
    
    func deleteSearchAtIndex(index: Int) {
        searches.removeValueForKey(tags[index])
        let removedTag = tags.removeAtIndex(index)
        updateUserDefaults(updateTags: true, updateSearches: true)
        
        let keyValueStore = NSUbiquitousKeyValueStore.defaultStore()
        keyValueStore.removeObjectForKey(removedTag)
    }
    
    func moveTagAtIndex(oldIndex: Int, todesinationIndex newIndex: Int) {
        let temp = tags.removeAtIndex(oldIndex)
        self.tags.insert(temp, atIndex: newIndex) //make it clear you're using a property by adding "self"
        updateUserDefaults(updateTags: true, updateSearches: false)
    }
    
    // called from mehods that are changing the model
    
    func saveQuery(query: String, forTag tag: String, syncToCloud sync: Bool){  //forTag tag lets you name both internal name and name caller uses when it passes the string in
        let oldValue = searches.updateValue(query, forKey: tag)
        if oldValue == nil {
            tags.insert(tag, atIndex: 0)
            updateUserDefaults(updateTags: true, updateSearches: true)
        } else {
            updateUserDefaults(updateTags: false, updateSearches: true)
        }
        
        if sync {
            NSUbiquitousKeyValueStore.defaultStore().setObject(query, forKey: tag)
        }
    
    }
    
    //Called from emthods that are hanging them odel
    func updateUserDefaults(# updateTags: Bool, updateSearches: Bool){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if updateTags {
            userDefaults.setObject(tags, forKey: tagsKey) //replacing old arrays
        }
        
        if updateSearches {
            userDefaults.setObject(searches, forKey: pairsKey) //dictionaries in NSUserDefault
        }
        
        userDefaults.synchronize()
        
    }
    
    @objc func updateSearches(notification: NSNotification){ //this has to do with maintaining backwards compatilbility with objective-c
        if let userInfo = notification.userInfo { //way to check for nil, if it doesnt get assigned a legitamate value, the if statement's code will not get executed
            if let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as NSNumber? {
                if reason.integerValue == NSUbiquitousKeyValueStoreServerChange || reason.integerValue == NSUbiquitousKeyValueStoreInitialSyncChange {
                    performUpdates(userInfo)
                }
            }
        }
    }
    
    func performUpdates(userInfo: [NSObject: AnyObject?]){
        let changedKeysObject = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] //listing keys that have changer
        let changedKeys = changedKeysObject as [String]
        
        let keyValueStore = NSUbiquitousKeyValueStore.defaultStore()
        
        for key in changedKeys {
            if let query = keyValueStore.stringForKey(key){
                saveQuery(query, forTag: key, syncToCloud: false)
            } else {
                searches.removeValueForKey(key)
                tags = tags.filter{$0 != key}
                updateUserDefaults(updateTags: true, updateSearches: true)
                
            }
            
            delegate.modelDataChanged()
        }
    }
}