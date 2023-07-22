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
    @ObservedObject var importController = FileImportController()
    @State var errors: [Error] = []

    var importingBody: some View {
        VStack {
            Text("Importing...")
            Text("\(importController.imported) out of \(importController.total) completed")
            ProgressView(value: Float(importController.imported) / Float(importController.total), total: 1.0)
            Text("Import ID: \(importRequest?.id ?? "no request")")
        }
    }

    var doneBody: some View {
        VStack {
            Text("Done")
            Text("Import ID: \(importRequest?.id ?? "no request")")
        }
    }

    var body: some View {
        VStack {
            VStack {
                if importController.importing {
                    importingBody
                } else {
                    doneBody
                }
            }.padding()
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
}
