//
//  hkAccess.swift
//  HKTest
//
//  Created by Bill Snook on 2/5/16.
//  Copyright © 2016 BillSnook. All rights reserved.
//

import Foundation
import HealthKit


class hkAccess {
	
	let hkStore: HKHealthStore!
	
	init() {
		hkStore = HKHealthStore()
	}
	
	class func isAvailable() -> Bool {
		return HKHealthStore.isHealthDataAvailable()
	}
	
	func startThisStore() {
		if hkAccess.isAvailable() {
			let heightType = HKObjectType.quantityTypeForIdentifier( HKQuantityTypeIdentifierHeight)
			let weightType = HKObjectType.quantityTypeForIdentifier( HKQuantityTypeIdentifierBodyMass)
			let dataTypes: Set<HKQuantityType> = [ heightType!, weightType! ]
			hkStore.requestAuthorizationToShareTypes( dataTypes, readTypes: dataTypes, completion: {
				( success, error ) in
				if success {
					print ( "Authorization succeeds" )
				} else {
					print( "Not authorized" )
				}
			})
		}
	}
	
}

