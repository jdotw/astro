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

    var body: some View {
        List {
            ForEach(exportRequests) { exportRequest in
                NavigationLink(destination: TargetExportContentView(exportRequest: exportRequest)) {
                    TargetExportRequestRow(exportRequest: exportRequest)
                }
            }
        }
        .navigationTitle("Target Exports")
    }
}

struct TargetExportRequestRow: View {
    var exportRequest: TargetExportRequest

    var body: some View {
        HStack {
            exportRequest.status.statusView
            VStack(alignment: .leading) {
                Text(exportRequest.target.name).bold()
                Text(exportRequest.timestamp, style: .date)
            }
            Spacer()
            Text(exportRequest.status.label)
        }
    }
}

extension TargetExportRequestStatus {
    var label: String {
        switch self {
        case .inProgress:
            return "In Progress"
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
            switch self {
            case .inProgress:
                ProgressView()
                    .scaleEffect(0.5)
                    .progressViewStyle(.circular)
                    .frame(width: 14, height: 14)
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
