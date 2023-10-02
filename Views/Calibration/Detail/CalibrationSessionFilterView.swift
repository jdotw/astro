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

    var isFlat: Bool {
        guard let files = session.files?.allObjects as? [File] else { return false }
        print("FILES: ", files)
        return files.first { file in
            file.type.lowercased() == "flat"
        } != nil
    }

    var body: some View {
        if let filter {
            if isFlat {
                CalibrationSessionFilterFlatsView(session: session, filter: filter)
            } else {
                CalibrationSessionFilterLightView(session: session, filter: filter)
            }
        } else {
            Text("No Filter")
        }
    }
}
