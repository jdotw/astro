//
//  CalibrationLightSessionView.swift
//  Astro
//
//  Created by James Wilson on 22/9/2023.
//

import SwiftUI

struct CalibrationLightSessionView: View {
    @ObservedObject var session: Session
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(alignment: .trailing) {
            Text(session.dateString)
            UncalibratedFilterNamesView(session: session)
        }
    }
}

struct UncalibratedFilterNamesView: View {
    @ObservedObject var session: Session
    @FetchRequest var files: FetchedResults<File>

    init(session: Session) {
        self.session = session
        _files = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "session = %@ AND calibrationSession = nil", session),
            animation: .default)
    }

    var body: some View {
        let uniqueUncalibratedFilterNames = self.uniqueUncalibratedFilterNames
        if uniqueUncalibratedFilterNames.count > 0 {
            Text(uniqueUncalibratedFilterNames.joined(separator: ", "))
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
        } else {
            Image(systemName: "checkmark.circle").foregroundColor(.green)
        }
    }

    private var uniqueUncalibratedFilterNames: [String] {
        let filters = files.compactMap { $0.filter }
        return Array(Set(filters)).sorted()
    }
}

extension Session {}
