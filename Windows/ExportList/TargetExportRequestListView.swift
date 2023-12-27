//
//  TargetExportRequestListView.swift
//  Astro
//
//  Created by James Wilson on 27/12/2023.
//

import SwiftUI

struct TargetExportRequestListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TargetExportRequest.timestamp, ascending: false)],
        predicate: NSPredicate(format: "statusRawValue != %@", TargetExportRequestStatus.notStarted.rawValue),
        animation: .default)
    private var exportRequests: FetchedResults<TargetExportRequest>

    @State private var selection: URL?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        List(selection: $selection) {
            ForEach(exportRequests) { exportRequest in
                TargetExportRequestRow(exportRequest: exportRequest)
            }
        }
        .contextMenu(forSelectionType: URL.self, menu: { _ in }, primaryAction: { items in
            items.forEach { openWindow(value: $0) }
        })
        .navigationTitle("Target Exports")
    }
}

struct TargetExportRequestRow: View {
    var exportRequest: TargetExportRequest

    var body: some View {
        HStack {
            exportRequest.statusView
            VStack(alignment: .leading) {
                Text(exportRequest.target.name).bold()
                Text(exportRequest.timestamp, style: .date)
            }
            Spacer()
            Text(exportRequest.statusLabel)
        }
    }
}

extension TargetExportRequest {
    var statusLabel: String {
        switch status {
        case .inProgress:
            if hasExportOperation {
                return "In Progress"
            } else {
                return "Cancelled"
            }
        case .cancelled:
            return "Cancelled"
        case .exported:
            return "Done"
        case .failed:
            return "Failed"
        default:
            return "Unknown"
        }
    }

    var statusView: some View {
        VStack {
            switch status {
            case .inProgress:
                if hasExportOperation {
                    ProgressView()
                        .scaleEffect(0.5)
                        .progressViewStyle(.circular)
                        .frame(width: 14, height: 14)
                } else {
                    // Stale
                    Image(systemName: "nosign")
                        .foregroundColor(.gray)
                }
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            case .exported:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .cancelled:
                Image(systemName: "nosign")
                    .foregroundColor(.gray)
            default:
                Image(systemName: "questionmark")
                    .foregroundColor(.yellow)
            }
        }
    }
}
