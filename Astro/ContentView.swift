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
    private var files: FetchedResults<File>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>

    var body: some View {
        NavigationView {
            List {
                ForEach(files) { file in
                    NavigationLink {
                        FileView(file: file)
                    } label: {
                        VStack {
                            Text(file.name ?? "unnamed")
                            Text(file.target?.name ?? "unknown target")
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                ForEach(sessions) { session in
                    NavigationLink {} label: {
                        VStack {
                            Text(session.dateString ?? "unknown")
                        }
                    }
                }
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
        print("URL: \(fileURL)")
        guard let fits = FITSFile(url: fileURL),
              let headers = fits.headers else { return }
        print(headers)
        do {
            _ = try fits.importFile(context: viewContext)
        } catch {
            print(error)
        }
    }

    private func importFile(fileURL: URL) {
        if fileURL.isFITS { importFITSFile(fileURL: fileURL) }
    }

    private func addItem() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            for fileURL in panel.urls {
                if fileURL.startAccessingSecurityScopedResource() {
                    defer { fileURL.stopAccessingSecurityScopedResource() }

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
            offsets.map { files[$0] }.forEach(viewContext.delete)

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
