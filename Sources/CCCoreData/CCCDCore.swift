//
//  CCCDCore.swift
//
//  Created by Ryan Moulton on 6/14/19.
//  Copyright © 2019 Clever Coding. All rights reserved.
//

import Foundation
import CoreData

@objc public protocol RemoteObject {
	var serverId: Int64 { get set }
}

public extension RemoteObject where Self: NSManagedObject {
	
	static func fetchOrCreateObjectWithServerId(_ serverId: Int64, context: NSManagedObjectContext) -> Self {
		if let existing = objectWithServerId(serverId, context: context) { return existing }
		
		let insertedObject = NSEntityDescription.insertNewObject(forEntityName: Self.entity().name!, into: context) as! RemoteObject
		insertedObject.serverId = serverId
		return insertedObject as! Self
	}
	
	
	static func objectWithServerId(_ serverId: Int64, context: NSManagedObjectContext) -> Self? {
		let fetchRequest: NSFetchRequest<Self> = NSFetchRequest(entityName: Self.entity().name!)
		
		let predicate = NSPredicate(format: "serverId == %d", serverId)
		let descriptor = NSSortDescriptor(key: #keyPath(RemoteObject.serverId), ascending: true)
		fetchRequest.predicate = predicate
		fetchRequest.sortDescriptors = [descriptor]
		fetchRequest.fetchLimit = 1
		
		do {
			let results = try context.fetch(fetchRequest)
			return results.first
		} catch {
			print("Failed to fetch object with serverId:\(serverId) error:\(error)")
		}
		return nil
	}
	
	
	
	static func fetchAll(_ context: NSManagedObjectContext) -> [Self] {
		let fetchRequest: NSFetchRequest<Self> = NSFetchRequest(entityName: Self.entity().name!)
		
		do {
			let results = try context.fetch(fetchRequest)
			return results
		} catch {
			print("Failed to fetch objects, error:\(error)")
		}
		return [] as [Self]
	}
}



//CCRemote object match structure of objects on CC Lumen backend
@objc public protocol CCRemoteObject: RemoteObject {
	 var updatedAt: NSDate? { get }
	func assignValuesFromJSON(_ json: [String : AnyObject])
}



public extension CCRemoteObject where Self: NSManagedObject {
	static func lastUpdatedAt(context: NSManagedObjectContext) -> Date {
		let fetchRequest: NSFetchRequest<Self> = NSFetchRequest(entityName: Self.entity().name!)
		let descriptor = NSSortDescriptor(key: #keyPath(CCRemoteObject.updatedAt), ascending: true)
		fetchRequest.sortDescriptors = [descriptor]
		fetchRequest.fetchLimit = 1
		
		do {
			let results = try context.fetch(fetchRequest)
			if results.count == 0 {
				return Date.distantPast
			}
			
			//TODO: adjust for timezones. With Lumen timestamps sending this back is 6 hours behind
			//let timeZoneOffsetString = String(Int(TimeZone.current.secondsFromGMT() / 3600))
			
			return results.first!.updatedAt! as Date
		} catch {
			print("Failed to fetch objects")
		}
		
		//If none exist return distant past
		return Date.distantPast
	}
	
	
	static func processJSON(json : [[String : AnyObject]], context: NSManagedObjectContext) {
		for objectJSON in json {
			if let remoteId = objectJSON["id"] as? Int64 {
				//check for a deleted at date and remove if stored locally. Otherwise fetch or create
				if objectJSON["deleted_at"] != nil && !(objectJSON["deleted_at"] is NSNull) {
					if let object = Self.objectWithServerId(remoteId, context: context) {
						context.delete(object)
					}
				}else {
					//Fetch or Create object and then assign values coming from the server
					let object = Self.fetchOrCreateObjectWithServerId(remoteId, context: context)
					object.assignValuesFromJSON(objectJSON)
				}
			}
		}
	}
}
