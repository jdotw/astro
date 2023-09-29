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
            CalibrationFiltersView(session: session, orientation: .leftToRight, fileType: "Flat")
        }
    }
}
