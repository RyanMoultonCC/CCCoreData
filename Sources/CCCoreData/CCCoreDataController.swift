//
//  CCCoreDataController.swift
//
//  Created by Ryan Moulton on 8/13/15.
//  Copyright (c) 2015 Clever Coding. All rights reserved.
//

import CoreData

public class CCCoreDataController: NSObject {
	public var modelName: String = ""
	public var databaseFileName: String = ""
	public var moc: NSManagedObjectContext?
	
	
	//Singleton instance of CCCoreDataController
	public static let shared = CCCoreDataController()
	
	
	
	public lazy var applicationDocumentsDirectory: URL = {
		// The directory the application uses to store the Core Data store file. This code uses a directory named "Main.Carnival_Trivia" in the application's documents Application Support directory.
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls[urls.count-1] 
	}()
	
	
	public lazy var managedObjectModel: NSManagedObjectModel = {
		//Make sure the model name is not empty. This needs to be set when the application launches
		guard modelName.count != 0 else { fatalError("model name needs to be set before trying to access CCCoreData") }
		
		// The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
		let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
	}()
	
	
	public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
		guard databaseFileName.count != 0 else { fatalError("database file name needs to be set before trying to access CCCoreData") }
		
		// The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
		// Create the coordinator and store
		
		var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let url = self.applicationDocumentsDirectory.appendingPathComponent("\(databaseFileName).sqlite")
		let url_string = url.absoluteString;
		print("database url:  \(url_string)");
		
		//Check if we have a source file to copy from
		if !FileManager.default.fileExists(atPath: url.path), let sourceSQLiteURL = Bundle.main.url(forResource: databaseFileName, withExtension: "sqlite") {
			let sourceSqliteURLs = [sourceSQLiteURL/*, NSBundle.mainBundle().URLForResource("Carnival_Trivia", withExtension: "sqlite-wal")!, NSBundle.mainBundle().URLForResource("Carnival_Trivia", withExtension: "sqlite-shm")!*/]
			
			let destSqliteURLs = [self.applicationDocumentsDirectory.appendingPathComponent("\(databaseFileName).sqlite")/*,
				self.applicationDocumentsDirectory.URLByAppendingPathComponent("Carnival_Trivia.sqlite-wal"),
				self.applicationDocumentsDirectory.URLByAppendingPathComponent("Carnival_Trivia.sqlite-shm")*/]
			
			var error:NSError? = nil
			for index in 0 ..< sourceSqliteURLs.count {
				do {
					try FileManager.default.copyItem(at: sourceSqliteURLs[index], to: destSqliteURLs[index])
				} catch var error1 as NSError {
					error = error1
				} catch {
					fatalError()
				}
			}
		}
		
		var error: NSError? = nil
		var failureReason = "There was an error creating or loading the application's saved data."
		do {
			try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSSQLitePragmasOption: ["journal_mode": "DELETE"]])
		} catch var error1 as NSError {
			error = error1
			coordinator = nil
			// Report any error we got.
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
			dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
			dict[NSUnderlyingErrorKey] = error
			error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			// Replace this with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
			abort()
		} catch {
			fatalError()
		}
		
		return coordinator
	}()
	
	
	public lazy var managedObjectContext: NSManagedObjectContext? = {
		if (self.moc != nil){
			return self.moc
		}
		
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		let coordinator = self.persistentStoreCoordinator
		if coordinator == nil {
			return nil
		}
		
		self.moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
		self.moc!.persistentStoreCoordinator = coordinator
		return self.moc
	}()
	
	
	
	///Creates a child context of the master managedObjectContext with a private queue concurrency type
	///- returns: NSManagedObjectContext
	public class func createChildManagedObjectContext() -> NSManagedObjectContext{
		let childContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
		childContext.parent = CCCoreDataController.shared.managedObjectContext
		return childContext
	}
	
	
	///Creates a private managedObjectContext with a private queue concurrency type
	///- returns: NSManagedObjectContext
	public class func createPrivateManagedObjectContext() -> NSManagedObjectContext {
		let privateContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
		privateContext.persistentStoreCoordinator = CCCoreDataController.shared.persistentStoreCoordinator
		return privateContext
	}
	
	
	///Saves the managed object context. In a future version this will be changed to the master managed object context when it becomes necessary to add a background or child context
	///- returns: Void
	public func saveContext () {
		if let moc = self.managedObjectContext {
			var error: NSError? = nil
			if moc.hasChanges {
				do {
					try moc.save()
				} catch let error1 as NSError {
					error = error1
					// Replace this implementation with code to handle the error appropriately.
					// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
					NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
					abort()
				}
			}
		}
	}
}
