//
//  SessionList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

struct TargetList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selection: Target?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Target.name, ascending: true)],
        animation: .default)
    private var targets: FetchedResults<Target>

    var body: some View {
        List(selection: $selection) {
            ForEach(targets, id: \.self) { target in
                Label(target.name, systemImage: "scope")
                    .badge(target.files?.count ?? 0)
                    .badgeProminence(.standard)
            }
        }
    }
}
