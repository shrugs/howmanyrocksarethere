//
//  RockMapViewController.swift
//  howmanyrocksarethere
//
//  Created by Matt Condon on 9/11/16.
//  Copyright © 2016 howmanyrocksarethere. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Async

class RockMapViewController: UIViewController {

  var hasCentered = false
  var isFetchingRocks = false

  let locationManager = CLLocationManager()

  lazy var mapView : MKMapView = { [unowned self] in
    let mapView = MKMapView()
    mapView.showsUserLocation = true
    mapView.userTrackingMode = .Follow
    mapView.delegate = self
    return mapView
  }()

  var rocks = [[String: AnyObject]]()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nil, bundle: nil)
    self.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "ic_near_me"), selectedImage: UIImage(named: "ic_near_me"))
    self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(mapView)
    mapView.snp_makeConstraints { make in
      make.edges.equalTo(view)
    }
  }

  func reloadData() {
    for rock in rocks {
      if let lat = rock["lat"] as? Double, lng = rock["lng"] as? Double {
        let ann = RockAnnotation(
          title: (rock["nickname"] ?? "Some Rock") as! String,
          description: "",
          coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
        )

        mapView.addAnnotation(ann)
      }
    }
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
  }

  let regionRadius: CLLocationDistance = 1000
  func centerMapOnLocation(location: CLLocation) {
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
    mapView.setRegion(coordinateRegion, animated: true)
  }

  func fetchRocks(lat lat: Double, lng: Double, radius: Int) {
    isFetchingRocks = true
    Async.userInitiated {
      THE_DATABASE.sharedDatabase.getNearbyRocks(
        lat: lat,
        lng: lng,
        radius: radius
      ) { [weak self] rocks in
        Async.main {
          self?.isFetchingRocks = false
          self?.rocks = rocks
          self?.reloadData()
        }
      }
    }
  }
}

extension RockMapViewController : MKMapViewDelegate {

  func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    if !isFetchingRocks {
      let center = mapView.region.center
      let span = mapView.region.span

      let topRadius = CLLocation(
        latitude: center.latitude,
        longitude: center.longitude + (span.longitudeDelta / 2.0)
      ).distanceFromLocation(CLLocation(latitude: center.latitude, longitude: center.longitude))

      fetchRocks(
        lat: mapView.region.center.latitude,
        lng: mapView.region.center.longitude,
        radius: Int(topRadius)
      )
    }
  }

  func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
    if let loc = userLocation.location where !hasCentered {
      hasCentered = true
      centerMapOnLocation(loc)
    }
  }

  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

    var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("demo")

    if annotation.isEqual(mapView.userLocation) {
      return nil
    }

    if annotationView == nil {
      annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "demo")
      annotationView!.canShowCallout = true
    } else {
      annotationView!.annotation = annotation
    }

    annotationView!.image = UIImage(named: "maprock")

    return annotationView

  }
}



























