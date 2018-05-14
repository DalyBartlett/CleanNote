//
//  MemoListViewController.swift
//  SimpleMemo
//
//  Created by  李俊 on 2017/2/25.
//  Copyright © 2017年 Lijun. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import EvernoteSDK
import SMKit
import SnapKit

private let backgroundColor = UIColor(r: 245, g: 245, b: 245)
private let addBtnSize: CGFloat = 55

class MemoListViewController: MemoCollectionViewController , CLLocationManagerDelegate {

  fileprivate lazy var searchView = UIView()
  fileprivate var isSearching: Bool = false
  fileprivate lazy var searchResults = [Memo]()
  fileprivate lazy var searchBar = UISearchBar()

    let locationManager = CLLocationManager()
    var location: CLLocation?
    var Weather2D: CLLocationCoordinate2D?
    
  fileprivate let addButton: UIButton = {
    let button = UIButton(type: .custom)
    let image = UIImage(named: "ic_add")?.withRenderingMode(.alwaysTemplate)
    button.setImage(image, for: .normal)
    button.tintColor = .white
    button.backgroundColor = SMColor.tint
    button.layer.cornerRadius = addBtnSize / 2
    button.layer.masksToBounds = true
    return button
  }()

    //MARK: - StartCurrentCity
    func getCurrentCityLoaction()
    {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        startLocationManager()
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",message:"Please enable location services for this app in Settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }else
        {}
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print ("here")
        
        let newLocation = locations.last!
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            print("too old")
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            print ("less than 0")
            return
        }
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy   {
            print ("improving")
            
            location = newLocation
            Weather2D = newLocation.coordinate
            locationManager.stopUpdatingLocation()
            return
            //            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
            //                search.cancelSearches()
            //                print("*** We're done!")
            //                let center = CLLocationCoordinate2D(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
            //                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            //                self.mapView.setRegion(region, animated: true)
            //                stopLocationManager()
            //            }
        }
    }
    
    func GotoWeatherAction(sender:UIBarButtonItem)
    {
        if(location?.coordinate.latitude == 0.0 || location?.coordinate.longitude == 0.0 || location == nil || Weather2D == nil)
        {
            showLocationFauseAlert()
        }
        else
        {
            let WeatherView:WeatherViewController = WeatherViewController()
            WeatherView.loaction = location
            WeatherView.lat  = (Weather2D?.latitude)!
            WeatherView.lng = (Weather2D?.longitude)!
            
            present(WeatherView, animated: true, completion: nil)
        }
        
    }
    func showLocationFauseAlert() {
        let alert = UIAlertController(title: nil,message:"Failed to get the current location, please check if location permission is enabled,Or try clicking on the weather again after clicking ‘OK’", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default){ action in
            
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.locationManager.startUpdatingLocation()
            
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
  fileprivate lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Clean Note"
    label.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
    label.textColor = SMColor.title
    label.sizeToFit()
    return label
  }()

  fileprivate lazy var evernoteItem: UIBarButtonItem = {
    let item = UIBarButtonItem(image: UIImage(named: "ENActivityIcon"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(evernoteAuthenticate))
    return item
  }()

  fileprivate lazy var searchItem: UIBarButtonItem = {
    let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.search, target: self, action: #selector(search))
    return item
  }()

    @available(iOS 10.0, *)
    lazy var fetchedResultsController: NSFetchedResultsController<Memo> = {
    let request = Memo.defaultRequest()
    let sortDescriptor = NSSortDescriptor(key: "updateDate", ascending: false)
    request.sortDescriptors = [sortDescriptor]
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStack.default.managedContext, sectionNameKeyPath: nil, cacheName: nil)
    controller.delegate = self
    return controller
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    do {
        if #available(iOS 10.0, *) {
            try fetchedResultsController.performFetch()
        } else {
            // Fallback on earlier versions
        }
    } catch {
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
    collectionView?.backgroundColor = backgroundColor
    collectionView?.register(MemoCell.self, forCellWithReuseIdentifier: String(describing: MemoCell.self))
    getCurrentCityLoaction()
    setNavigationBar()

    addButton.addTarget(self, action: #selector(addMemo), for: .touchUpInside)
    view.addSubview(addButton)
    addButton.snp.makeConstraints { (addBtn) in
      addBtn.centerX.equalToSuperview()
      addBtn.bottom.equalTo(view).offset(-30)
      addBtn.size.equalTo(CGSize(width: addBtnSize, height: addBtnSize))
    }
    if traitCollection.forceTouchCapability == .available {
      registerForPreviewing(with: self, sourceView: view)
    }

    if SimpleMemoNoteBook != nil {
      updateMemoFromEvernote()
    }

    NotificationCenter.default.addObserver(self, selector: #selector(updateMemoFromEvernote), name: SMNotification.SimpleMemoDidSetSimpleMemoNotebook, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(updateMemoFromEvernote), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if ENSession.shared.isAuthenticated {
      uploadMemoToEvernote()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

}

// MARK: - UICollectionViewDataSource Delegate

extension MemoListViewController {

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if #available(iOS 10.0, *) {
        return (isSearching ? searchResults.count :
            fetchedResultsController.fetchedObjects?.count ?? 0)
    } else {
        return 0;
        // Fallback on earlier versions
    }
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    // swiftlint:disable:next force_cast
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MemoCell.self), for: indexPath) as! MemoCell

    if #available(iOS 10.0, *) {
        let memo = isSearching ? searchResults[indexPath.row] : fetchedResultsController.object(at: indexPath)
        cell.memo = memo
        cell.deleteMemoAction = { memo in
            let alert = UIAlertController(title: "Delete notes", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "cancle", style: UIAlertActionStyle.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "delete", style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
                ENSession.shared.deleteFromEvernote(with: memo)
                if #available(iOS 10.0, *) {
                    CoreDataStack.default.managedContext.delete(memo)
                    CoreDataStack.default.saveContext()
                } else {
                    // Fallback on earlier versions
                }
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        cell.didSelectedMemoAction = { memo in
            let MemoView = MemoViewController()
            MemoView.memo = memo
            self.navigationController?.pushViewController(MemoView, animated: true)
        }
        return cell
    } else {
        // Fallback on earlier versions
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MemoCell.self), for: indexPath) as! MemoCell
        return cell
    }
    
  }
}

