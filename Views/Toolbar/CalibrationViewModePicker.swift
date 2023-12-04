//
//  FileListModePicker.swift
//  Astro
//
//  Created by James Wilson on 5/8/2023.
//

import SwiftUI

struct CalibrationViewModePicker: View {
    @Binding var mode: CalibrationViewMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(sortedModes) { viewMode in
                viewMode.label
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    var sortedModes: [CalibrationViewMode] {
        return [.sessions, .files]
    }
}

extension CalibrationViewMode {
    var labelContent: (name: String, systemImage: String) {
        switch self {
        case .sessions:
            return ("Sessions", "photo.on.rectangle.angled")
        case .files:
            return ("Files", "list.dash")
        }
    }

    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}
