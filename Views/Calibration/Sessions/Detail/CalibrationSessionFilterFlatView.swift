//
//  CalibrationSessionFilterFlatView.swift
//  Astro
//
//  Created by James Wilson on 1/10/2023.
//

import SwiftUI

struct CalibrationSessionFilterFlatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: Session
    var filter: Filter?

    var body: some View {
        Text("\(session.dateString) - FLATS \(filter?.name ?? "no filter")")
    }
}
