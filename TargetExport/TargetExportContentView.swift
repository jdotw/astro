//
//  TargetExportContentView.swift
//  Astro
//
//  Created by James Wilson on 10/9/2023.
//

import SwiftUI

struct TargetExportContentView: View {
    var exportRequest: TargetExportRequest
    @StateObject var controller = TargetExportController()
    @State var error: Error?

    @State private var selectedFileID: TargetExportRequestFile.ID?
    @State private var resultsSortOrder: [KeyPathComparator<TargetExportRequestFile>] = [
        .init(\.status, order: SortOrder.forward)
    ]

    @Environment(\.managedObjectContext) private var viewContext

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
                            switch $0.status {
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
                        TableColumn("File", value: \.source.name)
                        TableColumn("Error") {
                            Text($0.error?.localizedDescription ?? "")
                        }
                    }
                }
            }
        }
        .task {
            if exportRequest.completed == false {
                do {
                    try
                        controller.performExport(request: exportRequest) {
                            exportRequest.completed = true
                            do {
                                try viewContext.save()
                            } catch {
                                self.error = error
                            }
                        }
                } catch {
                    self.error = error
                }
            }
        }
    }
}
