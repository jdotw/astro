//
//  FileApproval.swift
//  Astro
//
//  Created by James Wilson on 6/8/2023.
//

import SwiftUI

struct FileApproval: View {
    var files: [File]
    @Binding var navStackPath: [File]
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.forward)
    ]

    @State private var selectedFileID: File.ID?
    @State private var showStarRects: Bool = false

    @FocusState private var focused: Bool
    @Environment(\.managedObjectContext) private var viewContext

    func delete() {
        guard let fileToDelete = selectedFile else { return }
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
        fileToDelete.rejected = true
        try! viewContext.save()
    }

    func moveSelection(delta: Int) -> Bool {
        guard let selectedFile = selectedFile,
              let index = sortedFiles.firstIndex(where: { $0.id == selectedFile.id })
        else { return false }
        let newIndex = index + delta
        if newIndex < 0 || newIndex >= sortedFiles.count {
            return false
        }
        selectedFileID = sortedFiles[newIndex].id
        return true
    }

    func goNext() {
        _ = moveSelection(delta: 1)
    }

    func goPrev() {
        _ = moveSelection(delta: -1)
    }

    var canGoBack: Bool {
        guard let selectedFile = selectedFile,
              let index = sortedFiles.firstIndex(where: { $0.id == selectedFile.id })
        else { return false }
        return index > 0
    }

    var canGoForward: Bool {
        guard let selectedFile = selectedFile,
              let index = sortedFiles.firstIndex(where: { $0.id == selectedFile.id })
        else { return false }
        return index < sortedFiles.count - 1
    }

    var body: some View {
        VStack {
            ItemFullSizeImage(file: selectedFile, showStarRects: $showStarRects)
            Text("File: \(selectedFile?.name ?? "no selection")")
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
                        .disabled(selectedFile == nil)
                        .keyboardShortcut(.delete, modifiers: [])
                        Button(action: { showStarRects.toggle() }) {
                            Image(systemName: "star.fill")
                        }
                        .keyboardShortcut(.space, modifiers: [])
                    }
                })
        }
        .onChange(of: files) {
            selectedFileID = nil
        }
    }

    private struct ItemFullSizeImage: View {
        var file: File?
        @State private var histogram: NSImage = .init()
        @Binding var showStarRects: Bool

        var body: some View {
            if let file = file {
                FilteredImage(file: file, histogramImage: $histogram, showStarRects: $showStarRects)
            } else {
                Text("no file")
            }
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
        }
    }
}

extension FileApproval {
    var sortedFiles: [File] {
        files.filter { !$0.rejected }.sorted(using: sortOrder)
    }

    var selectedFile: File? {
        guard let selectedFileID = selectedFileID else {
            return sortedFiles.first
        }
        return sortedFiles.first { $0.id == selectedFileID }
    }
}
