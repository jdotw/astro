//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

struct FileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var exposureValue: Double = 0
    @Binding var fileID: File.ID

    var file: File? {
        return nil
//        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
//        fetchRequest.predicate = $fileID.wrappedValue == nil ? nil : NSPredicate(format: "id == %@", $fileID.wrappedValue!)
//        fetchRequest.fetchLimit = 1
//        let files = try? viewContext.fetch(fetchRequest)
//        return files?.first
    }

    var fits: FITSFile? {
        guard let file = file else {
            return nil
        }
        return FITSFile(file: file)
    }

    var image: CGImage? {
        return fits?.image()
    }

    var exposedImage: CGImage? {
        guard let fits = fits,
              let image = image
        else {
            return nil
        }
        return fits.adjustExposure(inputImage: image, ev: Float(exposureValue))
    }

    var body: some View {
        Text(self.file?.name ?? "unnamed")
//        Text(self.file.name ?? "unnamed")
//            .padding(10.0)
//        HStack {
//            Image(nsImage: NSImage(cgImage: exposedImage!, size: NSSize.zero))
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//            Image(nsImage: NSImage(cgImage: fits!.createHistogram(inputImage: exposedImage!)!, size: NSSize.zero))
//                .aspectRatio(contentMode: .fit)
//        }
//        Slider(value: self.$exposureValue, in: -10 ... 10, step: 0.1) {
//            Text("Exposure")
//        }
//        .padding()
//
//        Text("Exposure Value: \(self.exposureValue)")
//        Text("FileView: \(file.name ?? "none")")
    }
}

// struct FileView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileView(file: File.example).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
// }
