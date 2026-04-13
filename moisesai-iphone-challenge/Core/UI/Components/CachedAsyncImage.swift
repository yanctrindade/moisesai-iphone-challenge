import SwiftUI

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            image = nil
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url else { return }

        if let cached = await ImageCache.shared.get(for: url) {
            image = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return }
            await ImageCache.shared.set(uiImage, for: url, cost: data.count)
            image = uiImage
        } catch {
            // Silently fail — placeholder stays visible
        }
    }
}

actor ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func get(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL, cost: Int) {
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
