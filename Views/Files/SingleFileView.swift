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

    @State private var file: File?
    @State private var fits: FITSFile?

    func handleChangeInFileID(fileID: String) {
        let fileReq = NSFetchRequest<File>(entityName: "File")
        fileReq.predicate = NSPredicate(format: "id == %@", fileID)
        fileReq.fetchLimit = 1
        self.file = try? self.viewContext.fetch(fileReq).first
        if let file = self.file {
            self.fits = FITSFile(file: file)
            self.fits?.loadImage()
        } else {
            self.fits = nil
        }
    }

    var body: some View {
        VStack {
            if let file = file,
               let fits = fits
            {
                Text(file.name)
                FITSFileImageView(fits: fits, exposure: self.exposureValue)
                Slider(value: self.$exposureValue, in: -10 ... 10, step: 0.1) {
                    Text("Exposure")
                }

                .padding()
            } else {
                Text("No file selected")
                    .task {}
            }
        }
        .onChange(of: self.fileID) { fileID in
            self.handleChangeInFileID(fileID: fileID)
        }
        .task {
            self.handleChangeInFileID(fileID: self.fileID)
        }
    }
}
