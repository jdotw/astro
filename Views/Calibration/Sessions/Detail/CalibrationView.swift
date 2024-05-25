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
    @AppStorage("calibrationViewMode") private var calibrationViewMode: CalibrationViewMode = .sessions
    @Binding var navStackPath: [File]

    var body: some View {
        VStack {
            switch calibrationViewMode {
            case .sessions:
                CalibrationSessionView(session: session)
            case .files:
                CalibrationFileTable(session: session, navStackPath: $navStackPath)
            }
        }
        .toolbar {
            ToolbarItem {
                CalibrationViewModePicker(mode: $calibrationViewMode)
            }
        }
    }
}