private extension MemoListViewController {

  func setNavigationBar() {
    navigationItem.titleView = titleLabel
    evernoteItem.tintColor = ENSession.shared.isAuthenticated ? SMColor.tint : UIColor.gray
    navigationItem.rightBarButtonItem = searchItem
    let btnAction = UIButton(frame:CGRect(x:0, y:0, width:18, height:18))
    btnAction.setTitle("🌞", for: .normal)
    
    btnAction.addTarget(self,action:#selector(GotoWeatherAction(sender:)),for:.touchUpInside)
   navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnAction)
    //    navigationItem.leftBarButtonItem = evernoteItem
  }

  /// evernoteAuthenticate
  @objc func evernoteAuthenticate() {
    if ENSession.shared.isAuthenticated {
      let alert = UIAlertController(title: "Exit Evernote?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title: "cancle", style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: "exit", style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
        ENSession.shared.unauthenticate()
        self.evernoteItem.tintColor = UIColor.gray
      }))
      present(alert, animated: true, completion: nil)
    } else {
      ENSession.shared.authenticate(with: self, preferRegistration: false, completion: { error in
        if error == nil {
          ENSession.shared.fetchSimpleMemoNoteBook()
          self.evernoteItem.tintColor = SMColor.tint
        } else {
          printLog(message: error.debugDescription)
        }
      })
    }
  }

  /// 搜索
  @objc func search() {
    navigationItem.rightBarButtonItems?.removeAll(keepingCapacity: true)
    navigationItem.leftBarButtonItems?.removeAll(keepingCapacity: true)
    searchBar.searchBarStyle = .minimal
    searchBar.setShowsCancelButton(true, animated: true)
    searchBar.delegate = self
    searchBar.backgroundColor = backgroundColor
    navigationItem.titleView = searchView
    searchView.frame = navigationController!.navigationBar.bounds
    searchView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    searchView.addSubview(searchBar)

    var margin: CGFloat = 0
    let deviceModel = UIDevice.current.model
    if deviceModel == "iPad" || deviceModel == "iPad Simulator" {
      margin = 30
    } else {
      margin = 10
    }

    searchBar.frame = CGRect(x: 0, y: 0, width: searchView.width - margin, height: searchView.height)
    searchBar.becomeFirstResponder()
    isSearching = true
    if !searchBar.text!.isEmpty {
      fetchSearchResults(searchBar.text!)
    }
    collectionView?.reloadData()
  }

  /// 新memo
  @objc func addMemo() {
    navigationController?.pushViewController(MemoViewController(), animated: true)
  }

}

// MARK: - UISearchBarDelegate

extension MemoListViewController: UISearchBarDelegate {

