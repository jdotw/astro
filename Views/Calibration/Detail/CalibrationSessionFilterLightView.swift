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
    var filter: Filter

    @State private var histogramImage: NSImage = .init()
    @State private var showStarRects: Bool = false
    @State private var earlierHistogramImage: NSImage = .init()
    @State private var laterHistogramImage: NSImage = .init()
    @State private var overlay: CalibrationSessionFilterLightViewOverlay = .earlier
    @State private var showOverlay: Bool = true

    @State private var earlierCalibrationSessionID: String = ""
    @State private var laterCalibrationSessionID: String = ""

    @FocusState private var focused: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: true)])
    private var sessions: FetchedResults<Session>

    @FetchRequest private var earlierCalibrationSessions: FetchedResults<Session>
    @FetchRequest private var laterCalibrationSessions: FetchedResults<Session>

    init(session: Session, filter: Filter) {
        self.session = session
        self.filter = filter

        let earlierPredicate = NSPredicate(format: "dateString <= %@ AND SUBQUERY(files, $file, $file.type =[cd] %@ and $file.filter = %@).@count > 0", session.dateString, "Flat", filter)
        let laterPredicate = NSPredicate(format: "dateString > %@ AND SUBQUERY(files, $file, $file.type =[cd] %@ and $file.filter = %@).@count > 0", session.dateString, "Flat", filter)
        _earlierCalibrationSessions = FetchRequest(
            entity: Session.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: false)],
            predicate: earlierPredicate)
        _laterCalibrationSessions = FetchRequest(
            entity: Session.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: true)],
            predicate: laterPredicate)
    }

    var body: some View {
        VStack {
            Text("\(session.dateString) - LIGHTS \(filter.name)")
            HStack {
                VStack {
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
                    if earlierCalibrationSessions.count > 0 {
                        Picker("Session", selection: $earlierCalibrationSessionID) {
                            ForEach(earlierCalibrationSessions, id: \.id.absoluteString) { session in
                                Text(session.dateString)
                            }
                        }
                        .focusable(true)
                    }
                }
                .focusable(true)
                VStack {
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
                    if laterCalibrationSessions.count > 0 {
                        Picker("Session", selection: $laterCalibrationSessionID) {
                            ForEach(laterCalibrationSessions, id: \.id.absoluteString) { session in
                                Text(session.dateString)
                            }
                        }
                        .focusable(true)
                    }
                }
            }
        }
        .toolbar(content: {
            Toggle("Show Overlay", isOn: $showOverlay)
                .keyboardShortcut(.space, modifiers: [])

        })
        .task {
            updateSessionPickers()
        }
        .onChange(of: session) { _, _ in
            updateSessionPickers()
        }
    }

    func updateSessionPickers() {
        earlierCalibrationSessionID = earlierCalibrationSessions.first?.id.absoluteString ?? ""
        laterCalibrationSessionID = laterCalibrationSessions.first?.id.absoluteString ?? ""
    }

    var candidateFile: File? {
        guard let files = session.files?.allObjects as? [File] else { return nil }
        return files.first { file in
            file.filter == filter
        }
    }

    func candidateFlat(inSession candidateSession: Session) -> File? {
        guard let files = candidateSession.files?.allObjects as? [File] else { return nil }
        return files.first { file in
            file.filter == filter && file.type.lowercased() == "flat"
        }
    }

    var earlierCandidateSession: Session? {
        earlierCalibrationSessions.first { session in
            session.id.absoluteString == earlierCalibrationSessionID
        }
    }

    var laterCandidateSession: Session? {
        laterCalibrationSessions.first { session in
            session.id.absoluteString == laterCalibrationSessionID
        }
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
