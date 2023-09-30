//
//  CalibrationFiltersView.swift
//  Astro
//
//  Created by James Wilson on 24/9/2023.
//

import SwiftUI

enum CalibrationFiltersViewOrientation {
    case leftToRight
    case rightToLeft
}

enum CalibrationFilterLineDirection {
    case up
    case down
    case both
    case none
}

struct CalibrationFiltersView: View {
    @ObservedObject var session: Session
    let fileType: String
    @FetchRequest var filters: FetchedResults<Filter>
    let orientation: CalibrationFiltersViewOrientation

    init(session: Session, orientation: CalibrationFiltersViewOrientation, fileType: String) {
        self.session = session
        self.orientation = orientation
        self.fileType = fileType
        _filters = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Filter.name, ascending: true)],
            predicate: NSPredicate(format: "ANY files.session = %@", session),
            animation: .default)
    }

    func filterColor(_ filter: Filter) -> some View {
        Image(systemName: filter.systemImageName)
            .foregroundColor(filter.foregroundColor.opacity(self.session.hasFilesWithFilter(filter) ? 1.0 : 0.2))
    }

    func filterName(_ filter: Filter) -> some View {
        Text(filter.name.localizedCapitalized)
    }

    func line(_ filter: Filter, direction: CalibrationFilterLineDirection) -> some View {
        GeometryReader { geo in
            switch self.orientation {
            case .leftToRight:
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
                .foregroundColor(.white.opacity(self.session.hasFilesWithFilter(filter) ? 1.0 : 0.2))
            case .rightToLeft:
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
                .foregroundColor(.white.opacity(self.session.hasFilesWithFilter(filter) ? 1.0 : 0.2))
            }
        }
    }

    var body: some View {
        VStack(alignment: self.vStackAlignment) {
            ForEach(self.sortedFilters) { filter in
                HStack {
                    switch self.orientation {
                    case .leftToRight:
                        let filesForFilter = self.session.calibratesFilesWithFilter(filter)
                        self.filterName(filter)
                        Text("(\(self.sortOrder(forFilter: filter)))")
                        Spacer()
                        self.filterColor(filter)
                        ViewThatFits { // Ensures spacer will expand
                            GeometryReader { geo in
                                self.line(filter, direction: self.lineDirection(forFilesCalibratedWithFilter: filesForFilter))
                                    .frame(width: geo.size.height)
                                    .opacity(filesForFilter.count > 0 ? 1.0 : 0.0)
//                                self.line(filter, direction: .down)
//                                    .frame(width: geo.size.height)
//                                    .opacity(filesForFilter.hasCalibrationSession ? 1.0 : 0.0)
                            }
                        }.frame(maxWidth: 20)
                    case .rightToLeft:
                        let filesForFilter = self.session.filesWithFilter(filter)
                        ViewThatFits { // Ensures spacer will expand
                            GeometryReader { geo in
                                self.line(filter, direction: self.lineDirection(forFilesInFilter: filesForFilter))
                                    .frame(width: geo.size.height)
                                    .opacity(filesForFilter.hasCalibrationSession ? 1.0 : 0.0)
                            }
                        }.frame(maxWidth: 20)
                        self.filterColor(filter)
                        Spacer()
                        HStack {
                            self.filterName(filter)
                            Text("(\(self.sortOrder(forFilter: filter)))")
                            if let calSess = filesForFilter.calibrationSession {
                                Text("(\(calSess.dateString))")
                            }
                        }
                    }
                }
            }
        }
    }

    func lineDirection(forFilesInFilter filesForFilter: [File]) -> CalibrationFilterLineDirection {
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

    func lineDirection(forFilesCalibratedWithFilter filesForFilter: [File]) -> CalibrationFilterLineDirection {
        var direction: CalibrationFilterLineDirection = .none
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

    var vStackAlignment: HorizontalAlignment {
        switch self.orientation {
        case .leftToRight:
            return .leading
        case .rightToLeft:
            return .trailing
        }
    }

    func sortOrder(forFilter filter: Filter) -> Int {
        // Sort order:
        // 100. Calibrated by earlier session
        //      Sorted by: R, G, B, L, Ha, O3, S2
        // 200. Not calibrated
        //      Sorted by: R, G, B, L, Ha, O3, S2
        // 300. Calibrated by older session
        //      Sorted by: R, G, B, L, Ha, O3, S2
        var score = 0
        let filesInSession = self.session.filesWithFilter(filter)
        if let calSession = filesInSession.calibrationSession {
            if calSession.dateString.compare(self.session.dateString) != .orderedDescending {
                score = 100 // Calibrated by earlier session (or same date) 100-199
                print("Comparing calSession.dateString=\(calSession.dateString) to session.dateString=\(self.session.dateString) got .orderedAscending (score 100)")
            } else {
                score = 300 // Calibrated by later session 300-399
                print("Comparing calSession.dateString=\(calSession.dateString) to session.dateString=\(self.session.dateString) got != .orderedAscending (score 300)")
            }
        } else {
            score = 200 // Not calibrated 200-299
        }
        switch filter.name.lowercased() {
        // RGBL 1-9
        case "red":
            score += 1
        case "green":
            score += 2
        case "blue":
            score += 3
        case "lum":
            score += 4
        // Narrowband 10-19
        case "ha":
            score += 10
        case "o3":
            score += 11
        case "s2":
            score += 12
        // Unknown: 99
        default:
            score += 99
        }
        return score
    }

    var sortedFilters: [Filter] {
        // Returns an array of Filters in this order:
        // - Calibrated by a session before this session
        // - Not yet calibrated
        // - Calibrated by a session after this session
        let filtersByType = self.filters.filter { filter in
            let files = self.session.filesWithFilter(filter)
            let matchingType = files.first { file in
                print("TEST: \(file.type) == \(self.fileType)")
                return file.type.caseInsensitiveCompare(self.fileType) == .orderedSame
            }
            return matchingType != nil
        }
        return filtersByType.sorted { x, y in
            self.sortOrder(forFilter: x) < self.sortOrder(forFilter: y)
        }
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

extension Session {
    func filesWithFilter(_ filter: Filter) -> [File] {
        guard let files = files?.allObjects as? [File] else { return [] }
        return files.filter { $0.filter == filter }
    }

    func calibratesFilesWithFilter(_ filter: Filter) -> [File] {
        guard let files = calibratesFiles?.allObjects as? [File] else { return [] }
        return files.filter { $0.filter == filter }
    }

    func hasFilesWithFilter(_ filter: Filter) -> Bool {
        return self.filesWithFilter(filter).count > 0
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
