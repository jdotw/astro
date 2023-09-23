//
//  CalibrationCandidateSessionView.swift
//  Astro
//
//  Created by James Wilson on 22/9/2023.
//

import SwiftUI

struct CalibrationCandidateSessionView: View {
    @ObservedObject var session: Session
    @FetchRequest var files: FetchedResults<File>

    init(session: Session) {
        self.session = session
        _files = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "session = %@", session),
            animation: .default)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(session.dateString)
            Text(uniqueUncalibratedFilterNames.joined(separator: ", "))
        }.draggable(session.objectID.uriRepresentation())
    }

    var uniqueUncalibratedFilterNames: [String] {
        let filters = files.compactMap { $0.calibrationSession != nil ? nil : $0.filter }
        return Array(Set(filters)).sorted()
    }
}
