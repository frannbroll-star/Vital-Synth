//
//  VitalbankImporter.swift
//  Vital Synth
//
//  Extracts .vital presets from a .vitalbank ZIP archive and stores them
//  in Documents/ImportedPresets/<BankName>/ for later loading via the engine.
//

import Foundation

// MARK: - Model

struct ImportedPreset: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let bankName: String
    let relativePath: String // relative to importedPresetsDirectory

    init(name: String, bankName: String, relativePath: String) {
        self.id = UUID()
        self.name = name
        self.bankName = bankName
        self.relativePath = relativePath
    }

    var url: URL {
        VitalbankImporter.importedPresetsDirectory.appendingPathComponent(relativePath)
    }
}

// MARK: - Importer

enum VitalbankImporter {

    static var importedPresetsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir  = docs.appendingPathComponent("ImportedPresets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Extracts all .vital files from a .vitalbank ZIP and copies them into
    /// Documents/ImportedPresets/<bankName>/. Returns the imported preset records.
    static func importBank(from bankURL: URL) throws -> [ImportedPreset] {
        let bankName = bankURL.deletingPathExtension().lastPathComponent
        let bankDir  = importedPresetsDirectory.appendingPathComponent(bankName, isDirectory: true)

        // Extract to a temp directory
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let extracted = try ZipExtractor.extractZip(bankURL,
                                                     toDirectory: tmpDir,
                                                     fileExtension: "vital")

        guard !extracted.isEmpty else {
            throw NSError(domain: "VitalbankImporter", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No .vital presets found in this bank"])
        }

        try FileManager.default.createDirectory(at: bankDir, withIntermediateDirectories: true)

        var imported: [ImportedPreset] = []
        for srcURL in extracted {
            let destURL = bankDir.appendingPathComponent(srcURL.lastPathComponent)
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.copyItem(at: srcURL, to: destURL)
            let presetName   = srcURL.deletingPathExtension().lastPathComponent
            let relativePath = "\(bankName)/\(srcURL.lastPathComponent)"
            imported.append(ImportedPreset(name: presetName, bankName: bankName, relativePath: relativePath))
        }

        return imported.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Recursively scans a folder for .vital files.
    ///
    /// Bank name resolution:
    /// - If the immediate parent is named "Presets" (common pack layout), the
    ///   grandparent is used as the bank name, and its sibling "Wavetables/" and
    ///   "Samples/" folders are copied alongside the presets.
    /// - Otherwise the immediate parent name is used.
    /// - Files sitting directly in the root folder use the root name.
    static func importFolder(from folderURL: URL) throws -> [ImportedPreset] {
        let fm         = FileManager.default
        let folderName = folderURL.lastPathComponent
        var results:          [ImportedPreset] = []
        var processedPackDirs = Set<String>()   // track dirs whose aux files we've already copied

        guard let enumerator = fm.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            throw NSError(domain: "VitalbankImporter", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not read folder"])
        }

        for case let item as URL in enumerator {
            guard item.pathExtension.lowercased() == "vital" else { continue }

            let parentDir  = item.deletingLastPathComponent()
            let parentName = parentDir.lastPathComponent

            // If the parent folder is named "Presets", climb to the pack level
            let bankName: String
            let packDir:  URL
            if parentName.localizedCaseInsensitiveCompare("Presets") == .orderedSame {
                let grandParent = parentDir.deletingLastPathComponent()
                bankName = grandParent.lastPathComponent == folderName ? folderName : grandParent.lastPathComponent
                packDir  = grandParent
            } else {
                bankName = parentName == folderName ? folderName : parentName
                packDir  = parentDir
            }

            // Copy Wavetables/ and Samples/ siblings once per pack dir
            if !processedPackDirs.contains(packDir.path) {
                processedPackDirs.insert(packDir.path)
                copyAuxFolders(from: packDir, toBankNamed: bankName, fm: fm)
            }

            let bankDir = importedPresetsDirectory.appendingPathComponent(bankName, isDirectory: true)
            try fm.createDirectory(at: bankDir, withIntermediateDirectories: true)

            let dest = bankDir.appendingPathComponent(item.lastPathComponent)
            try? fm.removeItem(at: dest)
            try fm.copyItem(at: item, to: dest)

            results.append(ImportedPreset(
                name: item.deletingPathExtension().lastPathComponent,
                bankName: bankName,
                relativePath: "\(bankName)/\(item.lastPathComponent)"
            ))
        }

        guard !results.isEmpty else {
            throw NSError(domain: "VitalbankImporter", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "No .vital presets found in folder"])
        }

        return results.sorted {
            $0.bankName == $1.bankName
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : $0.bankName.localizedCaseInsensitiveCompare($1.bankName) == .orderedAscending
        }
    }

    /// Copies Wavetables/ and Samples/ from a pack directory into the bank's
    /// destination folder so the engine can resolve external references.
    private static func copyAuxFolders(from packDir: URL, toBankNamed bankName: String, fm: FileManager) {
        for subfolder in ["Wavetables", "Samples"] {
            let src = packDir.appendingPathComponent(subfolder)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: src.path, isDirectory: &isDir), isDir.boolValue else { continue }

            let dest = importedPresetsDirectory
                .appendingPathComponent(bankName)
                .appendingPathComponent(subfolder)
            try? fm.createDirectory(at: dest, withIntermediateDirectories: true)

            let items = (try? fm.contentsOfDirectory(at: src,
                                                     includingPropertiesForKeys: nil,
                                                     options: .skipsHiddenFiles)) ?? []
            for file in items {
                let fileDest = dest.appendingPathComponent(file.lastPathComponent)
                try? fm.removeItem(at: fileDest)
                try? fm.copyItem(at: file, to: fileDest)
            }
        }
    }
}
