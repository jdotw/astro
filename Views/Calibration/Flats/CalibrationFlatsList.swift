//
//  CalibrationFlatsList.swift
//  Astro
//
//  Created by James Wilson on 8/12/2024.
//

import SwiftUI

struct CalibrationFlatsList: View {
    @FetchRequest(entity: Session.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: false)],
                  predicate: NSPredicate(format: "SUBQUERY(files, $file, $file.typeRawValue == %@).@count > 0", FileType.flat.rawValue))
    var sessions: FetchedResults<Session>
    
    @Binding var selectedSessionID: URL?
    
    var body: some View {
        List(selection: $selectedSessionID) {
            ForEach(sessions) { session in
                Label(session.date.formatted(date: .abbreviated, time: .omitted), systemImage: "moon")
            }
        }
    }
}
