//
//  SingleFileView.swift
//  Astro
//
//  Created by James Wilson on 14/7/2023.
//

import SwiftUI

struct SingleFileView: View {
    var file: File
    @State private var exposureValue: Double = 10.0
    @State private var gammaValue: Double = 1.4
    @State private var toneCurve1: Double = 0.0
    @State private var toneCurve2: Double = 0.5
    @State private var toneCurve3: Double = 0.9
    @State private var toneCurve4: Double = 1.0
    @State private var toneCurve5: Double = 1.2
    @State private var applyToneCurve: Bool = true

    @State private var showInspector: Bool = true
    @State private var histogramImage: NSImage = .init()

    var body: some View {
        VStack {
            Text(file.name)
            FilteredImage(file: file, exposureValue: exposureValue, gammaValue: gammaValue, toneCurve1: toneCurve1, toneCurve2: toneCurve2, toneCurve3: toneCurve3, toneCurve4: toneCurve4, toneCurve5: toneCurve5, applyToneCurve: applyToneCurve, histogramImage: $histogramImage)
        }
        .inspector(isPresented: $showInspector) {
            Slider(value: $gammaValue, in: -10 ... 10, step: 0.1) {
                Text("Gamma")
            }
            .padding()
            Text("Gamma: \(gammaValue, specifier: "%.2f")")
                .padding()
            Slider(value: $exposureValue, in: -20 ... 20, step: 0.2) {
                Text("Exposure")
            }
            .padding()
            Text("Exposure: \(exposureValue, specifier: "%.2f")")
                .padding()

            Slider(value: $toneCurve1, in: 0 ... 5, step: 0.1) {
                Text("Tone Curve 1")
            }
            .padding()
            Slider(value: $toneCurve2, in: 0 ... 5, step: 0.1) {
                Text("Tone Curve 2")
            }
            .padding()
            Slider(value: $toneCurve3, in: 0 ... 5, step: 0.1) {
                Text("Tone Curve 3")
            }
            .padding()
            Slider(value: $toneCurve4, in: 0 ... 5, step: 0.1) {
                Text("Tone Curve 4")
            }
            .padding()
            Slider(value: $toneCurve5, in: 0 ... 5, step: 0.1) {
                Text("Tone Curve 5")
            }
            .padding()

            Toggle(isOn: $applyToneCurve) {
                Text("Apply Tone Curve")
            }

            Image(nsImage: histogramImage)
        }
    }
}
