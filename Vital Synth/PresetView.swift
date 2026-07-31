//
//  PresetView.swift
//  Vital Synth
//
//  Preset browser, randomiser UI, import/export.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - FileDocument for export

struct PresetExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data
    init(_ data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Save Preset Sheet

struct SavePresetSheet: View {
    @Binding var name: String
    @Binding var category: String
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let categories = PresetStyle.allCases.map(\.rawValue) + ["Custom"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Preset Name")) {
                    TextField("Name", text: $name)
                }
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            let emoji = PresetStyle(rawValue: cat)?.emoji ?? "🎵"
                            Text("\(emoji)  \(cat)").tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(VitalColors.labelText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name, category); dismiss() }
                        .foregroundColor(VitalColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preset Sheet

struct PresetSheet: View {
    @ObservedObject var manager: PresetManager
    let engine: VitalAudioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab    = 0
    @State private var selectedStyle: PresetStyle = .pad
    @State private var saveNameText   = ""
    @State private var saveCategory   = "Custom"
    @State private var showSaveSheet  = false
    @State private var showImport     = false
    @State private var showExport     = false
    @State private var exportDoc      = PresetExportDocument()
    @State private var previewNotes: Set<Int> = []
    @State private var bankImportResult: String? = nil

    // C major chord for auto-preview
    private let previewChord = [60, 64, 67]

    private var totalPresetCount: Int {
        manager.presets.count + manager.importedPresets.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("RANDOM").tag(0)
                    Text(totalPresetCount > 0 ? "SAVED (\(totalPresetCount))" : "SAVED").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(VitalColors.headerBg)

                if selectedTab == 0 {
                    randomTab
                } else {
                    savedTab
                }

                // ── Preview keyboard ─────────────────────────────────────────
                previewKeyboardStrip
            }
            .background(VitalColors.background.ignoresSafeArea())
            .navigationTitle(totalPresetCount > 0 ? "Presets (\(totalPresetCount))" : "Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(VitalColors.accent)
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                SavePresetSheet(name: $saveNameText, category: $saveCategory) { name, cat in
                    var preset = engine.capturePreset(name: name.isEmpty ? engine.currentPatch : name)
                    preset.category = cat
                    manager.save(preset)
                }
            }
            .fileExporter(isPresented: $showExport, document: exportDoc,
                          contentType: .json, defaultFilename: "vital_presets") { _ in }
            .fileImporter(isPresented: $showImport,
                          allowedContentTypes: [
                              .json,
                              UTType(filenameExtension: "vital",     conformingTo: .data) ?? .data,
                              UTType(filenameExtension: "vitalbank", conformingTo: .data) ?? .data,
                              .folder
                          ],
                          onCompletion: handleImport)
            .alert("Bank Imported", isPresented: Binding(
                get: { bankImportResult != nil },
                set: { if !$0 { bankImportResult = nil } }
            )) {
                Button("OK") { bankImportResult = nil }
            } message: {
                Text(bankImportResult ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Random tab

    private var randomTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Style grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 8
                ) {
                    ForEach(PresetStyle.allCases) { style in
                        Button { selectedStyle = style } label: {
                            VStack(spacing: 5) {
                                Text(style.emoji).font(.system(size: 24))
                                Text(style.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(selectedStyle == style
                                        ? .black : VitalColors.labelText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedStyle == style
                                ? VitalColors.accent : VitalColors.body)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                // Randomize + auto-preview chord
                Button {
                    engine.allNotesOff()
                    previewNotes.removeAll()
                    let preset = manager.randomPreset(style: selectedStyle)
                    engine.applyPreset(preset)
                    playPreviewChord()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "dice.fill")
                        Text("RANDOMIZE")
                            .font(.system(size: 14, weight: .black)).tracking(1.5)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(VitalColors.accent)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .buttonStyle(.plain)

                // Save current
                Button {
                    saveNameText = engine.currentPatch
                    saveCategory = "Custom"
                    showSaveSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Current Patch")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(VitalColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(VitalColors.body)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(VitalColors.accent.opacity(0.35), lineWidth: 1))
                }
                .padding(.horizontal)
                .buttonStyle(.plain)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Saved tab

    private var savedTab: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 16) {
                Button {
                    saveNameText = engine.currentPatch
                    saveCategory = "Custom"
                    showSaveSheet = true
                } label: {
                    Label("Save Current", systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    if let data = manager.exportData() {
                        exportDoc = PresetExportDocument(data)
                        showExport = true
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.accent)
                }
                .buttonStyle(.plain)
                .disabled(manager.presets.isEmpty)

                Button {
                    showImport = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down.on.square")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.accent)
                }
                .buttonStyle(.plain)

                Button {
                    showImport = true
                } label: {
                    Label("Import Bank", systemImage: "archivebox.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.modTeal)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(VitalColors.bodyHeading)

            if manager.presets.isEmpty && manager.importedPresets.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 44))
                        .foregroundColor(VitalColors.labelText.opacity(0.5))
                    Text("No saved presets yet.\nRandomize something and save it,\nor tap Import Bank to load a .vitalbank file.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13))
                        .foregroundColor(VitalColors.labelText)
                }
                Spacer()
            } else {
                List {
                    customPresetSections
                    importedBankSections
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - List sections

    @ViewBuilder private var customPresetSections: some View {
        ForEach(orderedCategories, id: \.self) { cat in
            let inCat = manager.presets.filter { $0.category == cat }
            if !inCat.isEmpty {
                Section(header: categoryHeader(cat)) {
                    ForEach(inCat) { preset in
                        presetRow(preset)
                            .listRowBackground(VitalColors.body)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { manager.delete(preset) }
                                    label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder private var importedBankSections: some View {
        ForEach(manager.importedBankNames, id: \.self) { bankName in
            let inBank = manager.importedPresets.filter { $0.bankName == bankName }
            Section(header: bankHeader(bankName)) {
                ForEach(inBank) { preset in
                    importedPresetRow(preset)
                        .listRowBackground(VitalColors.body)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { manager.deleteImported(preset) }
                                label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
        }
    }

    // MARK: - Category helpers

    private var orderedCategories: [String] {
        let defined = PresetStyle.allCases.map(\.rawValue) + ["Custom"]
        var seen = Set(defined)
        var extras: [String] = []
        for p in manager.presets where !seen.contains(p.category) {
            seen.insert(p.category); extras.append(p.category)
        }
        return defined + extras
    }

    private func categoryHeader(_ cat: String) -> some View {
        let emoji = PresetStyle(rawValue: cat)?.emoji ?? "🎵"
        let count = manager.presets.filter { $0.category == cat }.count
        return HStack(spacing: 6) {
            Text(emoji)
            Text(cat.uppercased())
                .font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundColor(VitalColors.labelText)
            Spacer()
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(VitalColors.labelText.opacity(0.7))
        }
        .textCase(nil)
    }

    private func bankHeader(_ name: String) -> some View {
        let count = manager.importedPresets.filter { $0.bankName == name }.count
        return HStack(spacing: 6) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 9))
                .foregroundColor(VitalColors.modTeal)
            Text(name.uppercased())
                .font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundColor(VitalColors.modTeal)
            Spacer()
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(VitalColors.modTeal.opacity(0.8))
        }
        .textCase(nil)
    }

    private func importedPresetRow(_ preset: ImportedPreset) -> some View {
        Button {
            engine.allNotesOff()
            previewNotes.removeAll()
            engine.loadVitalPreset(from: preset.url)
            // Brief delay for engine to load before chord preview
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { playPreviewChord() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 16))
                    .foregroundColor(VitalColors.modTeal)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(VitalColors.bodyText)
                    Text(preset.bankName)
                        .font(.system(size: 10))
                        .foregroundColor(VitalColors.modTeal.opacity(0.7))
                }

                Spacer()

                Image(systemName: "play.circle")
                    .font(.system(size: 16))
                    .foregroundColor(VitalColors.modTeal.opacity(0.6))
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // Tap to preview — no dismiss. Use "Done" to close.
    private func presetRow(_ preset: VitalPreset) -> some View {
        Button {
            engine.allNotesOff()
            previewNotes.removeAll()
            engine.applyPreset(preset)
            playPreviewChord()
        } label: {
            HStack(spacing: 12) {
                Text(PresetStyle(rawValue: preset.category)?.emoji ?? "🎵")
                    .font(.system(size: 20))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(VitalColors.bodyText)
                    Text(preset.category)
                        .font(.system(size: 10))
                        .foregroundColor(VitalColors.labelText)
                }

                Spacer()

                Image(systemName: "play.circle")
                    .font(.system(size: 16))
                    .foregroundColor(VitalColors.accent.opacity(0.6))
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview keyboard strip

    private var previewKeyboardStrip: some View {
        VStack(spacing: 0) {
            // Strip header
            HStack(spacing: 10) {
                Text("PREVIEW")
                    .font(.system(size: 8, weight: .bold)).tracking(1.2)
                    .foregroundColor(VitalColors.labelText)
                Spacer()
                // Chord preview button
                Button { playPreviewChord() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill").font(.system(size: 9))
                        Text("C maj").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(VitalColors.accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(VitalColors.body)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(VitalColors.bodyHeading)

            // Keys
            GeometryReader { geo in
                let whites = [60, 62, 64, 65, 67, 69, 71]
                let blacks: [(midi: Int, lw: Int)] = [
                    (61, 0), (63, 1), (66, 3), (68, 4), (70, 5)
                ]
                let gap: CGFloat = 1
                let ww = (geo.size.width - CGFloat(whites.count + 1) * gap) / CGFloat(whites.count)
                let bw = ww * 0.58
                let bh = geo.size.height * 0.62

                ZStack(alignment: .topLeading) {
                    Color(white: 0.10)
                    HStack(spacing: gap) {
                        ForEach(whites, id: \.self) { midi in
                            previewWhiteKey(midi: midi, w: ww, h: geo.size.height)
                        }
                    }
                    .padding(.leading, gap)
                    ForEach(blacks, id: \.midi) { bk in
                        previewBlackKey(
                            midi: bk.midi,
                            x: gap + CGFloat(bk.lw) * (ww + gap) + ww * 0.60,
                            w: bw, h: bh)
                    }
                }
            }
        }
        .frame(height: 90)
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(Color.white.opacity(0.10)), alignment: .top)
    }

    private func previewWhiteKey(midi: Int, w: CGFloat, h: CGFloat) -> some View {
        let pressed = previewNotes.contains(midi)
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    gradient: Gradient(stops: pressed
                        ? [.init(color: Color(red: 0.63, green: 0.53, blue: 1.0), location: 0),
                           .init(color: Color(red: 0.80, green: 0.72, blue: 1.0), location: 1)]
                        : [.init(color: Color(white: 0.90), location: 0),
                           .init(color: Color(white: 0.97), location: 0.4),
                           .init(color: Color(white: 0.84), location: 1)]),
                    startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(pressed ? 0.06 : 0.18))
                .frame(height: 4)
        }
        .frame(width: w, height: h)
        .scaleEffect(pressed
            ? CGSize(width: 0.97, height: 0.97)
            : CGSize(width: 1.0,  height: 1.0), anchor: .bottom)
        .animation(.easeOut(duration: 0.06), value: pressed)
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !previewNotes.contains(midi) {
                    previewNotes.insert(midi)
                    engine.noteOn(note: midi, velocity: 0.75)
                }
            }
            .onEnded { _ in
                previewNotes.remove(midi)
                engine.noteOff(note: midi)
            })
    }

    private func previewBlackKey(midi: Int, x: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        let pressed = previewNotes.contains(midi)
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    gradient: Gradient(stops: pressed
                        ? [.init(color: Color(red: 0.50, green: 0.40, blue: 0.90), location: 0),
                           .init(color: Color(red: 0.22, green: 0.16, blue: 0.48), location: 1)]
                        : [.init(color: Color(white: 0.20), location: 0),
                           .init(color: Color(white: 0.06), location: 1)]),
                    startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(pressed ? 0.0 : 0.08))
                .frame(height: h * 0.28)
        }
        .frame(width: w, height: h)
        .scaleEffect(pressed
            ? CGSize(width: 0.96, height: 0.95)
            : CGSize(width: 1.0,  height: 1.0), anchor: .bottom)
        .animation(.easeOut(duration: 0.06), value: pressed)
        .offset(x: x)
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !previewNotes.contains(midi) {
                    previewNotes.insert(midi)
                    engine.noteOn(note: midi, velocity: 0.80)
                }
            }
            .onEnded { _ in
                previewNotes.remove(midi)
                engine.noteOff(note: midi)
            })
    }

    // MARK: - Helpers

    private func playPreviewChord() {
        previewChord.forEach { engine.noteOn(note: $0, velocity: 0.72) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            previewChord.forEach { engine.noteOff(note: $0) }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let ext   = url.pathExtension.lowercased()

        if isDir {
            // Folder of .vital presets
            let accessing   = url.startAccessingSecurityScopedResource()
            let folderName  = url.lastPathComponent
            Task {
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                do {
                    let count = try await manager.importFolder(from: url)
                    let noun  = count == 1 ? "preset" : "presets"
                    bankImportResult = "Imported \(count) \(noun) from \"\(folderName)\""
                } catch {
                    bankImportResult = error.localizedDescription
                }
            }
        } else if ext == "vitalbank" {
            // Copy while security scope is active, then extract async
            let accessing = url.startAccessingSecurityScopedResource()
            let tmpCopy = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tmpCopy)
            try? FileManager.default.copyItem(at: url, to: tmpCopy)
            if accessing { url.stopAccessingSecurityScopedResource() }

            let bankName = url.deletingPathExtension().lastPathComponent
            Task {
                do {
                    let count = try await manager.importBank(from: tmpCopy)
                    let noun = count == 1 ? "preset" : "presets"
                    bankImportResult = "Imported \(count) \(noun) from \"\(bankName)\""
                } catch {
                    bankImportResult = error.localizedDescription
                }
                try? FileManager.default.removeItem(at: tmpCopy)
            }
        } else {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            if ext == "vital" {
                engine.loadVitalPreset(from: url)
                dismiss()
            } else {
                guard let data = try? Data(contentsOf: url) else { return }
                manager.importData(data)
            }
        }
    }
}
