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
import Charts

typealias	chartData = Array<Dictionary<String,String>>


class ViewController: UIViewController, UIGestureRecognizerDelegate {

	@IBOutlet var displayLabel: UILabel!
	@IBOutlet weak var barChartView: BarChartView!
	@IBOutlet var sendButton: UIButton!
	
	@IBOutlet weak var slider: UIView!
	
	var hkStore: HKHealthStore?
	var height, weight: HKQuantitySample?
	var dataToPost: chartData = Array()
	let dateFormatter = NSDateFormatter()
	let dowFormatter = NSDateFormatter()
	
	override func viewDidLoad() {
		super.viewDidLoad()

		barChartView.hidden = true
		sendButton.enabled = true // false
		
		if HKHealthStore.isHealthDataAvailable() {
			displayLabel.text = "Healthkit data is available"
			let stepType = HKObjectType.quantityTypeForIdentifier( HKQuantityTypeIdentifierStepCount)
			let dataTypes: Set<HKQuantityType> = [ stepType! ]
			hkStore = HKHealthStore()
			hkStore?.requestAuthorizationToShareTypes( [], readTypes: dataTypes, completion: {
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
			dispatch_async( dispatch_get_main_queue() ) {
				self.setupChart()
				self.setupSlider()
			}
		} else {
			displayLabel.text = "Healthkit is not available"
		}
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func didTouchSendData(sender: AnyObject) {
		self.postData(dataToPost)
	}

	func getData() {
		dispatch_async( dispatch_get_main_queue() ) {
			self.displayLabel.text = "Checking for Healthkit data"
		}
		
		let calendar = NSCalendar.currentCalendar()
		
		let interval = NSDateComponents()
		interval.day = 1
		
		// Set the anchor date to Monday at midnight
		let anchorComponents = calendar.components([.Day, .Month, .Year, .Weekday], fromDate: NSDate())
//		let offset = (7 + anchorComponents.weekday - 2) % 7
		anchorComponents.day -= 0 // offset
		anchorComponents.hour = 0
		
		guard let anchorDate = calendar.dateFromComponents(anchorComponents) else {
			print("*** unable to create a valid date from the given components ***")
			return
		}
		
		guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else {
			print("*** Unable to create a step count type ***")
			return
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
				print("*** An error occurred while calculating the statistics: \(error?.localizedDescription) ***")
				return
			}
			
			let endDate = NSDate()
			
			guard let startDate = calendar.dateByAddingUnit(.Day, value: -6, toDate: endDate, options: []) else {
				print("*** Unable to calculate the start date ***")
				return
			}
			
			// Plot the weekly step counts over the past 3 months
			self.initStepCount()
			statsCollection.enumerateStatisticsFromDate(startDate, toDate: endDate) { [unowned self] statistics, stop in
				
				if let quantity = statistics.sumQuantity() {
					let date = statistics.startDate
					let value = quantity.doubleValueForUnit(HKUnit.countUnit())
					
					// Call a custom method to plot each data point.
					self.nextStepCount(value, forDate: date)
				}
			}
			print( "Got data" )
			dispatch_async( dispatch_get_main_queue() ) {
				self.fillChart()
			}
		}
		
		hkStore?.executeQuery(query)
	}
	
	func initStepCount() {
		dateFormatter.dateFormat = "yyyy-MM-dd"
		dowFormatter.dateFormat = "EEEEEE"
		
		dataToPost = Array()
	}
	func nextStepCount( steps: Double, forDate: NSDate ) {
		let dayStr = dowFormatter.stringFromDate(forDate)
		let dateStr = dateFormatter.stringFromDate(forDate)
		let stepsInt = Int( steps )
		let stepsStr = String( stepsInt )
		let dataDictionary = ["dayOfWeek":dayStr,"date":dateStr,"steps":stepsStr]
		dataToPost.append( dataDictionary )
	}
	
	func postData( postData: chartData) {
		
		if let maURL = NSURL( string: "http://wiki.movinganalytics.com" ) {
			let request = NSMutableURLRequest(URL: maURL)
			request.HTTPMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
			var sendData: Array<AnyObject> = Array()
			let dateStr = dateFormatter.stringFromDate( NSDate() )
			sendData.append( dateStr )
			sendData.append( "Bill - Steps Per Day" )
			for chartElement in postData {
				let chartString = "<\(chartElement["date"]!),\(chartElement["steps"]!)>"
				sendData.append( chartString )
			}
			request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(sendData, options: [])
//			print( sendData )

			Alamofire.request(request)
				.responseJSON { response in
					print(response)
				}

		}
	}
	
	func setupChart() {
		barChartView.noDataText = "Preparing data..."
		barChartView.backgroundColor = UIColor.whiteColor()
		barChartView.hidden = false
		barChartView.descriptionText = ""
		barChartView.xAxis.labelPosition = .Top
		barChartView.rightAxis.enabled = false
	}
	
	func fillChart() {
		var days: [String?]? = []
		
		var dataEntries: [BarChartDataEntry] = []
		var i = 0
		for chartElement in dataToPost {
            days!.append( chartElement["dayOfWeek"]! )
            
			let dayOfWeek = (chartElement["steps"]! as NSString).doubleValue
			let dataEntry = BarChartDataEntry( value: dayOfWeek, xIndex: i++ )
			dataEntries.append(dataEntry)
        }
		
		let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "Daily Steps")
		chartDataSet.colors = [UIColor.orangeColor()]
		let chartData = BarChartData(xVals: days, dataSet: chartDataSet)
		barChartView.data = chartData

	}
	
	func setupSlider() {
		let gesture = UIPanGestureRecognizer(target: self, action: Selector("didSlide:"))
		barChartView.addGestureRecognizer( gesture )
		gesture.delegate = self

	}
	
	func didSlide(gesture: UIPanGestureRecognizer) {
		let translation = gesture.translationInView(self.view)
		print( "x: \(translation.x)" )
		
		// Use translation.y to change the position of your customView, e.g.
//		barChartView.frame.origin.x = translation.x
		var newX = -translation.x
		let maxX = view.bounds.size.width / 2.0
		if newX < 0 {
			newX = 0
		} else if newX > maxX {
			newX = maxX
		}
		
		slider.frame.origin.x = newX
	}
}

