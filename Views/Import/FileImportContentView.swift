//
//  ImportContentView.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import CoreData
import SwiftUI

struct FileImportContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var importRequestID: ImportRequest.ID?

    @StateObject var importController = FileImportController()

    @State private var errors: [Error] = []
    @State private var selectedFileID: ImportRequestFile.ID?

    @State private var resultsSortOrder: [KeyPathComparator<ImportRequestFile>] = [
        .init(\.status, order: SortOrder.forward)
    ]

    var importingBody: some View {
        VStack {
            Text("Importing...")
            Text("\(importController.imported) out of \(importController.total) completed")
            ProgressView(value: Float(importController.imported) / Float(importController.total), total: 1.0)
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
                Text("Imported \(importController.imported) files")
            }
        }
        .padding()
    }

    var body: some View {
        VStack {
            HStack {
                if importController.importing {
                    importingBody
                } else {
                    doneBody
                }
                Table(importSourcedURLs) {
                    TableColumn("Importing From", value: \.url.relativePath)
                }
            }
            VStack {
                Table(importController.files, selection: $selectedFileID, sortOrder: $resultsSortOrder) {
                    TableColumn("", value: \.status) {
                        switch $0.status {
                        case .imported:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .failed:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        case .importing:
                            ProgressView()
                                .scaleEffect(0.5)
                                .progressViewStyle(.circular)
                                .frame(width: 14, height: 14)
                        case .pending:
                            Image(systemName: "doc.badge.clock.fill")
                        }
                    }.width(20)
                    TableColumn("File", value: \.name)
                    TableColumn("Error") {
                        Text($0.error?.localizedDescription ?? "")
                    }
                }
            }
        }
        .task {
            guard let importRequest = importRequest
            else {
                print("Failed to create import controller")
                return
            }
            do {
                try
                    importController.performImport(request: importRequest) {}
            } catch {
                errors.append(error)
            }
        }
    }

    var importRequest: ImportRequest? {
        guard let importRequestID = importRequestID
        else {
            return nil
        }
        let req = ImportRequest.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", importRequestID)
        return try? viewContext.fetch(req).first
    }

    var importSourcedURLs: [ImportURL] {
        return importRequest?.urls?.allObjects as? [ImportURL] ?? []
    }
}
