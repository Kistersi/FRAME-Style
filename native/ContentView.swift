import SwiftUI
import PhotosUI
import Photos
import CoreImage
import CoreImage.CIFilterBuiltins

private enum AtelierTab: String, CaseIterable {
    case atelier = "Atelier"
    case gallery = "Galerie"
    case styles = "Stile"
    case settings = "Info"

    var symbol: String {
        switch self {
        case .atelier: "slider.horizontal.3"
        case .gallery: "square.grid.2x2"
        case .styles: "sparkles"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedItem: PhotosPickerItem?
    @State private var aiReturnedItem: PhotosPickerItem?
    @State private var aiStudio = false
    @State private var originalImage: UIImage?
    @State private var editedImage: UIImage?
    @State private var selectedStyle: PhotoStyle = .darkCinematic
    @State private var blackAndWhite = false
    @State private var selectedTab: AtelierTab = .atelier
    @State private var statusMessage = "Dein Foto bleibt auf diesem Gerät."
    @State private var isShowingOriginal = false

    private let ciContext = CIContext()

    var body: some View {
        GeometryReader { geometry in
            let usePadWorkspace = geometry.size.width >= 760
            ZStack {
                Color(red: 0.067, green: 0.063, blue: 0.059).ignoresSafeArea()
                if usePadWorkspace {
                    iPadLayout(size: geometry.size)
                } else {
                    iPhoneLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: selectedItem) { _, item in
            Task { await loadPhoto(item) }
        }
        .onChange(of: aiReturnedItem) { _, item in
            Task { await loadAIResult(item) }
        }
    }

    private var brandHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("FRAME / STYLE")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .tracking(2.4)
                Text("YOUR PERSONAL PHOTO ATELIER")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Text("NATIVE 0.3.0")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(red: 0.88, green: 0.70, blue: 0.49))
                .padding(.horizontal, 10).padding(.vertical, 7)
                .overlay(Capsule().stroke(Color(red: 0.50, green: 0.39, blue: 0.27)))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var iPhoneLayout: some View {
        VStack(spacing: 10) {
            brandHeader
            if selectedTab == .atelier {
                phoneEditor
            } else {
                secondaryTab
            }
            phoneTabBar
        }
        .padding(.bottom, 4)
    }

    private var phoneEditor: some View {
        VStack(spacing: 10) {
            previewArea
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 12)
            if originalImage != nil {
                compactControls
            } else {
                emptyPicker
                    .frame(maxHeight: 210)
                    .padding(.horizontal, 16)
                Spacer(minLength: 0)
            }
        }
    }

    private var emptyPicker: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 38))
                .foregroundStyle(accent)
            Text("Dein Moment. Dein Look.")
                .font(.system(size: 20, weight: .medium, design: .serif))
            Text("Wähle ein Foto aus deiner Mediathek. Die Bearbeitung bleibt lokal.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
            photoPickerButton
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(line))
    }

    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.45))
            if let originalImage {
                if let editedImage {
                    HStack(spacing: 5) {
                        previewColumn(image: originalImage, label: "ORIGINAL")
                        previewColumn(image: editedImage, label: "FRAME / STYLE")
                    }
                    .padding(7)
                } else {
                    Image(uiImage: originalImage)
                        .resizable().scaledToFit()
                        .padding(8)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("Deine Bildvorschau")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(line))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func previewColumn(image: UIImage, label: String) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.system(size: 9, weight: .bold)).tracking(1.2)
                .foregroundStyle(accent)
            Image(uiImage: image).resizable().scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var compactControls: some View {
        VStack(spacing: 9) {
            Picker("Bearbeitungsmodus", selection: $aiStudio) {
                Text("LOCAL").tag(false)
                Text("AI STUDIO").tag(true)
            }
            .pickerStyle(.segmented)

            if aiStudio {
                VStack(spacing: 8) {
                    Text("AI STUDIO · CHATGPT")
                        .font(.system(size: 10, weight: .bold)).tracking(1.4)
                        .foregroundStyle(accent)
                    Text("Übergib dein Foto über das iOS-Teilen-Menü an ChatGPT. Speichere das Ergebnis anschließend in Fotos und importiere es hier wieder.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58))
                        .multilineTextAlignment(.center)
                    if let originalImage {
                        ShareLink(
                            item: Image(uiImage: originalImage),
                            subject: Text("FRAME / STYLE – AI STUDIO"),
                            message: Text("Bitte bearbeite dieses Foto im Stil \(selectedStyle.rawValue), Farbvariante \(blackAndWhite ? "Schwarz-Weiß" : "Farbig"). Erhalte Motiv, Personen, Gegenstände, Bildausschnitt und Perspektive unverändert. Verändere nur den fotografischen Look. Keine neuen oder entfernten Objekte und kein Text.")
                        ) {
                            Label("An ChatGPT übergeben", systemImage: "arrowshape.turn.up.right")
                                .frame(maxWidth: .infinity).padding(.vertical, 11)
                        }
                        .buttonStyle(.borderedProminent).tint(accent).foregroundStyle(.black)
                    }
                    PhotosPicker(selection: $aiReturnedItem, matching: .images) {
                        Label("ChatGPT-Ergebnis importieren", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity).padding(.vertical, 9)
                    }
                    .buttonStyle(.bordered).tint(accent)
                    Text("Die Übergabe startet nur durch deine Auswahl. ChatGPT ist eine separate App; die Rückgabe erfolgt durch Import.")
                        .font(.system(size: 9)).foregroundStyle(.white.opacity(0.42))
                }
            } else {
                HStack {
                    Text("FOTOSTIL").font(.system(size: 10, weight: .bold)).tracking(1.5)
                    Spacer()
                    Text(selectedStyle.rawValue).font(.caption).foregroundStyle(accent)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(PhotoStyle.allCases) { style in styleChip(style) }
                    }
                }
                HStack(spacing: 8) {
                    colorModeButton("Farbig", isSelected: !blackAndWhite) { blackAndWhite = false }
                    colorModeButton("Schwarz-Weiß", isSelected: blackAndWhite) { blackAndWhite = true }
                    Button(action: renderPhoto) {
                        Label("Umwandeln", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent).tint(accent).foregroundStyle(.black)
                    .disabled(originalImage == nil)
                }
            }
            HStack {
                photoPickerButton
                Spacer()
                Button("Speichern", systemImage: "square.and.arrow.down", action: savePhoto)
                    .font(.caption.weight(.semibold))
                    .disabled(editedImage == nil)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(panel)
    }

    private func iPadLayout(size: CGSize) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                brandHeader
                Divider().overlay(line)
                Text("BEARBEITUNG").font(.system(size: 10, weight: .bold)).tracking(1.7).foregroundStyle(accent)
                Text("Fotostil").font(.headline)
                ForEach(PhotoStyle.allCases) { style in
                    styleRow(style)
                }
                Divider().overlay(line)
                Text("Farbvariante").font(.headline)
                colorModeButton("Farbig", isSelected: !blackAndWhite) { blackAndWhite = false }
                colorModeButton("Schwarz-Weiß", isSelected: blackAndWhite) { blackAndWhite = true }
                Spacer()
                photoPickerButton
                Button(action: renderPhoto) {
                    Label("Jetzt umwandeln", systemImage: "sparkles")
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent).tint(accent).foregroundStyle(.black)
                .disabled(originalImage == nil)
                Button("Ergebnis in Fotos sichern", systemImage: "square.and.arrow.down", action: savePhoto)
                    .buttonStyle(.bordered).tint(accent)
                    .disabled(editedImage == nil)
                Text("NATIVE 0.3.0 · LOKALE VERARBEITUNG")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(20)
            .frame(width: min(max(size.width * 0.27, 250), 330))
            .background(panel)

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Foto-Atelier").font(.system(size: 25, weight: .medium, design: .serif))
                        Text(statusMessage).font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    photoPickerButton
                }
                previewArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if originalImage == nil { emptyPicker }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var secondaryTab: some View {
        VStack(spacing: 14) {
            Text(selectedTab.rawValue).font(.system(size: 25, weight: .medium, design: .serif))
            if selectedTab == .styles {
                ForEach(PhotoStyle.allCases) { style in styleRow(style) }
            } else if selectedTab == .gallery {
                Text("Deine gespeicherten Bilder findest du in deiner Fotos-App.")
                    .foregroundStyle(.white.opacity(0.55)).font(.footnote)
            } else {
                Text("FRAME / STYLE Native 0.3.0\nBildverarbeitung erfolgt lokal auf deinem Gerät.")
                    .multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
        .padding()
    }

    private var phoneTabBar: some View {
        HStack {
            ForEach(AtelierTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol).font(.system(size: 17))
                        Text(tab.rawValue).font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? accent : .white.opacity(0.48))
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .background(panel)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 10)
    }

    private func styleChip(_ style: PhotoStyle) -> some View {
        Button { selectedStyle = style } label: {
            Text(style.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 11).padding(.vertical, 9)
                .foregroundStyle(selectedStyle == style ? .black : .white)
                .background(selectedStyle == style ? accent : panel, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func styleRow(_ style: PhotoStyle) -> some View {
        Button { selectedStyle = style } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(style.rawValue).font(.system(size: 13, weight: .semibold))
                    Text(style.subtitle).font(.system(size: 10)).foregroundStyle(.white.opacity(0.48))
                }
                Spacer()
                if selectedStyle == style {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(accent)
                }
            }
            .padding(10)
            .background(selectedStyle == style ? accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func colorModeButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .foregroundStyle(isSelected ? accent : .white.opacity(0.7))
                .background(isSelected ? accent.opacity(0.13) : panel, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? accent : line))
        }
        .buttonStyle(.plain)
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label("Foto auswählen", systemImage: "photo.badge.plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
                .padding(.vertical, 9)
        }
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            statusMessage = "Das Foto konnte nicht geladen werden."
            return
        }
        originalImage = image
        editedImage = nil
        statusMessage = "Foto geladen – bereit zur Bearbeitung."
    }

    @MainActor
    private func loadAIResult(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            statusMessage = "Das ChatGPT-Ergebnis konnte nicht geladen werden."
            return
        }
        editedImage = image
        statusMessage = "ChatGPT-Ergebnis importiert – bereit zum Speichern."
    }

    private func renderPhoto() {
        guard let originalImage, let input = CIImage(image: originalImage) else { return }
        var output = input
        let controls = CIFilter.colorControls()
        controls.inputImage = output

        switch selectedStyle {
        case .urbanBW:
            controls.saturation = 0
            controls.contrast = 1.35
            controls.brightness = -0.02
        case .darkCinematic:
            controls.saturation = 0.82
            controls.contrast = 1.2
            controls.brightness = -0.12
        case .warmVintage:
            let sepia = CIFilter.sepiaTone()
            sepia.inputImage = output
            sepia.intensity = 0.38
            output = sepia.outputImage ?? output
            controls.inputImage = output
            controls.saturation = 1.08
            controls.contrast = 0.96
            controls.brightness = 0.02
        case .coldBlue:
            controls.saturation = 0.84
            controls.contrast = 1.08
            controls.brightness = 0.01
        case .naturalPro:
            controls.saturation = 1.08
            controls.contrast = 1.06
            controls.brightness = 0.01
        case .softMono:
            controls.saturation = 0
            controls.contrast = 0.92
            controls.brightness = 0.05
        case .custom:
            controls.saturation = 1.04
            controls.contrast = 1.02
            controls.brightness = 0
        }
        output = controls.outputImage ?? output
        if blackAndWhite {
            let mono = CIFilter.colorControls()
            mono.inputImage = output
            mono.saturation = 0
            output = mono.outputImage ?? output
        }
        guard let cgImage = ciContext.createCGImage(output, from: output.extent) else {
            statusMessage = "Die Umwandlung ist fehlgeschlagen."
            return
        }
        editedImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        statusMessage = "\(selectedStyle.rawValue) · lokal umgewandelt"
    }

    private func savePhoto() {
        guard let editedImage else { return }
        statusMessage = "Speichere in Album FRAMESTYLE …"

        // Creating or finding a named album requires read/write Photo Library access.
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in
                    statusMessage = "Bitte erlaube FRAME / STYLE den Zugriff auf deine Fotomediathek."
                }
                return
            }

            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "localizedTitle == %@", "FRAMESTYLE")
            let albums = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: options
            )
            let existingAlbum = albums.firstObject

            PHPhotoLibrary.shared().performChanges({
                let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: editedImage)
                guard let placeholder = assetRequest.placeholderForCreatedAsset else { return }

                let albumRequest: PHAssetCollectionChangeRequest
                if let existingAlbum,
                   let changeRequest = PHAssetCollectionChangeRequest(for: existingAlbum) {
                    albumRequest = changeRequest
                } else {
                    guard let createRequest = PHAssetCollectionChangeRequest
                        .creationRequestForAssetCollection(withTitle: "FRAMESTYLE") else {
                        return
                    }
                    albumRequest = createRequest
                }
                albumRequest.addAssets([placeholder] as NSArray)
            }) { success, error in
                Task { @MainActor in
                    if success {
                        statusMessage = "Gespeichert im Album „FRAMESTYLE“."
                    } else {
                        statusMessage = error?.localizedDescription ?? "Speichern im Album fehlgeschlagen."
                    }
                }
            }
        }
    }

    private var accent: Color { Color(red: 0.84, green: 0.66, blue: 0.44) }
    private var panel: Color { Color(red: 0.105, green: 0.098, blue: 0.09) }
    private var line: Color { Color(red: 0.23, green: 0.20, blue: 0.17) }
}
