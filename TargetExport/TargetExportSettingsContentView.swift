//
//  TargetExportContentView.swift
//  Astro
//
//  Created by James Wilson on 10/9/2023.
//

import SwiftUI

struct TargetExportSettingsContentView: View {
    let exportRequest: TargetExportRequest

    @State private var referenceFile: File? = nil
    @State private var useCachedFiles: Bool = true
    @State private var showSelectReferenceAlert: Bool = false

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            VStack {
                Text("Select Reference File")
                FileGrid(source: FileBrowserSource.target(exportRequest.target), selectedFile: $referenceFile)
            }
            VStack {
                Toggle(isOn: $useCachedFiles) {
                    Text("Use cached files")
                }
                HStack {
                    Button("Cancel") {
                        exportRequest.status = .cancelled
                        do {
                            try viewContext.save()
                        } catch {
                            exportRequest.error = error.localizedDescription
                        }
                        dismiss()
                    }
                    Button("Export") {
                        guard let referenceFile else {
                            showSelectReferenceAlert = true
                            return
                        }
                        exportRequest.reference = referenceFile
                        exportRequest.status = .inProgress
                        TargetExportController.shared.performExport(request: exportRequest, context: viewContext)
                        dismiss()
                        openWindow(value: TransientWindowType.targetExportRequestList)
                    }
                    .buttonStyle(.borderedProminent)
                    .alert("Select Reference Image", isPresented: $showSelectReferenceAlert, actions: {
                        Button("OK", role: .cancel) {}
                    }, message: {
                        Text("A reference image must be selected to perform the export.")
                    })
                }
            }
        }
    }
}
