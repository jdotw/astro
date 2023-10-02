//
//  CalibrationView.swift
//  Astro
//
//  Created by James Wilson on 17/9/2023.
//

import SwiftUI

struct CalibrationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: Session
    var filter: Filter?

    var body: some View {
        if let filter {
            CalibrationSessionFilterView(session: session, filter: filter)
        } else {
            CalibrationSessionView(session: session)
        }
    }
}
