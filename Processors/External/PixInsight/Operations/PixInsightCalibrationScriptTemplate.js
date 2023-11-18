P.enableCFA = true;
P.cfaPattern = ImageCalibration.prototype.Auto;
P.inputHints = "fits-keywords normalize raw cfa signed-is-physical";
P.outputHints = "properties fits-keywords no-compress-data no-embedded-data no-resolution";
P.pedestal = 0;
P.pedestalMode = ImageCalibration.prototype.Keyword;
P.pedestalKeyword = "";
P.overscanEnabled = false;
P.overscanImageX0 = 0;
P.overscanImageY0 = 0;
P.overscanImageX1 = 0;
P.overscanImageY1 = 0;
P.overscanRegions = [ // enabled, sourceX0, sourceY0, sourceX1, sourceY1, targetX0, targetY0, targetX1, targetY1
    [false, 0, 0, 0, 0, 0, 0, 0, 0],
    [false, 0, 0, 0, 0, 0, 0, 0, 0],
    [false, 0, 0, 0, 0, 0, 0, 0, 0],
    [false, 0, 0, 0, 0, 0, 0, 0, 0]
];
P.masterBiasEnabled = true;
P.masterBiasPath = "/Users/jwilson/Desktop/Astro/Batch-20230415-Processed/Calibration/bias.xisf";
P.masterDarkEnabled = true;
P.masterDarkPath = "/Users/jwilson/Desktop/Astro/Batch-20230415-Processed/Calibration/dark.xisf";
P.masterFlatEnabled = true;
P.calibrateBias = false;
P.calibrateDark = false;
P.calibrateFlat = false;
P.optimizeDarks = true;
P.darkOptimizationThreshold = 0.00000;
P.darkOptimizationLow = 3.0000;
P.darkOptimizationWindow = 0;
P.darkCFADetectionMode = ImageCalibration.prototype.DetectCFA;
P.separateCFAFlatScalingFactors = true;
P.flatScaleClippingFactor = 0.05;
P.evaluateNoise = true;
P.noiseEvaluationAlgorithm = ImageCalibration.prototype.NoiseEvaluation_MRS;
P.evaluateSignal = true;
P.structureLayers = 5;
P.saturationThreshold = 1.00;
P.saturationRelative = false;
P.noiseLayers = 1;
P.hotPixelFilterRadius = 1;
P.noiseReductionFilterRadius = 0;
P.minStructureSize = 0;
P.psfType = ImageCalibration.prototype.PSFType_Moffat4;
P.psfGrowth = 1.00;
P.maxStars = 24576;
P.outputExtension = ".xisf";
P.outputPrefix = "";
P.outputPostfix = "";
P.outputSampleFormat = ImageCalibration.prototype.f32;
P.outputPedestal = 0;
P.outputPedestalMode = ImageCalibration.prototype.OutputPedestal_Literal;
P.autoPedestalLimit = 0.00010;
P.overwriteExistingFiles = false;
P.onError = ImageCalibration.prototype.Continue;
P.noGUIMessages = true;
P.useFileThreads = true;
P.fileThreadOverload = 1.00;
P.maxFileReadThreads = 0;
P.maxFileWriteThreads = 0;
/*
 * Read-only properties
 *
 P.outputData = [ // outputFilePath, darkScalingFactorRK, darkScalingFactorG, darkScalingFactorB, psfTotalFluxEstimateRK, psfTotalFluxEstimateG, psfTotalFluxEstimateB, psfTotalPowerFluxEstimateRK, psfTotalPowerFluxEstimateG, psfTotalPowerFluxEstimateB, psfTotalMeanFluxEstimateRK, psfTotalMeanFluxEstimateG, psfTotalMeanFluxEstimateB, psfTotalMeanPowerFluxEstimateRK, psfTotalMeanPowerFluxEstimateG, psfTotalMeanPowerFluxEstimateB, psfMStarEstimateRK, psfMStarEstimateG, psfMStarEstimateB, psfNStarEstimateRK, psfNStarEstimateG, psfNStarEstimateB, psfCountRK, psfCountG, psfCountB, noiseEstimateRK, noiseEstimateG, noiseEstimateB, noiseFractionRK, noiseFractionG, noiseFractionB, noiseScaleLowRK, noiseScaleLowG, noiseScaleLowB, noiseScaleHighRK, noiseScaleHighG, noiseScaleHighB, noiseAlgorithmRK, noiseAlgorithmG, noiseAlgorithmB
 ];
 */
