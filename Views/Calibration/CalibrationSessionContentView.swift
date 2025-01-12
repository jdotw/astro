//
//  CalibrationSessionView.swift
//  Astro
//
//  Created by James Wilson on 8/12/2024.
//

import SwiftUI

struct CalibrationSessionContentView: View {
    var session: Session
    var fileType: FileType
    @Binding var navStackPath: [File]

    @AppStorage("calibrationSessionFileBrowserViewMode") private var fileViewMode: FileBrowserViewMode = .approve
    
    private func exportCalibrationSession() {
//        let exportRequest = CalibrationSessionExportRequest(context: viewContext)
//        exportRequest.timestamp = Date()
//        exportRequest.session = session
//        exportRequest.fileType = fileType
//        exportRequest.status = .notStarted
//        do {
//            try viewContext.save()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//        openWindow(value: exportRequest.id)
    }


    var body: some View {
        VStack {
            FileBrowser(source: .calibrationSession(session, fileType),
                        navStackPath: $navStackPath,
                        viewMode: $fileViewMode)
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: {
                    print("YEAH!")
                }) {
                    Label("Export", systemImage: "square.and.arrow.up.on.square")
                }
            }
        }

    }
}
