//
//  FileApproval.swift
//  Astro
//
//  Created by James Wilson on 6/8/2023.
//

import SwiftUI

struct FileApproval: View {
    var source: FileBrowserSource

    @FetchRequest var files: FetchedResults<File>
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.forward)
    ]

    @State private var selectedFileID: File.ID?
    @State private var showStarRects: Bool = true
    @State private var showInspector: Bool = true

    @FocusState private var focused: Bool
    @Environment(\.managedObjectContext) private var viewContext

    init(source: FileBrowserSource) {
        let fetchReq = source.fileFetchRequest
        _files = fetchReq
        self.source = source
    }

    func delete() {
        guard let fileIDToDelete = selectedFileID else { return }
        // Perform navigation before marking the file as rejected
        // Becuase once it's rejected, it won't appear in sortedFiles
        if canGoForward {
            goNext()
        } else if canGoBack {
            goPrev()
        } else {
            selectedFileID = nil
        }
        // Mark file as rejected
        if let fileToDelete = files.first(where: { $0.id == fileIDToDelete }) {
            fileToDelete.rejected = true
            try! viewContext.save()
        }
    }

    func moveSelection(delta: Int) -> Bool {
        let sortedFiles = files
        guard let selectedFileID = selectedFileID,
              let index = sortedFiles.firstIndex(where: { $0.id == selectedFileID })
        else { return false }
        let newIndex = index + delta
        if newIndex < 0 || newIndex >= sortedFiles.count {
            return false
        }
        self.selectedFileID = sortedFiles[newIndex].id
        return true
    }

    func goNext() {
        _ = moveSelection(delta: 1)
    }

    func goPrev() {
        _ = moveSelection(delta: -1)
    }

    var canGoBack: Bool {
        let sortedFiles = files
        guard let selectedFileID = selectedFileID,
              let index = sortedFiles.firstIndex(where: { $0.id == selectedFileID })
        else { return false }
        return index > 0
    }

    var canGoForward: Bool {
        let sortedFiles = files
        guard let selectedFileID = selectedFileID,
              let index = sortedFiles.firstIndex(where: { $0.id == selectedFileID })
        else { return false }
        return index < sortedFiles.count - 1
    }

    var body: some View {
        let selectedFile = selectedFile
        VStack {
            if let selectedFile {
                Text("File: \(selectedFile.name)")
                ItemFullSizeImage(file: selectedFile,
                                  showStarRects: $showStarRects)
                    .frame(maxHeight: .infinity)
            } else {
                Text("no file selected")
            }
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(files) { file in
                            ItemPreviewImage(file: file)
                                .frame(width: 100, height: 100)
                                .onTapGesture {
                                    selectedFileID = file.id
                                }
                                .background(RoundedRectangle(cornerRadius: 8).fill(file == selectedFile ? Color.accentColor : Color.clear))
                        }
                    }
                    .onChange(of: selectedFileID) { _, _ in
                        let selectedFile = self.selectedFile
                        DispatchQueue.main.async {
                            // use selectedFile here to ensure we get the default
                            // selection of the first file if selectedFileID is nil
                            if let selectedFile {
                                proxy.scrollTo(selectedFile.id, anchor: .center)
                                selectedFile.reviewed = true
                                try! viewContext.save()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .bottom)
                .background(Color.black.opacity(0.5))
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: goPrev) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)
                .keyboardShortcut(.leftArrow, modifiers: [])
                Button(action: goNext) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
                .keyboardShortcut(.rightArrow, modifiers: [])
                Button(action: delete) {
                    Image(systemName: "trash.fill")
                }
                .disabled(selectedFileID == nil)
                .keyboardShortcut(.delete, modifiers: [])
                Toggle(isOn: $showStarRects) {
                    Image(systemName: "star.fill")
                }
                .keyboardShortcut(.space, modifiers: [])
            }
        })
        .inspector(isPresented: $showInspector) {
            ImageInspector(file: selectedFile)
        }
        .onChange(of: source) { _, _ in
            self.selectedFileID = nil
        }
    }

    private struct ItemFullSizeImage: View {
        @ObservedObject var file: File
        @State private var histogram: NSImage = .init()
        @Binding var showStarRects: Bool

        var body: some View {
            FilteredImage(file: file, histogramImage: $histogram, showStarRects: $showStarRects)
        }
    }

    private struct ItemPreviewImage: View {
        var file: File?
        var body: some View {
            AsyncImage(url: file?.previewURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "moon.stars")
                    .symbolVariant(.fill)
                    .font(.system(size: 40))
                    .foregroundColor(Color.accentColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(4)
        }
    }
}

extension FileApproval {
    var selectedFile: File? {
        guard let selectedFileID = selectedFileID else {
            return files.first
        }
        return files.first { $0.id == selectedFileID }
    }
}
