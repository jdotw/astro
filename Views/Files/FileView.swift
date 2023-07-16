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
    var body: some View {
        VStack {
            if files.count > 1 {
                MultiFileView(files: files)
            } else if let file = files.first {
                VStack {
                    SingleFileView(file: file)
                }
            }
        }
    }
}
