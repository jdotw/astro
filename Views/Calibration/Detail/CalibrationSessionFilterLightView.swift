//
//  CalibrationSessionFilterLightView.swift
//  Astro
//
//  Created by James Wilson on 1/10/2023.
//

import SwiftUI

enum CalibrationSessionFilterLightViewOverlay: String, CaseIterable, Identifiable {
    var id: Self { self }

    case earlier
    case later
}

struct CalibrationSessionFilterLightView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: Session
    var filter: Filter?

    @State private var histogramImage: NSImage = .init()
    @State private var showStarRects: Bool = false
    @State private var earlierHistogramImage: NSImage = .init()
    @State private var laterHistogramImage: NSImage = .init()
    @State private var overlay: CalibrationSessionFilterLightViewOverlay = .earlier
    @State private var showOverlay: Bool = true

    @FocusState private var focused: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: true)])
    private var sessions: FetchedResults<Session>

    var body: some View {
        VStack {
            Text("\(session.dateString) - LIGHTS \(filter?.name ?? "no filter")")
            HStack {
                ZStack {
                    if let earlierCandidateSession = earlierCandidateSession,
                       let file = candidateFlat(inSession: earlierCandidateSession)
                    {
                        FilteredImage(file: file, autoFlipImage: false, histogramImage: $earlierHistogramImage, showStarRects: $showStarRects)
                            .opacity(showOverlay ? 1.0 : 0.0)
                    } else {
                        Text("No earlier calibration session found")
                    }
                    if let file = candidateFile {
                        FilteredImage(file: file, autoFlipImage: false, histogramImage: $histogramImage, showStarRects: $showStarRects)
                            .opacity(showOverlay ? 0.2 : 1.0)
                    } else {
                        Text("No candidate file found")
                    }
                }
                ZStack {
                    if let laterCandidateSession = laterCandidateSession,
                       let file = candidateFlat(inSession: laterCandidateSession)
                    {
                        FilteredImage(file: file, autoFlipImage: false, histogramImage: $laterHistogramImage, showStarRects: $showStarRects)
                            .opacity(showOverlay ? 1.0 : 0.0)
                    } else {
                        Text("No later calibration session found")
                    }
                    if let file = candidateFile {
                        FilteredImage(file: file, autoFlipImage: false, histogramImage: $histogramImage, showStarRects: $showStarRects)
                            .opacity(showOverlay ? 0.2 : 1.0)
                    } else {
                        Text("No candidate file found")
                    }
                }

            }.focusable(true)
        }
        .toolbar(content: {
            Toggle("Show Overlay", isOn: $showOverlay)
                .keyboardShortcut(.space, modifiers: [])

        })
    }

    var candidateFile: File? {
        guard let filter, let files = session.files?.allObjects as? [File] else { return nil }
        return files.first { file in
            file.filter == filter
        }
    }

    func candidateFlat(inSession candidateSession: Session) -> File? {
        guard let filter, let files = candidateSession.files?.allObjects as? [File] else { return nil }
        return files.first { file in
            file.filter == filter && file.type.lowercased() == "flat"
        }
    }

    var earlierCandidateSession: Session? {
        guard let filter else { return nil }
        let sessions = sessions.compactMap { $0 }
        guard let index = sessions.firstIndex(of: session) else { return nil }
        for (i, candidate) in sessions[sessions.startIndex ..< index].reversed().enumerated() {
            print("CANDIDATE (\(session.dateString): i=\(i) dateString=\(candidate.dateString)")
            if let candidateFiles = candidate.files?.allObjects as? [File],
               let file = candidateFiles.first(where: { file in
                   file.type.lowercased() == "flat" && file.filter == filter
               })
            {
                print("FOUND CANDIDATE \(candidate.dateString) - FILE: \(file)")
                return candidate
            }
        }
        return nil
    }

    var laterCandidateSession: Session? {
        guard let filter else { return nil }
        let sessions = sessions.compactMap { $0 }
        guard let index = sessions.firstIndex(of: session) else { return nil }
        for (i, candidate) in sessions[index...].enumerated() {
            print("LATER CANDIDATE (\(session.dateString): i=\(i) dateString=\(candidate.dateString)")
            if let candidateFiles = candidate.files?.allObjects as? [File],
               let file = candidateFiles.first(where: { file in
                   file.type.lowercased() == "flat" && file.filter == filter
               })
            {
                print("FOUND LATER CANDIDATE \(candidate.dateString) - FILE: \(file)")
                return candidate
            }
        }
        return nil
    }
}

struct CalibrationSessionFilterLightViewOverlayPicker: View {
    @Binding var overlay: CalibrationSessionFilterLightViewOverlay

    var body: some View {
        Picker("Overlay", selection: $overlay) {
            ForEach(CalibrationSessionFilterLightViewOverlay.allCases) { overlay in
                overlay.label
                    .keyboardShortcut(overlay.labelContent.keyboardShortcut, modifiers: [])
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

extension CalibrationSessionFilterLightViewOverlay {
    var labelContent: (name: String, systemImage: String, keyboardShortcut: KeyEquivalent) {
        switch self {
        case .earlier:
            return ("Earlier", "chevron.up", .upArrow)
        case .later:
            return ("Later", "chevron.down", .downArrow)
        }
    }

    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}
