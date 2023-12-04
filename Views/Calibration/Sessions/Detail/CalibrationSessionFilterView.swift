//
//  CalibrationSessionFilterView.swift
//  Astro
//
//  Created by James Wilson on 1/10/2023.
//

import SwiftUI

struct CalibrationSessionFilterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: Session
    var filter: Filter?
    var type: SessionType

    var body: some View {
        if let filter {
            switch type {
            case .calibration:
                CalibrationSessionFilterFlatsView(session: session, filter: filter)
            case .light:
                CalibrationSessionFilterLightView(session: session, filter: filter)
            }
        } else {
            Text("No Filter")
        }
    }
}
