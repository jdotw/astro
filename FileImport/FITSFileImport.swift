//
//  FITSFileImport.swift
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

import Foundation

class FITSFileImport: FileImport {}
//    @Published var header: FITSHeader?
//    @Published var data: Data?
//
//    override init() {
//        super.init()
//        self.fileType = .fits
//    }
//
//    override func importFile() {
//        super.importFile()
//        self.header = nil
//        self.data = nil
//        if let url = self.url {
//            do {
//                let fileData = try Data(contentsOf: url)
//                let header = FITSHeader(data: fileData)
//                self.header = header
//                self.data = fileData
//            } catch {
//                print(error)
//            }
//        }
//    }
