//
//  TargetExportController.swift
//  Astro
//
//  Created by James Wilson on 16/9/2023.
//

import Foundation

class TargetExportController: ObservableObject {
    @Published var exported = 0
    @Published var total = 0
    @Published var exporting = false
    @Published var error: Error?
    @Published var files = [TargetExportRequestFile]()

    func performExport(request: TargetExportRequest, completion: @escaping () -> Void) throws {
        exported = 0
        total = 0
        exporting = true
        error = nil
        try request.performBackgroundTask { result in
            switch result {
            case .success(let exportableFiles):
                DispatchQueue.main.sync {
                    self.total = exportableFiles.count
                    self.files = exportableFiles
                }
                self.exportFiles(exportableFiles)
            case .failure(let error):
                DispatchQueue.main.sync {
                    self.error = error
                    self.files = []
                }
            }
            DispatchQueue.main.sync {
                self.exporting = false
                completion()
            }
        }
    }

    private func exportFiles(_ files: [TargetExportRequestFile]) {
        for file in files {
            if file.status == .pending {
                do {
                    try FileManager.default.copyItem(at: file.source.fitsURL, to: file.destination)
                    DispatchQueue.main.sync {
                        file.status = .exported
                        file.error = nil
                    }
                } catch {
                    DispatchQueue.main.sync {
                        file.status = .failed
                        file.error = error
                    }
                }
            }
            DispatchQueue.main.sync {
                self.exported += 1
            }
        }
    }
}
