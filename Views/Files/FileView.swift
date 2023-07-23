//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

struct FileView: View {
    var files: Set<File>
    @State private var focusedFile: File?
    var body: some View {
        VStack {
            if let focusedFile = focusedFile {
                SingleFileView(file: focusedFile)
            } else if files.count == 1, let singleFile = files.first {
                SingleFileView(file: singleFile)
            } else {
                MultiFileView(files: files, focusedFile: $focusedFile)
            }
        }
    }
}
