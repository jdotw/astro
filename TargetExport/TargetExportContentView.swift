//
//  TargetExportContentView.swift
//  Astro
//
//  Created by James Wilson on 10/9/2023.
//

import SwiftUI

struct TargetExportContentView: View {
    let exportRequest: TargetExportRequest

    var body: some View {
        VStack {
            switch exportRequest.status {
            case .notStarted:
                TargetExportSettingsContentView(exportRequest: exportRequest)
            default:
                TargetExportProgressContentView(exportRequest: exportRequest)
            }
        }
        .navigationTitle("Export of \(exportRequest.target.name) on \(exportRequest.formattedTimestamp)")
    }
}

extension TargetExportRequest {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: timestamp)
    }
}
