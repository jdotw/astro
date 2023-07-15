//
//  SingleFileView.swift
//  Astro
//
//  Created by James Wilson on 14/7/2023.
//

import SwiftUI

struct SingleFileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var exposureValue: Double = 0
    var fileID: File.ID

    var file: File? {
        let fileReq = NSFetchRequest<File>(entityName: "File")
        fileReq.predicate = NSPredicate(format: "id == %@", self.fileID)
        fileReq.fetchLimit = 1
        return try? self.viewContext.fetch(fileReq).first
    }

    var body: some View {
        VStack {
            if let file = file {
                Text(file.name)
                Image(nsImage: NSImage(contentsOf: file.previewURL)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
//                FITSFileImageView(fits: fits, exposure: self.exposureValue)
                Slider(value: self.$exposureValue, in: -10 ... 10, step: 0.1) {
                    Text("Exposure")
                }

                .padding()
            } else {
                Text("No file selected")
                    .task {}
            }
        }
    }
}
