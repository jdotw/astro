//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

enum FileBrowserViewMode: String, CaseIterable, Identifiable {
    var id: Self { self }
    case table
    case grid
}

struct FileBrowser: View {
    var session: Session?
    var target: Target?
    var blaj: String = ""
    var files: [File]
    var columns: [FileTableColumns] = FileTableColumns.allCases

    @Binding var navStackPath: [File]
    @Binding var viewMode: FileBrowserViewMode

    var body: some View {
        VStack {
            switch viewMode {
            case .table:
                FileTable(files: files, columns: columns, navStackPath: $navStackPath)
            case .grid:
                FileGrid(files: files, navStackPath: $navStackPath)
            }
        }
        .toolbar {
            ToolbarItem {
                FileBrowserModePicker(mode: $viewMode)
            }
        }
    }
}
