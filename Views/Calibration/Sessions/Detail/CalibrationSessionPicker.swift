//
//  CalibrationSessionPicker.swift
//  Astro
//
//  Created by James Wilson on 24/5/2024.
//

import SwiftUI

enum CalibrationSessionPickerLimit {
    case earlier
    case later
    case none
}

struct CalibrationSessionPicker: View {
    @ObservedObject var session: Session
    var filter: Filter
    var fileType: FileType
    var limit: CalibrationSessionPickerLimit = .none
    
    @FetchRequest private var calibrationSessions: FetchedResults<Session>
    
    @State private var selectedSessionID: URL?
    
    @State private var showStarRects: Bool = false
    @State private var earlierHistogram: NSImage = .init()
    @State private var laterHistogram: NSImage = .init()
    @State private var candidateHistogram: NSImage = .init()
    
    @Environment(\.managedObjectContext) private var viewContext
    
    init(session: Session, filter: Filter, fileType: FileType, limit: CalibrationSessionPickerLimit = .none) {
        self.session = session
        self.filter = filter
        self.fileType = fileType
        self.limit = limit
        
        var predicate: NSPredicate
        var sortDescriptors: [NSSortDescriptor]
        switch limit {
        case .earlier:
            sortDescriptors = [NSSortDescriptor(keyPath: \Session.date, ascending: true)]
            switch fileType {
            case .flat:
                predicate = NSPredicate(format: "date < %@ AND SUBQUERY(files, $file, $file.typeRawValue =[cd] %@ and $file.filter = %@).@count > 0", session.date as CVarArg, fileType.rawValue, filter)
            default:
                predicate = NSPredicate(format: "date < %@ AND SUBQUERY(files, $file, $file.typeRawValue =[cd] %@).@count > 0", session.date as CVarArg, fileType.rawValue)
            }
        case .later:
            sortDescriptors = [NSSortDescriptor(keyPath: \Session.date, ascending: true)]
            switch fileType {
            case .flat:
                predicate = NSPredicate(format: "date => %@ AND SUBQUERY(files, $file, $file.typeRawValue =[cd] %@ and $file.filter = %@).@count > 0", session.date as CVarArg, fileType.rawValue, filter)
            default:
                predicate = NSPredicate(format: "date => %@ AND SUBQUERY(files, $file, $file.typeRawValue =[cd] %@).@count > 0", session.date as CVarArg, fileType.rawValue, filter)
            }
        case .none:
            sortDescriptors = [NSSortDescriptor(keyPath: \Session.date, ascending: true)]
            switch fileType {
            case .flat:
                predicate = NSPredicate(format: "SUBQUERY(files, $file, $file.typeRawValue =[cd] %@ and $file.filter = %@).@count > 0", fileType.rawValue, filter)
            default:
                predicate = NSPredicate(format: "SUBQUERY(files, $file, $file.typeRawValue =[cd] %@).@count > 0", fileType.rawValue, filter)
            }
        }
        
        _calibrationSessions = FetchRequest(
            entity: Session.entity(),
            sortDescriptors: sortDescriptors,
            predicate: predicate)
    }
    
    var isResolvedSession: Bool {
        if let selectedSession,
           selectedSession == session.resolvedCalibrationSession(forFilter: filter, type: .flat)
        {
            return true
        } else {
            return false
        }
    }
    
    var selectedSession: Session? {
        guard let selectedSessionID else {
            if let resolvedSession = session.resolvedCalibrationSession(forFilter: filter, type: fileType),
               calibrationSessions.contains(resolvedSession)
            {
                return resolvedSession
            } else {
                switch limit {
                case .earlier:
                    return calibrationSessions.last
                default:
                    return calibrationSessions.first
                }
            }
        }
        guard let objectID = viewContext.managedObjectID(forURIRepresentation: selectedSessionID) else { return nil }
        return viewContext.object(with: objectID) as? Session
    }
    
    private func selectedSessionBinding() -> Binding<URL?> {
        return .init(
            get: {
                selectedSession?.id
            },
            set: {
                selectedSessionID = $0
            })
    }
    
    var body: some View {
        VStack {
            if fileType == .flat {
                VStack {
                    if let selectedSession,
                       let file = selectedSession.candidateFlat(forFilter: filter)
                    {
                        FilteredImage(file: file, autoFlipImage: false, histogramImage: $earlierHistogram, showStarRects: $showStarRects)
                            .border(Color.green, width: isResolvedSession ? 2 : 0)
                            .cornerRadius(8.0)
                    } else {
                        Text("No earlier calibration session found").padding()
                    }
                }
            }
            if calibrationSessions.count > 0 {
                Picker(selection: selectedSessionBinding()) {
                    ForEach(calibrationSessions) { session in
                        Text(session.dateString).tag(session.id as URL?)
                    }
                    Text("None").tag(nil as URL?)
                } label: {
                    EmptyView()
                }
            }
        }
    }
}
