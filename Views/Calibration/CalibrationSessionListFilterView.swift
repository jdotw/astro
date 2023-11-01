//
//  CalibrationFiltersView.swift
//  Astro
//
//  Created by James Wilson on 24/9/2023.
//

import SwiftUI

enum CalibrationSessionListFilterLineDirection {
    case up
    case down
    case both
    case none
}

struct CalibrationSessionListFilterView: View {
    @ObservedObject var session: Session
    @ObservedObject var filter: Filter
    @FetchRequest var files: FetchedResults<File>
    var sessionType: SessionType

    init(session: Session, filter: Filter, sessionType: SessionType) {
        self.session = session
        self.filter = filter
        self.sessionType = sessionType
        switch sessionType {
        case .light:
            _files = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)],
                predicate: NSPredicate(format: "session = %@ AND filter = %@", session, filter),
                animation: .default)
        case .calibration:
            _files = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)],
                predicate: NSPredicate(format: "calibrationSession = %@ AND filter = %@", session, filter),
                animation: .default)
        }
    }

    func filterColor(_ filter: Filter) -> some View {
        Image(systemName: filter.systemImageName)
            .foregroundColor(filter.foregroundColor)
    }

    func filterName(_ filter: Filter) -> some View {
        Text(filter.name.localizedCapitalized)
    }

    func lineForFlatFilter(_ filter: Filter, direction: CalibrationSessionListFilterLineDirection) -> some View {
        GeometryReader { geo in
            Path { path in
                let offset = 10.0
                if direction == .up || direction == .both {
                    path.move(to: CGPoint(x: 0.0, y: geo.size.height * 0.5))
                    path.addCurve(to: CGPoint(x: geo.size.width + offset, y: -4.0 * offset),
                                  control1: CGPoint(x: geo.size.width + offset, y: geo.size.height * 0.5),
                                  control2: CGPoint(x: geo.size.width + offset, y: geo.size.height * 0.5))
                }
                if direction == .down || direction == .both {
                    path.move(to: CGPoint(x: 0.0, y: geo.size.height * 0.5))
                    path.addCurve(to: CGPoint(x: geo.size.width + offset, y: 4.0 * offset),
                                  control1: CGPoint(x: geo.size.width + offset, y: geo.size.height * 0.5),
                                  control2: CGPoint(x: geo.size.width + offset, y: geo.size.height * 0.5))
                }
            }
            .stroke(style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round))
            .foregroundColor(.white.opacity(self.files.isEmpty ? 0.2 : 1.0))
        }
    }

    func lineForLightFilter(_ filter: Filter, direction: CalibrationSessionListFilterLineDirection) -> some View {
        GeometryReader { geo in
            Path { path in
                let offset = 10.0
                path.move(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.5))
                switch direction {
                case .up:
                    path.addCurve(to: CGPoint(x: -1.0 * offset, y: -10.0 * offset),
                                  control1: CGPoint(x: -1.0 * offset, y: geo.size.height * 0.5),
                                  control2: CGPoint(x: -1.0 * offset, y: geo.size.height * 0.5))
                case .down:
                    path.addCurve(to: CGPoint(x: -1.0 * offset, y: +10.0 * offset),
                                  control1: CGPoint(x: -1.0 * offset, y: geo.size.height * 0.5),
                                  control2: CGPoint(x: -1.0 * offset, y: geo.size.height * 0.5))
                default:
                    break
                }
            }
            .stroke(style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round))
            .foregroundColor(.white.opacity(self.files.isEmpty ? 0.2 : 1.0))
        }
    }

    var bodyForFlatFilter: some View {
        HStack {
            let filesForFilter = self.files.map { $0 }
            self.filterName(self.filter)
            Spacer()
            self.filterColor(self.filter)
            ViewThatFits { // Ensures spacer will expand
                GeometryReader { geo in
                    self.lineForFlatFilter(self.filter, direction: self.lineDirection(forFilesCalibratedWithFilter: filesForFilter))
                        .frame(width: geo.size.height)
                        .opacity(filesForFilter.count > 0 ? 1.0 : 0.0)
                }
            }.frame(maxWidth: 20)
        }
    }

    var bodyForLighFilter: some View {
        HStack {
            let filesForFilter = self.files.map { $0 }
            ViewThatFits { // Ensures spacer will expand
                GeometryReader { geo in
                    self.lineForLightFilter(self.filter, direction: self.lineDirection(forFilesInFilter: filesForFilter))
                        .frame(width: geo.size.height)
                        .opacity(filesForFilter.hasCalibrationSession ? 1.0 : 0.0)
                }
            }.frame(maxWidth: 20)
            self.filterColor(self.filter)
            Spacer()
            HStack {
                self.filterName(self.filter)
                if let calSess = filesForFilter.calibrationSession {
                    Text("(\(calSess.dateString))")
                }
            }
        }
    }

    var body: some View {
        switch self.sessionType {
        case .light:
            self.bodyForLighFilter
        case .calibration:
            self.bodyForFlatFilter
        }
    }

    func lineDirection(forFilesInFilter filesForFilter: [File]) -> CalibrationSessionListFilterLineDirection {
        guard let calibrationSession = filesForFilter.calibrationSession else { return .down }
        switch calibrationSession.dateString.compare(self.session.dateString) {
        case .orderedAscending:
            return .up
        case .orderedDescending:
            return .down
        case .orderedSame:
            return .up
        default:
            return .none
        }
    }

    func lineDirection(forFilesCalibratedWithFilter filesForFilter: [File]) -> CalibrationSessionListFilterLineDirection {
        var direction: CalibrationSessionListFilterLineDirection = .none
        if filesForFilter.first(where: { file in
            file.session?.dateString.compare(session.dateString) == .orderedAscending
        }) != nil {
            direction = .up
        }
        if filesForFilter.first(where: { file in
            file.session?.dateString.compare(session.dateString) != .orderedAscending
        }) != nil {
            if direction == .up {
                direction = .both
            } else {
                direction = .down
            }
        }
        return direction
    }
}

extension Filter {
    var systemImageName: String {
        switch self.name.lowercased() {
        case "red", "green", "blue", "lum":
            return "circle.fill"
        case "ha", "s2", "o3":
            return "triangle.fill"
        default:
            return "square.fill"
        }
    }

    var foregroundColor: Color {
        switch self.name.lowercased() {
        case "red":
            return .red
        case "green":
            return .green
        case "blue":
            return .blue
        case "lum":
            return .white
        case "ha":
            return .pink
        case "o3":
            return .teal
        case "s2":
            return .indigo
        default:
            return .gray
        }
    }
}

extension [File] {
    var calibrationSession: Session? {
        return self.first { file in
            file.calibrationSession != nil
        }?.calibrationSession
    }

    var hasCalibrationSession: Bool {
        return self.calibrationSession != nil
    }
}
