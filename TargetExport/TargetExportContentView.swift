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

    var exportingBody: some View {
        VStack {
            Text("Exporting...")
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
                Text("Done")
                Text("Exported \(controller.exported) files")
            }
        }
        .padding()
    }

    var body: some View {
        VStack {
            HStack {
                if controller.exporting {
                    exportingBody
                } else {
                    doneBody
                }
                Text("Exporting to \(exportRequest.url.relativePath)")
            }
            VStack {
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
        .task {
            do {
                try
                    controller.performExport(request: exportRequest) {
                        print("Done")
                    }
            } catch {
                self.error = error
            }
        }
    }
}
