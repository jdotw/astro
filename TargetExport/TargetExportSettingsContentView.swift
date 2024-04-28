//
//  TargetExportContentView.swift
//  Astro
//
//  Created by James Wilson on 10/9/2023.
//

import SwiftUI

private enum TargetExportSettingsStep: Int {
    case selectDestinationFolder
    case selectReferenceFile
    case reviewCalibration
    case otherSettings
}

struct TargetExportSettingsContentView: View {
    let exportRequest: TargetExportRequest

    @State private var referenceFile: File? = nil
    @State private var useCachedFiles: Bool = true
    @State private var showSelectReferenceAlert: Bool = false
    @State private var currentStep: TargetExportSettingsStep = .selectDestinationFolder
    @State private var showSelectDestinationSheet: Bool

    init(exportRequest: TargetExportRequest) {
        self.exportRequest = exportRequest
        _showSelectDestinationSheet = State(initialValue: exportRequest.url == nil)
    }

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) var dismiss

    var selectDestinationFolder: some View {
        VStack {
            Text("Select destination folder...")
        }
    }

    var selectReferenceFile: some View {
        VStack {
            Text("Select Reference File")
            FileGrid(source: FileBrowserSource.target(exportRequest.target), selectedFile: $referenceFile)
        }
    }

    var reviewCalibration: some View {
        VStack {
            Text("Table goes here...")
        }
    }

    var otherSettings: some View {
        Toggle(isOn: $useCachedFiles) {
            Text("Use cached files")
        }
    }

    func nextClicked() {
        switch currentStep {
        case .selectDestinationFolder:
            currentStep = .selectReferenceFile
        case .selectReferenceFile:
            currentStep = .reviewCalibration
        case .reviewCalibration:
            currentStep = .otherSettings
        case .otherSettings:
            performExport()
        }
    }

    func performExport() {
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

    var canProgressToNext: Bool {
        switch currentStep {
        case .selectDestinationFolder:
            return true
        case .selectReferenceFile:
            return referenceFile != nil
        case .reviewCalibration:
            return true
        case .otherSettings:
            return true
        }
    }

    var body: some View {
        VStack {
            switch currentStep {
            case .selectDestinationFolder:
                selectDestinationFolder
            case .selectReferenceFile:
                selectReferenceFile
            case .reviewCalibration:
                reviewCalibration
            case .otherSettings:
                otherSettings
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
                Button(currentStep == .otherSettings ? "Export" : "Next") {
                    nextClicked()
                }
                .disabled(!canProgressToNext)
                .buttonStyle(.borderedProminent)
                .alert("Select Reference Image", isPresented: $showSelectReferenceAlert, actions: {
                    Button("OK", role: .cancel) {}
                }, message: {
                    Text("A reference image must be selected to perform the export.")
                })
            }
        }
        .fileExporter(isPresented: $showSelectDestinationSheet, item: exportRequest.target, defaultFilename: exportRequest.target.name) { result in
            switch result {
            case .success(let url):
                exportRequest.url = url
                if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                    try! FileManager.default.removeItem(at: url)
                }
                try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
                exportRequest.bookmark = try! url.bookmarkData(options: .withSecurityScope)
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                nextClicked()
            case .failure(let error):
                print("ERROR: ", error)
            }
        }
    }
}

extension Target: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .target) { target in
            target.name.data(using: .utf8)!
        }
    }
}
