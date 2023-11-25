//
//  SessionList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

struct TargetList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedTargetID: URL?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Target.name, ascending: true)],
        predicate: NSPredicate(format: "name !=[cd] %@", Target.unknownTargetName),
        animation: .default)
    private var targets: FetchedResults<Target>

    var body: some View {
        List(selection: $selectedTargetID) {
            ForEach(targets) { target in
                TargetListItem(target: target)
            }
        }
    }
}
