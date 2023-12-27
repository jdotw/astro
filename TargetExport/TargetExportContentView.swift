//
//  TargetExportContentView.swift
//  Astro
//
//  Created by James Wilson on 10/9/2023.
//

import SwiftUI

struct TargetExportContentView: View {
    var exportRequest: TargetExportRequest
    @ObservedObject var controller = TargetExportController.shared
    @State var error: Error?

    @State private var selectedFileID: TargetExportRequestFile.ID?
    @State private var resultsSortOrder: [KeyPathComparator<TargetExportRequestFile>] = [
        .init(\.status, order: SortOrder.forward)
    ]

    @State private var referenceFile: File? = nil
    @State private var useCachedFiles: Bool = true
    @State private var showSelectReferenceAlert: Bool = false

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) var dismiss

    var configBody: some View {
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
                        do {
                            exportRequest.status = .inProgress
                            try TargetExportController.shared.performExport(request: exportRequest) {
                                exportRequest.completed = true
                                do {
                                    try viewContext.save()
                                } catch {
                                    exportRequest.error = error.localizedDescription
                                }
                            }
                        } catch {
                            exportRequest.status = .failed
                            exportRequest.error = error.localizedDescription
                        }
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

    var exportingBody: some View {
        VStack {
            Text("Exporting \(exportRequest.target.name) to \(exportRequest.url.relativePath)")
            Text("\(controller.exported) out of \(controller.total) completed")
            ProgressView(value: Float(controller.exported) / Float(controller.total), total: 1.0)
        }.padding()
    }

    var doneBody: some View {
        HStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .resizable()
                .foregroundColor(.green)
                .frame(width: 44, height: 44)
                .aspectRatio(contentMode: .fit)
            VStack(alignment: .leading) {
                Text("Exported \(exportRequest.target.name) to \(exportRequest.url.relativePath)")
                if controller.exported > 0 {
                    Text("\(controller.exported) files")
                }
            }
        }
        .padding()
    }

    var body: some View {
        VStack {
            switch exportRequest.status {
            case .notStarted:
                configBody
            default:
                HStack {
                    if exportRequest.completed {
                        doneBody
                    } else {
                        exportingBody
                    }
                }
                VStack {
                    if controller.files.count > 0 {
                        Table(controller.files, selection: $selectedFileID, sortOrder: $resultsSortOrder) {
                            TableColumn("", value: \.status) {
                                switch $0.progress {
                                case .exported:
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                case .failed:
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                case .exporting:
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .progressViewStyle(.circular)
                                        .frame(width: 14, height: 14)
                                case .pending:
                                    Image(systemName: "doc.badge.clock.fill")
                                }
                            }.width(20)
                            TableColumn("File") {
                                Text($0.source?.name ?? "")
                            }
                            TableColumn("Error") {
                                Text($0.error?.localizedDescription ?? "")
                            }
                        }
                    }
                }
            }
        }
    }
}