  fileprivate func fetchSearchResults(_ searchText: String) {
    let request = Memo.defaultRequest()
    request.predicate = NSPredicate(format: "text CONTAINS[cd] %@", searchText)
    let sortDescriptor = NSSortDescriptor(key: "updateDate", ascending: false)
    request.sortDescriptors = [sortDescriptor]
    var results: [AnyObject]?
    do {
        if #available(iOS 10.0, *) {
            results = try CoreDataStack.default.managedContext.fetch(request)
        } else {
            // Fallback on earlier versions
        }
    } catch {
      if let error = error as NSError? {
        printLog(message: "\(error.userInfo)")
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }

    if let resultMemos = results as? [Memo] {
      searchResults = resultMemos
    }
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    fetchSearchResults(searchText)
    collectionView?.reloadData()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    searchView.removeFromSuperview()
    setNavigationBar()
    isSearching = false
    searchResults.removeAll(keepingCapacity: false)
    collectionView?.reloadData()
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

}

// MARK: - NSFetchedResultsControllerDelegate

extension MemoListViewController: NSFetchedResultsControllerDelegate {

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

    // 如果处于搜索状态, 内容更新了,就重新搜索,重新加载数据
    if isSearching, let searchText = searchBar.text {
      fetchSearchResults(searchText)
      collectionView?.reloadData()
      return
    }

    switch type {
    case .insert:
      collectionView?.insertItems(at: [newIndexPath!])
    case .update:
      collectionView?.reloadItems(at: [indexPath!])
    case .delete:
      collectionView?.deleteItems(at: [indexPath!])
    case .move:
      collectionView?.moveItem(at: indexPath!, to:newIndexPath!)
      collectionView?.reloadItems(at: [newIndexPath!])
    }
  }

}

// MARK: - UIViewControllerPreviewingDelegate

extension MemoListViewController: UIViewControllerPreviewingDelegate {

  func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
    guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }

    let detailViewController = MemoViewController()
    if #available(iOS 10.0, *) {
        let memo = isSearching ? searchResults[indexPath.row] : fetchedResultsController.object(at: indexPath)
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: 350)
        previewingContext.sourceRect = cell.frame
        detailViewController.memo = memo
        return detailViewController
    } else {
        // Fallback on earlier versions
        return MemoViewController()
    }

  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    show(viewControllerToCommit, sender: self)
  }

}

// MARK: - Evernote

private extension MemoListViewController {

  func uploadMemoToEvernote() {
    if !ENSession.shared.isAuthenticated || SimpleMemoNoteBook == nil {
      return
    }
    // 取出所有没有上传的memo
    let predicate = NSPredicate(format: "isUpload == %@", false as CVarArg)
    let request = Memo.defaultRequest()
    request.predicate = predicate
    var results: [AnyObject]?
    do {
        if #available(iOS 10.0, *) {
            results = try CoreDataStack.default.managedContext.fetch(request)
        } else {
            // Fallback on earlier versions
        }
    } catch {
      printLog(message: error.localizedDescription)
    }

    if let unUploadMemos = results as? [Memo] {
      for unUploadMemo in unUploadMemos {
        ENSession.shared.uploadMemoToEvernote(unUploadMemo)
      }
    }
  }

  @objc func updateMemoFromEvernote() {
    if !ENSession.shared.isAuthenticated || SimpleMemoNoteBook == nil {
      return
    }

    ENSession.shared.downloadNotesInSimpleMemoNotebook { [weak self] (results, error) in
      if let results = results {
        self?.updateMemos(with: results)
      } else if let error = error {
        printLog(message: error.localizedDescription)
      }
    }
  }

  func updateMemos(with results: [ENSessionFindNotesResult]) {
    if #available(iOS 10.0, *) {
        guard let currentMemos = fetchedResultsController.fetchedObjects else {
            return
        }
        var tempMemos = currentMemos
        let currentGuid = tempMemos.flatMap { $0.guid ?? $0.noteRef?.guid }
        let resultsGuids = results.map { $0.noteRef?.guid }
        for (index, guid) in resultsGuids.enumerated() {
            guard let guid = guid else { continue }
            let result = results[index]
            if !currentGuid.contains(guid) {
                ENSession.shared.downloadNewMemo(with: result.noteRef!, created: result.created, updated: result.updated)
                continue
            }
            
            var currentMemo: Memo?
            for (index, memo) in tempMemos.enumerated() {
                let memoGuid = memo.guid ?? memo.noteRef?.guid
                if memoGuid == guid {
                    currentMemo = memo
                    tempMemos.remove(at: index)
                    break
                }
            }
            guard let memo = currentMemo else {
                ENSession.shared.downloadNewMemo(with: result.noteRef!, created: result.created, updated: result.updated)
                continue
            }
            
            if !memo.isUpload {
                memo.guid = nil
                memo.noteRef = nil
                CoreDataStack.default.saveContext()
                ENSession.shared.downloadNewMemo(with: result.noteRef!, created: result.created, updated: result.updated)
                continue
            }
            
            if memo.updateDate != result.created {
                ENSession.shared.update(memo, noteRef: result.noteRef!, created: result.created, updated: result.updated)
            }
        }
    } else {
        // Fallback on earlier versions
    }
  
  }

}
