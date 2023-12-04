//
//  Persistence.swift

//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newFile = File(context: viewContext)
            newFile.timestamp = Date()
            newFile.name = "file-\(Int.random(in: 0..<100)).fits"
            newFile.contentHash = "md5"
            newFile.type = .light
            newFile.bookmark = Data()
            newFile.url = URL(fileURLWithPath: "/Users/jwilson/Downloads/IMG_0001.fits")
        }
        for i in 1..<4 {
            let session = Session(context: viewContext)
            session.dateString = "2023070\(i)"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Astro")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let docsURL = URL.documentsDirectory!
            if !FileManager.default.fileExists(atPath: docsURL.path(percentEncoded: false)) {
                try! FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)
            }
            container.persistentStoreDescriptions.first!.url = docsURL.appending(path: "Library.sqlite")
        }
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            print("store: \(storeDescription.url!)")
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        // JW HACK
//        let url = URL(filePath: "/Users/jwilson/Desktop/integrated-image.xisf")
//        let xisfFile = XISFFile(url: url)
//        let headerData = xisfFile.headerData
//        print("JW: headerData.count = ", headerData?.count ?? -1)
//        let headers = xisfFile.parseHeaders()
//        print("HEADERS: ", headers ?? "none")
//        let firstImage = xisfFile.images.first!
//        let imageHeaders = firstImage.fitsKeywords
//        print("FITS HEADERS: ", imageHeaders)
//
//        let importer = XISFFileImporter(url: url,
//                                        context: container.viewContext)
//        do {
//            guard let importedFile = try importer.importFile() else {
//                print("NO FILE IMPORTED")
//                return
//            }
//            print("IMPORTED: ", importedFile)
//            let processor = FileProcessOperation(fileObjectID: importedFile.objectID)
//            FileProcessController.shared.queue.addOperation(processor)
//
//        } catch {
//            switch error {
//            case FileImportError.alreadyExists(let file):
//                print("ALREADY EXISTS: ", file)
//                let processor = FileProcessOperation(fileObjectID: file.objectID)
//                FileProcessController.shared.queue.addOperation(processor)
//            default:
//                print("IMPORT ERROR: ", error)
//            }
//        }
        // END JW HACK
    }
}

extension NSManagedObjectContext {
    func managedObjectID(forURIRepresentation url: URL) -> NSManagedObjectID? {
        return PersistenceController.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
    }
}
