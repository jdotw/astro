//
//  ExternalProcessingOperation.swift
//  Astro
//
//  Created by James Wilson on 12/11/2023.
//

import Foundation

protocol ExternalProcessingOperation {
    var files: [File] { get }
    var error: Error? { get }
}
