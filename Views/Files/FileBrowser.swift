//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

enum FileBrowserViewMode: String, CaseIterable, Identifiable {
    var id: Self { self }
    case approve
    case table
    case grid
}

enum FileBrowserSource {
    case session(Session)
    case target(Target)
    case selection([NSManagedObjectID])
    case all
}

struct FileBrowser: View {
    var source: FileBrowserSource
    var columns: [FileTableColumns] = FileTableColumns.allCases

    @Binding var navStackPath: [File]
    @Binding var viewMode: FileBrowserViewMode

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)])
    private var files: FetchedResults<File>

    var body: some View {
        VStack {
            switch viewMode {
            case .approve:
                FileApproval(source: source)
            case .table:
                FileTable(source: source, columns: columns, navStackPath: $navStackPath)
            case .grid:
                FileGrid(source: source, navStackPath: $navStackPath)
            }
        }
        .toolbar {
            ToolbarItem {
                FileBrowserModePicker(mode: $viewMode)
            }
        }
    }
}

extension FileBrowserSource {
    var fileFetchRequest: FetchRequest<File> {
        var predicate: NSPredicate?
        switch self {
        case .all:
            predicate = NSPredicate(format: "rejected = false")
        case .session(let session):
            predicate = NSPredicate(format: "session == %@ AND rejected = false", session)
        case .target(let target):
            predicate = NSPredicate(format: "target == %@ AND rejected = false", target)
        case .selection(let selectedIDs):
            print("IDS: ", selectedIDs)
            predicate = NSPredicate(format: "self IN %@", selectedIDs)
        }
        let sortDescriptors = [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)]
        return FetchRequest<File>(entity: File.entity(),
                                  sortDescriptors: sortDescriptors,
                                  predicate: predicate)
    }

    var defaultSortOrder: [KeyPathComparator<File>] {
        switch self {
        case .target:
            [.init(\.filter, order: SortOrder.forward),
             .init(\.timestamp, order: SortOrder.forward)]
        default:
            [.init(\.timestamp, order: SortOrder.forward)]
        }
    }
}

extension FileBrowserSource: Equatable {
    static func == (lhs: FileBrowserSource, rhs: FileBrowserSource) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all):
            return true
        case (.session(let lhsSession), .session(let rhsSession)):
            return lhsSession == rhsSession
        case (.target(let lhsTarget), .target(let rhsTarget)):
            return lhsTarget == rhsTarget
        case (.selection(let lhsIDs), .selection(let rhsIDs)):
            return lhsIDs == rhsIDs
        default:
            return false
        }
    }
}
