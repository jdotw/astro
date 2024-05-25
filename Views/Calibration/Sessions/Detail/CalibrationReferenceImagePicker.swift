//
//  CalibrationSessionReferenceImagePicker.swift
//  Astro
//
//  Created by James Wilson on 24/5/2024.
//

import SwiftUI

struct CalibrationReferenceImagePicker: View {
    @ObservedObject var session: Session
    var filter: Filter
    
    @FetchRequest private var files: FetchedResults<File>
    
    @State private var selectedFileID: URL?
    
    @State private var showStarRects: Bool = false
    @State private var earlierHistogram: NSImage = .init()
    @State private var laterHistogram: NSImage = .init()
    @State private var candidateHistogram: NSImage = .init()
    
    @Environment(\.managedObjectContext) private var viewContext
    
    init(session: Session, filter: Filter) {
        self.session = session
        self.filter = filter
        
        _files = FetchRequest(
            entity: File.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)],
            predicate: NSPredicate(format: "session = %@ AND typeRawValue =[cd] %@ and filter = %@", session, FileType.light.rawValue, filter))
    }
    
    private var selectedFile: File? {
        guard let selectedFileID else { return files.first }
        guard let objectID = viewContext.managedObjectID(forURIRepresentation: selectedFileID) else { return nil }
        return viewContext.object(with: objectID) as? File
    }
    
    private func selectedFileBinding() -> Binding<URL?> {
        return .init(
            get: {
                selectedFile?.id
            },
            set: {
                selectedFileID = $0
            })
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    if let selectedFile {
                        FilteredImage(file: selectedFile, autoFlipImage: false, histogramImage: $candidateHistogram, showStarRects: $showStarRects)
                    } else {
                        Text("No reference image available")
                    }
                    Picker(selection: selectedFileBinding()) {
                        ForEach(files) { file in
                            Text(file.name).tag(file.id as URL?)
                        }

                    } label: {
                        EmptyView()
                    }
                }
            }
        }
    }
}
