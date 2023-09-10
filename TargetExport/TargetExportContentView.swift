//
//  TargetExportContentView.swift
//  Astro
//
//  Created by James Wilson on 10/9/2023.
//

import SwiftUI

struct TargetExportContentView: View {
    var exportRequest: TargetExportRequest

    var body: some View {
        Text("Hello, World!: \(exportRequest.url)")
    }
}
