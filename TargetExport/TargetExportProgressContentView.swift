//
//  TargetExportContentView.swift
//  Astro
//
//  Created by James Wilson on 10/9/2023.
//

import SwiftUI

struct TargetExportProgressContentView: View {
    let exportRequest: TargetExportRequest

    @State private var selectedFileID: TargetExportRequestFile.ID?
    @State private var resultsSortOrder: [KeyPathComparator<TargetExportRequestFile>] = [
        .init(\.status, order: SortOrder.forward)
    ]

    @Environment(\.managedObjectContext) private var viewContext

    var exportingBody: some View {
        VStack {
            if let exportOperation = exportRequest.exportOperation {
                Text("Exporting \(exportRequest.target.name) to \(exportRequest.url.relativePath)")
                Text("\(exportOperation.exported) out of \(exportOperation.total) completed")
                ProgressView(value: Float(exportOperation.exported) / Float(exportOperation.total), total: 1.0)
            }
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
                if let exportOperation = exportRequest.exportOperation,
                   exportOperation.exported > 0
                {
                    Text("\(exportOperation.exported) files")
                }
            }
        }
        .padding()
    }

    var body: some View {
        VStack {
            HStack {
                if exportRequest.hasExportOperation {
                    exportingBody
                } else {
                    doneBody
                }
            }
            VStack {
                if let exportOperation = exportRequest.exportOperation,
                   exportOperation.files.count > 0
                {
                    Table(exportOperation.files, selection: $selectedFileID, sortOrder: $resultsSortOrder) {
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
