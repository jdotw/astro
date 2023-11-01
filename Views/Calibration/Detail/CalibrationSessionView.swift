//
//  CalibrationSessionView.swift
//  Astro
//
//  Created by James Wilson on 1/10/2023.
//

import SwiftUI

struct CalibrationSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: Session
    var type: SessionType

    var body: some View {
        Text("\(session.dateString) - \(type.rawValue)")
    }
}
