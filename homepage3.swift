import SwiftUI
import QuickLook

struct HomePage3: View {

    let fileURL: URL

    var body: some View {

        QuickLookPreview(
            url: fileURL
        )
        .navigationTitle("File")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(
        context: Context
    ) -> QLPreviewController {

        let controller = QLPreviewController()

        controller.dataSource =
            context.coordinator

        return controller
    }

    func updateUIViewController(
        _ controller: QLPreviewController,
        context: Context
    ) {
    }

    func makeCoordinator() -> Coordinator {

        Coordinator(url: url)
    }

    class Coordinator:
        NSObject,
        QLPreviewControllerDataSource {

        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(
            in controller: QLPreviewController
        ) -> Int {

            return 1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {

            return url as NSURL
        }
    }
}
