//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

struct MultiFileView: View {
    var files: Set<File>
    @State private var exposureValue: Double = 0
    @State private var selection: Set<File> = []
    @State private var itemSize: CGFloat = 250
    @Binding var focusedFile: File?
    @Binding var navStackPath: [File]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(files.map { $0 }) { file in
//                    NavigationLink(value: file) {
                    GalleryItem(file: file, size: itemSize, isSelected: selection.contains(file))
                        .gesture(TapGesture(count: 2).onEnded {
                            print("double clicked")
                            navStackPath.append(file)
                        })
                        .simultaneousGesture(TapGesture().onEnded {
                            print("Single.. bruh")
                            selection = [file]
                        })
//                    }
                }
            }
        }
        .padding([.horizontal, .top])
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ItemSizeSlider(size: $itemSize)
        }
        .onTapGesture {
            selection = []
        }
    }
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: itemSize, maximum: itemSize), spacing: 40)]
    }
    
    private struct GalleryItem: View {
        var file: File
        var size: CGFloat
        var isSelected: Bool
        
        var body: some View {
            VStack {
                GalleryImage(file: file, size: size)
                    .background(selectionBackground)
                Text(verbatim: file.name)
                    .font(.callout)
            }
            .frame(width: size)
        }
        
        @ViewBuilder
        var selectionBackground: some View {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.selection)
            }
        }
    }
    
    private struct GalleryImage: View {
        var file: File
        var size: CGFloat
        
        var body: some View {
            AsyncImage(url: file.rawDataURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(background)
                    .frame(width: size, height: size)
            } placeholder: {
                Image(systemName: "moon.stars")
                    .symbolVariant(.fill)
                    .font(.system(size: 40))
                    .foregroundColor(Color.accentColor)
                    .background(background)
                    .frame(width: size, height: size)
            }
        }
        
        var background: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: size, height: size)
        }
    }
    
    private struct ItemSizeSlider: View {
        @Binding var size: CGFloat
        
        var body: some View {
            HStack {
                Spacer()
                Slider(value: $size, in: 100 ... 500)
                    .controlSize(.small)
                    .frame(width: 100)
                    .padding(.trailing)
            }
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }
}
