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
    @Binding var navStackPath: [File]

    var body: some View {
        MultiFileView(files: files, navStackPath: $navStackPath)
    }
}
