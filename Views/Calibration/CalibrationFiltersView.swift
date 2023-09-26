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

struct CalibrationFiltersView: View {
    @ObservedObject var session: Session
    @FetchRequest var filters: FetchedResults<Filter>
    let orientation: CalibrationFiltersViewOrientation

    init(session: Session, orientation: CalibrationFiltersViewOrientation) {
        self.session = session
        self.orientation = orientation
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

    func line(_ filter: Filter) -> some View {
        GeometryReader { geo in
            switch self.orientation {
            case .leftToRight:
                Path { path in
                    path.move(to: CGPoint(x: 0.0, y: geo.size.height * 0.5))
                    path.addCurve(to: CGPoint(x: geo.size.width, y: 0.0),
                                  control1: CGPoint(x: geo.size.width, y: geo.size.height * 0.5),
                                  control2: CGPoint(x: geo.size.width, y: geo.size.height * 0.5))
                }
                .stroke(style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round))
                .foregroundColor(.white.opacity(self.session.hasFilesWithFilter(filter) ? 1.0 : 0.2))
            case .rightToLeft:
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.5))
                    path.addCurve(to: CGPoint(x: 0.0, y: 0.0),
                                  control1: CGPoint(x: 0, y: geo.size.height * 0.5),
                                  control2: CGPoint(x: 0, y: geo.size.height * 0.5))
                }
                .stroke(style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round))
                .foregroundColor(.white.opacity(self.session.hasFilesWithFilter(filter) ? 1.0 : 0.2))
            }
        }
    }

    var body: some View {
        VStack(alignment: self.vStackAlignment) {
            ForEach(self.filters) { filter in
                HStack {
                    switch self.orientation {
                    case .leftToRight:
                        self.filterName(filter)
                        Spacer()
                        self.filterColor(filter)
                        ViewThatFits {
                            GeometryReader { geo in
                                self.line(filter)
                                    .frame(width: geo.size.height)
                            }
                        }.frame(maxWidth: 20)
                    case .rightToLeft:
                        GeometryReader { geo in
                            self.line(filter)
                                .frame(width: geo.size.height)
                        }
                        Spacer()
                        self.filterColor(filter)
                        self.filterName(filter)
                    }
                }
            }
        }
    }

    var vStackAlignment: HorizontalAlignment {
        switch self.orientation {
        case .leftToRight:
            return .leading
        case .rightToLeft:
            return .trailing
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
    func hasFilesWithFilter(_ filter: Filter) -> Bool {
        guard let files = files?.allObjects as? [File] else { return false }
        return files.contains(where: { $0.filter == filter })
    }
}
