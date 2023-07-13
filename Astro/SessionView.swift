//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct SessionView: View {
    @Binding var session: Session?

    @State var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.reverse)
    ]
    @State private var selection = Set<File.ID>()

    var table: some View {
        let fileSets = session?.fileSets?.allObjects as? [SessionFileSet] ?? []
        let files = fileSets.flatMap { $0.files?.allObjects as? [File] ?? [] }

        return Table(files, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Date", value: \.timestamp!) { file in
                Text(file.timestamp!.formatted(date: .abbreviated, time: .omitted))
            }

//            TableColumn("Days to Maturity", value: \.daysToMaturity) { plant in
//                Text(plant.daysToMaturity.formatted())
//            }
//
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
        }
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        table
//            .focusedSceneValue(\.garden, gardenBinding)
//            .focusedSceneValue(\.selection, $selection)
//            .searchable(text: $searchText)
//            .toolbar {
//                DisplayModePicker(mode: $mode)
//                Button(action: addPlant) {
//                    Label("Add Plant", systemImage: "plus")
//                }
//            }
//            .navigationTitle(garden.name)
//            .navigationSubtitle("\(garden.displayYear)")
    }
}

// struct SessionView_Previews: PreviewProvider {
//    static var previews: some View {
//        SessionView(session: Session.example)
//    }
// }
