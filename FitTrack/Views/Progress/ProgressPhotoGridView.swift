import SwiftUI
import SwiftData
import PhotosUI

struct ProgressPhotoGridView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProgressPhoto.date, order: .forward) private var photos: [ProgressPhoto]
    @State private var selectedItem: PhotosPickerItem?
    @State private var expandedPhoto: ProgressPhoto?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(photos) { photo in
                    if let image = loadImage(photo) {
                        image.resizable().scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                            .clipped()
                            .onTapGesture { expandedPhoto = photo }
                    }
                }
            }
            .padding(4)
        }
        .navigationTitle("Progress Photos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Add Photo", systemImage: "plus")
                }
            }
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await savePhoto(item) }
        }
        .sheet(item: $expandedPhoto) { photo in
            if let image = loadImage(photo) {
                image.resizable().scaledToFit()
                    .overlay(alignment: .bottom) {
                        Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding()
                    }
            }
        }
    }

    private func loadImage(_ photo: ProgressPhoto) -> Image? {
        guard let data = try? Data(contentsOf: photo.fileURL),
              let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
    }

    @MainActor
    private func savePhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("progress_photos")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(fileName)
        try? data.write(to: url)
        let record = ProgressPhoto(date: Date(), fileName: fileName)
        context.insert(record)
    }
}
