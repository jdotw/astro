//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct SessionView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var sessionID: Session.ID?
    @FetchRequest(entity: Session.entity(),
                  sortDescriptors: [])
    var results: FetchedResults<Session>

    @State private var selectedFileIDs: Set<File.ID> = []
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.reverse)
    ]

    var table: some View {
        Table(files!, selection: $selectedFileIDs, sortOrder: $sortOrder) {
            TableColumn("Timestamp", value: \.timestamp) {
                Text($0.timestamp.formatted(date: .omitted, time: .shortened))
            }
            .width(100)

            TableColumn("Target", value: \.target!.name)
                .width(100)

            TableColumn("Type", value: \.type) { file in
                Text(file.type.localizedCapitalized)
            }
            .width(50)

            TableColumn("Filter", value: \.filter!) { file in
                Text(file.filter?.localizedCapitalized ?? "N/A")
            }
            .width(50)

//            TableColumn("Date Planted", value: \.datePlanted) { plant in
//                Text(plant.datePlanted.formatted(date: .abbreviated, time: .omitted))
//            }
//
//            TableColumn("Harvest Date", value: \.harvestDate) { plant in
//                Text(plant.harvestDate.formatted(date: .abbreviated, time: .omitted))
//            }
//
//            TableColumn("Last Watered", value: \.lastWateredOn) { plant in
//                Text(plant.lastWateredOn.formatted(date: .abbreviated, time: .omitted))
//            }
//
//            TableColumn("Favorite", value: \.favorite, comparator: BoolComparator()) { plant in
//                Toggle("Favorite", isOn: gardenBinding[plant.id].favorite)
//                    .labelsHidden()
//            }
//            .width(50)
        }
    }

    var body: some View {
//        if let session = session {
        // yer item's here, do what ye want with it
        HStack {
            table
            VStack {
                FileView(fileIDs: $selectedFileIDs)
            }
            .frame(width: 250.0)
        }
//        } else {
//            // no item? handle it, mate
//            Text("No session")
//        }
    }
}

extension SessionView {
    var session: Session? {
        if let sessionID = sessionID {
            results.nsPredicate = NSPredicate(format: "id == %@", sessionID)
            return results.first!
        } else {
            return nil
        }
    }

    var files: [File]? {
        guard let session = session else {
            return nil
        }
        return session.files?.sortedArray(using: [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)]) as? [File]
    }
}

// struct SessionView_Previews: PreviewProvider {
//    static var previews: some View {
//        SessionView(session: Session.example)
//    }
// }
