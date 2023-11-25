//
//  TargetListItem.swift
//  Astro
//
//  Created by James Wilson on 25/11/2023.
//

import SwiftUI

struct TargetListItem: View {
    let target: Target
    @FetchRequest private var files: FetchedResults<File>
    @FetchRequest private var unreviewedFiles: FetchedResults<File>

    init(target: Target) {
        self.target = target
        _files = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)],
            predicate: NSPredicate(format: "target = %@ AND rejected = false", target))
        _unreviewedFiles = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)],
            predicate: NSPredicate(format: "target = %@ AND reviewed = false AND rejected = false", target))
    }

    var body: some View {
        Label(target.name, systemImage: "scope")
            .badge(files.count)
            .badgeProminence(.standard)
            .badge(unreviewedFiles.count)
            .badgeProminence(unreviewedFiles.count > 0 ? .increased : .decreased)
    }
}
