//
//  StarRectsView.swift
//  Astro
//
//  Created by James Wilson on 16/8/2023.
//

import SwiftUI

struct StarRectsView: View {
    let file: File
    @Binding var showStarRects: Bool
    let image: NSImage?

    var body: some View {
        Image(nsImage: image ?? NSImage())
            .resizable()
            .scaledToFill()
            .overlay(alignment: .topLeading, content: {
                if showStarRects {
                    GeometryReader { geometry in
                        let xScale = image != nil ? geometry.size.width / image!.size.width : 0.0
                        let yScale = image != nil ? geometry.size.height / image!.size.height : 0.0
                        ForEach(regionRects, id: \.self) { region in
                            let scaledRect = NSRect(x: region.origin.x * xScale,
                                                    y: region.origin.y * yScale,
                                                    width: region.width * xScale,
                                                    height: region.height * yScale)
                            let drawRect = NSRect(x: scaledRect.minX,
                                                  y: scaledRect.minY,
                                                  width: max(scaledRect.width, 1),
                                                  height: max(scaledRect.height, 1))
                            Rectangle()
                                //                                .fill(.red)
                                .stroke(lineWidth: 1.0)
                                .foregroundStyle(.red)
                                .position(x: drawRect.midX, y: drawRect.midY)
                                .frame(width: drawRect.width,
                                       height: drawRect.height,
                                       alignment: .topLeading)
                        }
                        let testRest = CGRect(origin: CGPoint(x: 0.0 * xScale, y: 0.0 * yScale),
                                              size: CGSize(width: max(10.0 * xScale, 4.0),
                                                           height: max(10.0 * yScale, 4.0)))
                        let drawTestRect = CGRect(origin: CGPoint(x: testRest.midX, y: testRest.midY),
                                                  size: CGSize(width: testRest.width,
                                                               height: testRest.height))
                        Rectangle()
                            .stroke(lineWidth: 1.0)
                            .foregroundStyle(.green)
                            .position(x: drawTestRect.minX, y: drawTestRect.minY)
                            .frame(width: drawTestRect.width,
                                   height: drawTestRect.height,
                                   alignment: .topLeading)
                    }
                }
            })
    }

    var regionRects: [NSRect] {
        if let regions = file.regions as? Set<Region> {
            return regions.map { region in
                NSRect(x: Int(region.x),
                       y: Int(region.y),
                       width: Int(region.width),
                       height: Int(region.height))
            }
        } else {
            return []
        }
    }
}

extension NSRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minX)
        hasher.combine(minY)
        hasher.combine(maxX)
        hasher.combine(maxY)
    }
}
