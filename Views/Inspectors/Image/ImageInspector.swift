//
//  ImageInspector.swift
//  Astro
//
//  Created by James Wilson on 3/9/2023.
//

import SwiftUI

struct ImageInspector: View {
    var file: File?
    var body: some View {
        if let _ = file {
//            ScrollView {
            VStack {
                FileMetadataInspectorPane()
            }
//            }
        } else {
            Text("No file selected")
        }
    }
}

#Preview {
    ImageInspector()
}
