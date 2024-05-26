//
//  Session+CoreDataProperties.swift
//
//
//  Created by James Wilson on 13/7/2023.
//
//  This file was NOT automatically generated and can be edited
//  We had to do this because CoreData is so bad.
//

import CoreData
import Foundation

@objc(Session)
public class Session: NSManagedObject {}

public extension Session {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged var dateString: String
    @NSManaged var date: Date
    @NSManaged var files: NSSet?
    @NSManaged var flatCalibrationForFiles: NSSet?
    @NSManaged var darkCalibrationForFiles: NSSet?
    @NSManaged var biasCalibrationForFiles: NSSet?
}

// MARK: Generated accessors for files

public extension Session {
    @objc(addFilesObject:)
    @NSManaged func addToFiles(_ value: File)

    @objc(removeFilesObject:)
    @NSManaged func removeFromFiles(_ value: File)

    @objc(addFiles:)
    @NSManaged func addToFiles(_ values: NSSet)

    @objc(removeFiles:)
    @NSManaged func removeFromFiles(_ values: NSSet)
}

extension Session: Identifiable {
    public var id: URL {
        objectID.uriRepresentation()
    }
}

public extension Session {
    func setCalibration(session: Session?, forFilter filter: Filter, type: FileType) {
        guard let files = files?.allObjects as? [File] else { return }
        files.filter { $0.filter == filter }.forEach { file in
            switch type {
            case .flat:
                file.flatCalibrationSession = session
            case .bias:
                file.biasCalibrationSession = session
            case .dark:
                file.darkCalibrationSession = session
            default:
                break
            }
            print("SET: ", file)
        }
    }

    func configuredCalibrationSessions(forFilter filter: Filter, type: FileType) -> [Session]? {
        guard let files = files?.allObjects as? [File] else { return nil }
        let filesForFilter = files.filter { $0.filter == filter }
        let uniqueCalibrationSessions = Set(filesForFilter.compactMap { file in
            switch type {
            case .flat:
                return file.flatCalibrationSession
            case .bias:
                return file.biasCalibrationSession
            case .dark:
                return file.darkCalibrationSession
            default:
                return nil
            }
        })
        return Array(uniqueCalibrationSessions)
    }

    func suggestedCalibrationSession(forFilter filter: Filter, type: FileType, candidates: [Session]?) -> Session? {
        let sortedCandidates = candidates?.sorted(by: { a, b in
            let deltaA = abs(a.date.timeIntervalSince(self.date))
            let deltaB = abs(b.date.timeIntervalSince(self.date))
            return deltaA < deltaB
        })
        return sortedCandidates?.first
    }

    func resolvedCalibrationSession(forFilter filter: Filter, type: FileType) -> Session? {
        let candidateFetchReq = NSFetchRequest<Session>(entityName: "Session")
        switch type {
        case .dark, .bias:
            candidateFetchReq.predicate = NSPredicate(format: "SUBQUERY(files, $file, $file.typeRawValue = %@).@count > 0", type.rawValue)
        default:
            candidateFetchReq.predicate = NSPredicate(format: "SUBQUERY(files, $file, $file.typeRawValue = %@ AND $file.filter = %@).@count > 0", type.rawValue, filter)
        }
        let candidates = try? managedObjectContext?.fetch(candidateFetchReq)

        if let configured = configuredCalibrationSessions(forFilter: filter, type: type),
           configured.count > 0
        {
            if configured.count == 1 {
                return configured.first
            } else {
                return nil
            }
        } else {
            return suggestedCalibrationSession(forFilter: filter, type: type, candidates: candidates)
        }
    }

    var uniqueFilters: [Filter] {
        guard let files = files?.allObjects as? [File] else { return [] }
        return Array(Set(files.compactMap { $0.filter }))
    }

    func hasUncalibratedFiles(forFilter filter: Filter, type: FileType) -> Bool {
        let calSession = resolvedCalibrationSession(forFilter: filter, type: type)
        if calSession == nil {
            return true
        } else {
            return false
        }
    }

    func hasUncalibratedFiles(ofType type: FileType) -> Bool {
        let filters = uniqueFilters
        let uncalFilter = filters.first { filter in
            hasUncalibratedFiles(forFilter: filter, type: type)
        }
        if uncalFilter == nil {
            return false
        } else {
            return true
        }
    }

    var hasUncalibratedFiles: Bool {
        let hasUncalFlats = hasUncalibratedFiles(ofType: .flat)
        let hasUncalBias = hasUncalibratedFiles(ofType: .bias)
        let hasUncalDark = hasUncalibratedFiles(ofType: .dark)
        return hasUncalFlats || hasUncalBias || hasUncalDark
    }

    func candidateFlats(forFilter filter: Filter) -> [File] {
        guard let files = files?.allObjects as? [File] else { return [] }
        return files.compactMap { file in
            if file.filter == filter, file.type == .flat {
                return file
            } else {
                return nil
            }
        }
    }

    func candidateFlat(forFilter filter: Filter) -> File? {
        guard let files = files?.allObjects as? [File] else { return nil }
        return files.first { file in
            file.filter == filter && file.type == .flat
        }
    }
}
