//
//  CategoryList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

enum CategoryItem: String, Identifiable, CaseIterable {
    var id: String { rawValue }

    case sessions
    case targets
    case files
}

struct CategoryList: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var selection: CategoryItem

    var body: some View {
        List(CategoryItem.allCases, selection: $selection) { item in
            NavigationLink(
                item.rawValue.localizedCapitalized,
                value: item
            )
        }
    }
}
