//
//  CategoryList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

enum CategorySectionItem: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case images
    case calibration
}

enum CategoryItem: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    
    // Lights
    case sessions
    case targets
    case files
    case calibration
    
    // Calibration
    case calFlats
    case calDarks
    case calBias
}

struct CategoryList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selection: CategoryItem
    @State var lightsExpanded: Bool = true
    
    var body: some View {
        List(selection: $selection) {
            Section(header: Text("Lights"), footer: Text("Expanded: \(lightsExpanded)")) {
                NavigationLink("Sessions", value: CategoryItem.sessions)
                NavigationLink("Targets", value: CategoryItem.targets)
                NavigationLink("Files", value: CategoryItem.files)
                NavigationLink("Calibration", value: CategoryItem.calibration)
            }
            Section(header: Text("Calibration"), footer: Text("Expanded: \(lightsExpanded)")) {
                NavigationLink("Flats", value: CategoryItem.calFlats)
                NavigationLink("Darks", value: CategoryItem.calDarks)
                NavigationLink("Bias", value: CategoryItem.calBias)
            }
        }
    }
}
