//
//  CalibrationCandidateSessionView.swift
//  Astro
//
//  Created by James Wilson on 22/9/2023.
//

import SwiftUI

struct CalibrationCandidateSessionView: View {
    @ObservedObject var session: Session

    var body: some View {
        VStack(alignment: .leading) {
            Text(session.dateString)
            Text(session.uniqueUncalibratedFilterNames.joined(separator: ", "))
        }.draggable(session.objectID.uriRepresentation())
    }
}

extension Session {
    var uniqueUncalibratedFilterNames: [String] {
        guard let files = files?.allObjects as? [File] else { return [] }
        let filters = files.compactMap { $0.calibrationSession != nil ? nil : $0.filter }
        return Array(Set(filters)).sorted()
    }
}
