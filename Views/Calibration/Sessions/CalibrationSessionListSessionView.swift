//
//  CalibrationSessionListSessionView.swift
//  Astro
//
//  Created by James Wilson on 22/10/2023.
//

import SwiftUI

struct CalibrationSessionListSessionView: View {
    @ObservedObject var session: Session
    var sessionType: SessionType
    @FetchRequest var files: FetchedResults<File>

    init(session: Session, sessionType: SessionType) {
        self.session = session
        self.sessionType = sessionType
        switch sessionType {
        case .light:
            _files = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)],
                predicate: NSPredicate(format: "session = %@", session),
                animation: .default)
        case .calibration:
            _files = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)],
                predicate: NSPredicate(format: "flatCalibrationSession = %@ OR darkCalibrationSession = %@ OR biasCalibrationSession = %@", session, session, session),
                animation: .default)
        }
    }

    var body: some View {
        HStack {
            Text(session.dateString)
            if sessionType == .light {
                if hasUncalibratedFiles {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                } else {
                    Image(systemName: "checkmark.circle").foregroundColor(.green)
                }
            }
        }
    }

    var uncalibratedFiles: [File] {
        files.filter { file in
            file.flatCalibrationSession == nil
        }
    }

    var hasUncalibratedFiles: Bool {
        !uncalibratedFiles.isEmpty
    }
}
