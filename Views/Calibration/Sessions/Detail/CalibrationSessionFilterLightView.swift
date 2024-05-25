//
//  CalibrationSessionFilterLightView.swift
//  Astro
//
//  Created by James Wilson on 1/10/2023.
//

import SwiftUI

struct CalibrationSessionFilterLightView: View {
    @ObservedObject var session: Session
    var filter: Filter

    @FetchRequest private var earlierCalibrationSessions: FetchedResults<Session>
    @FetchRequest private var laterCalibrationSessions: FetchedResults<Session>
    @FetchRequest private var candidateImages: FetchedResults<File>

    @State private var earlierCalibrationSessionID: URL?
    @State private var laterCalibrationSessionID: URL?
    @State private var candidateImageID: URL?

    @State private var earlierStackedFlatFrame: CGImage?
    @State private var laterStackedFlatFrame: CGImage?

    @State private var showStarRects: Bool = false
    @State private var earlierHistogram: NSImage = .init()
    @State private var laterHistogram: NSImage = .init()
    @State private var candidateHistogram: NSImage = .init()

    @Environment(\.managedObjectContext) private var viewContext

    init(session: Session, filter: Filter) {
        self.session = session
        self.filter = filter

        _earlierCalibrationSessions = FetchRequest(
            entity: Session.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: false)],
            predicate: NSPredicate(format: "date <= %@ AND SUBQUERY(files, $file, $file.typeRawValue =[cd] %@ and $file.filter = %@).@count > 0", session.date as CVarArg, FileType.flat.rawValue, filter))
        _laterCalibrationSessions = FetchRequest(
            entity: Session.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: true)],
            predicate: NSPredicate(format: "date > %@ AND SUBQUERY(files, $file, $file.typeRawValue =[cd] %@ and $file.filter = %@).@count > 0", session.date as CVarArg, FileType.flat.rawValue, filter))
        _candidateImages = FetchRequest(
            entity: File.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)],
            predicate: NSPredicate(format: "session = %@ AND typeRawValue =[cd] %@ and filter = %@", session, FileType.light.rawValue, filter))
    }

    private var candidateImage: File? {
        guard let candidateImageID else { return candidateImages.first }
        guard let objectID = viewContext.managedObjectID(forURIRepresentation: candidateImageID) else { return nil }
        return viewContext.object(with: objectID) as? File
    }

    private func candidateImageBinding() -> Binding<URL?> {
        return .init(
            get: {
                candidateImage?.id
            },
            set: {
                candidateImageID = $0
            })
    }

    var earlierCandidateSession: Session? {
        guard let earlierCalibrationSessionID else { return earlierCalibrationSessions.first }
        guard let objectID = viewContext.managedObjectID(forURIRepresentation: earlierCalibrationSessionID) else { return nil }
        return viewContext.object(with: objectID) as? Session
    }

    private func earlierSessionBinding() -> Binding<URL?> {
        return .init(
            get: {
                earlierCandidateSession?.id
            },
            set: {
                earlierCalibrationSessionID = $0
            })
    }

    var laterCandidateSession: Session? {
        guard let laterCalibrationSessionID else { return laterCalibrationSessions.first }
        guard let objectID = viewContext.managedObjectID(forURIRepresentation: laterCalibrationSessionID) else { return nil }
        return viewContext.object(with: objectID) as? Session
    }

    private func laterSessionBinding() -> Binding<URL?> {
        return .init(
            get: {
                laterCandidateSession?.id
            },
            set: {
                laterCalibrationSessionID = $0
            })
    }

    var body: some View {
        VStack {
            Text("\(session.dateString) - LIGHTS \(filter.name)")
            HStack {
                VStack {
                    ZStack {
                        if let earlierCandidateSession,
                           let file = candidateFlat(inSession: earlierCandidateSession)
                        {
                            FilteredImage(file: file, autoFlipImage: false, histogramImage: $earlierHistogram, showStarRects: $showStarRects)
                        } else {
                            Text("No earlier calibration session found")
                        }
                    }
                    Picker("Earlier", selection: earlierSessionBinding()) {
                        ForEach(earlierCalibrationSessions) { session in
                            Text(session.dateString).tag(session.id as URL?)
                        }
                        Text("None").tag(nil as URL?)
                    }
                }
                VStack {
                    if let candidateImageID,
                       let candidateFile = candidateImages.first(where: { $0.id == candidateImageID })
                    {
                        FilteredImage(file: candidateFile, autoFlipImage: false, histogramImage: $candidateHistogram, showStarRects: $showStarRects)
                    } else if let candidateFile = candidateImages.first {
                        FilteredImage(file: candidateFile, autoFlipImage: false, histogramImage: $candidateHistogram, showStarRects: $showStarRects)
                    }
                    Picker("Image", selection: candidateImageBinding()) {
                        ForEach(candidateImages) { file in
                            Text(file.name).tag(file.id as URL?)
                        }
//                        Text("None").tag(nil as URL?)
                    }
                }
                VStack {
                    ZStack {
                        if let laterCandidateSession,
                           let file = candidateFlat(inSession: laterCandidateSession)
                        {
                            FilteredImage(file: file, autoFlipImage: false, histogramImage: $laterHistogram, showStarRects: $showStarRects)
                        } else {
                            Text("No later calibration session found")
                        }
                    }
                    Picker("Later", selection: laterSessionBinding()) {
                        ForEach(laterCalibrationSessions) { session in
                            Text(session.dateString).tag(session.id as URL?)
                        }
                        Text("None").tag(nil as URL?)
                    }
                }
                VStack {
//                    Picker("Dark", selection: $laterCalibrationSessionID) {
//                        ForEach(laterCalibrationSessions) { session in
//                            Text(session.dateString)
//                        }
//                    }
//                    Picker("Bias", selection: $laterCalibrationSessionID) {
//                        ForEach(laterCalibrationSessions) { session in
//                            Text(session.dateString)
//                        }
//                    }
                }
            }
        }
    }

    var candidateFile: File? {
        guard let files = session.files?.allObjects as? [File] else { return nil }
        return files.first { file in
            file.filter == filter
        }
    }

    func candidateFlats(inSession candidateSession: Session) -> [File] {
        guard let files = candidateSession.files?.allObjects as? [File] else { return [] }
        return files.compactMap { file in
            if file.filter == filter && file.type == .flat {
                return file
            } else {
                return nil
            }
        }
    }

    func candidateFlat(inSession candidateSession: Session) -> File? {
        guard let files = candidateSession.files?.allObjects as? [File] else { return nil }
        return files.first { file in
            file.filter == filter && file.type == .flat
        }
    }
}
