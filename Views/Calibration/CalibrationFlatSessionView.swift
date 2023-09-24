//
//  CalibrationFlatSessionView.swift
//  Astro
//
//  Created by James Wilson on 22/9/2023.
//

import SwiftUI

struct CalibrationFlatSessionView: View {
    @ObservedObject var session: Session
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(alignment: .leading) {
            Text(session.dateString)
            CalibrationFilterNamesView(session: session)
        }
    }
}

struct CalibrationFilterNamesView: View {
    @ObservedObject var session: Session
    @FetchRequest var files: FetchedResults<File>

    init(session: Session) {
        self.session = session
        _files = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "session = %@ AND type =[cd] 'Flat'", session),
            animation: .default)
    }

    var body: some View {
        Text(uniqueFilterNames.joined(separator: ", "))
    }

    private var uniqueFilterNames: [String] {
        let filters = files.compactMap { $0.filter }
        return Array(Set(filters)).sorted()
    }
}

