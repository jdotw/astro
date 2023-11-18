//
//  TargetExportOperation.swift
//  Astro
//
//  Created by James Wilson on 13/11/2023.
//

import Foundation

class TargetExportOperation: Operation {
    // Exports all the files, both light and calibration frames,
    // for a given target and arranges them in this structure:
    //
    //  Target
    //  |-> Batch 1
    //      |-> Filter 1
    //          |-> Calibration
    //          |-> Light
    //      |-> Filter 2
    //          |-> Calibration
    //          |-> Light
    //  |-> Batch 2
    //      |-> Filter 1
    //          |-> Calibration
    //          |-> Light
    //      |-> Filter 2
    //          |-> Calibration
    //          |-> Light

}
