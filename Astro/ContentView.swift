//
//  ContentView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<File>

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        FileView(file: item)
                    } label: {
                        Text(item.name ?? "unnamed")
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func importFITSFile(fileURL: URL) {
        print(fileURL)
        let fits = FITSFile(url: fileURL)
        let headers = fits.headers
        print(fits.headers)
        let newItem = File(context: viewContext)
        newItem.timestamp = Date(fitsDate: headers["DATE-OBS"]!.value!)
        newItem.contentHash = fits.fileHash!
        newItem.name = fileURL.lastPathComponent
        newItem.type = headers["FRAME"]?.value?.lowercased()
    }

    private func importFile(fileURL: URL) {
        if fileURL.isFITS { importFITSFile(fileURL: fileURL) }
    }

    private func addItem() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            for fileURL in panel.urls {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: Set<URLResourceKey>([.isDirectoryKey])),
                      let isDirectory = resourceValues.isDirectory
                else {
                    continue
                }
                if isDirectory {
                    let enumerator = FileManager.default.enumerator(at: panel.url!, includingPropertiesForKeys: nil)
                    while let file = enumerator?.nextObject() as? URL {
                        importFile(fileURL: file)
                    }

                } else {
                    importFile(fileURL: fileURL)
                }
            }
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension URL {
    var isFITS: Bool { pathExtension == "fit" || pathExtension == "fits" }
}
