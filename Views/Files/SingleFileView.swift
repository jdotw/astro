//
//  SingleFileView.swift
//  Astro
//
//  Created by James Wilson on 14/7/2023.
//

import SwiftUI

struct SingleFileView: View {
    var file: File
    @State private var exposureValue: Double = 3.0

    var body: some View {
        VStack {
            Text(file.name)
            FilteredImage(file: file, exposureValue: exposureValue)
            Slider(value: self.$exposureValue, in: -10 ... 10, step: 0.1) {
                Text("Exposure")
            }
            .padding()
        }
    }
}
