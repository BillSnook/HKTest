//
//  ViewController.swift
//  HKTest
//
//  Created by Bill Snook on 2/5/16.
//  Copyright © 2016 BillSnook. All rights reserved.
//

import UIKit
import HealthKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

	@IBOutlet var displayLabel: UILabel!
	@IBOutlet var displayView: UIView!
	@IBOutlet var sendButton: UIButton!
	
	var hkStore: HKHealthStore?
	var height, weight: HKQuantitySample?
	var dataToPost: Array<String> = Array()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		displayView.hidden = true
		sendButton.enabled = true // false
		
		if HKHealthStore.isHealthDataAvailable() {
			displayLabel.text = "Healthkit data is available"
			let stepType = HKObjectType.quantityTypeForIdentifier( HKQuantityTypeIdentifierStepCount)
			let dataTypes: Set<HKQuantityType> = [ stepType! ]
			hkStore = HKHealthStore()
			hkStore?.requestAuthorizationToShareTypes( dataTypes, readTypes: dataTypes, completion: {
				( success, error ) in
				if success {
					print ( "Authorization succeeds" )
					self.getData()
				} else {
					print( "Not authorized" )
					dispatch_async( dispatch_get_main_queue() ) {
						self.displayLabel.text = "Healthkit data is available but you have not authorized access"
					}
				}
			})
		}
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func didTouchSendData(sender: AnyObject) {
		dataToPost = Array()
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		let now = NSDate()
		let nowString = dateFormatter.stringFromDate(now)
		dataToPost.append(nowString)
		dataToPost.append("Bill")
		dataToPost.append("<\(nowString),2345>")
		self.postData(dataToPost)
	}

	func getData() {
		dispatch_async( dispatch_get_main_queue() ) {
			self.displayLabel.text = "Checking for Healthkit data"
		}
		
//		let stepsCount = HKQuantityType.quantityTypeForIdentifier( HKQuantityTypeIdentifierStepCount )
//		
//		let stepsSampleQuery = HKSampleQuery(sampleType: stepsCount!,
//			predicate: nil,
//			limit: 7,
//			sortDescriptors: nil)
//			{ [unowned self] (query, results, error) in
//				if let results = results as? [HKQuantitySample] {
//					print( "Results: \(results)" )
//				}
//		}
//		
//		// Don't forget to execute the Query!
//		hkStore?.executeQuery(stepsSampleQuery)

		let calendar = NSCalendar.currentCalendar()
		
		let interval = NSDateComponents()
		interval.day = 1
		
		// Set the anchor date to Monday at 3:00 a.m.
		let anchorComponents = calendar.components([.Day, .Month, .Year, .Weekday], fromDate: NSDate())
		
		
		let offset = (7 + anchorComponents.weekday - 2) % 7
		anchorComponents.day -= offset
		anchorComponents.hour = 0
		
		guard let anchorDate = calendar.dateFromComponents(anchorComponents) else {
			fatalError("*** unable to create a valid date from the given components ***")
		}
		
		guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else {
			fatalError("*** Unable to create a step count type ***")
		}
		
		// Create the query
		let query = HKStatisticsCollectionQuery(quantityType: quantityType,
			quantitySamplePredicate: nil,
			options: .CumulativeSum,
			anchorDate: anchorDate,
			intervalComponents: interval)
		
		// Set the results handler
		query.initialResultsHandler = {
			query, results, error in
			
			guard let statsCollection = results else {
				// Perform proper error handling here
				fatalError("*** An error occurred while calculating the statistics: \(error?.localizedDescription) ***")
			}
			
			let endDate = NSDate()
			
			guard let startDate = calendar.dateByAddingUnit(.Day, value: -7, toDate: endDate, options: []) else {
				fatalError("*** Unable to calculate the start date ***")
			}
			
			// Plot the weekly step counts over the past 3 months
			statsCollection.enumerateStatisticsFromDate(startDate, toDate: endDate) { [unowned self] statistics, stop in
				
				if let quantity = statistics.sumQuantity() {
					let date = statistics.startDate
					let dateFormatter = NSDateFormatter()
					dateFormatter.dateFormat = "EEEE"
					let dateString = dateFormatter.stringFromDate( date )
					let value = quantity.doubleValueForUnit(HKUnit.countUnit())
					print("Date: \(dateString), value: \(value)")
					// Call a custom method to plot each data point.
///					self.plotWeeklyStepCount(value, forDate: date)
				}
			}
		}
		
		hkStore?.executeQuery(query)
	}
	
	func readMostRecentSample(sampleType:HKSampleType , completion: ((HKSample!, NSError!) -> Void)!) {
	
		let past = NSDate.distantPast() 
		let now = NSDate()
		let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
			
		let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
		let limit = 1
			
		let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
		{ (sampleQuery, results, error ) -> Void in
			
			if let _ = error {
				completion(nil,error)
				return;
			}
			
			// Get the first sample
			let mostRecentSample = results!.first as? HKQuantitySample
			
			// Execute the completion closure
			if completion != nil {
				completion(mostRecentSample,nil)
			}
		}
		self.hkStore!.executeQuery(sampleQuery)
	}

	func postData( postData: Array<String>) {
//		let postTarget: String = "http://wiki.movinganalytics.com"
//		Alamofire.request(.POST, postTarget, parameters: postData, encoding: .JSON)
//			.responseJSON { response in
//			guard response.result.error == nil else {
//				// got an error in getting the data, need to handle it
//				print("error calling POST on \(postTarget)")
//				print(response.result.error!)
//				return
//			}
//						
//			if let value: AnyObject = response.result.value {
//				// handle the results as JSON, without a bunch of nested if loops
//				let post = JSON(value)
//				print("The post is: " + post.description)
//			}
//		}
		
		if let maURL = NSURL( string: "http://wiki.movinganalytics.com" ) {
		let request = NSMutableURLRequest(URL: maURL)
		request.HTTPMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(postData, options: [])
		
		Alamofire.request(request)
			.responseJSON { response in
				print(response)
				print("Request: \(response.request)")
				print("Response: \(response.response)")
				print("Result: \(response.result)")
				print("Data: \(response.data)")
// do whatever you want here
//				switch response.result {
//				case .Failure(_, let error):
//					print(error)
//				case .Success(let responseObject):
//					print(responseObject)
//				}
			}
		}
	}
}

