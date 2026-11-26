import UIKit

/// 카메라 · 앨범에서 고른 사진을 자르기 화면에 넘길 JPEG로 만든다(QA A2-6).
///
/// 24 · 48MP 사진을 원본 크기 그대로 메인 스레드에서 인코딩하면 1초 안팎 멈추고, 자르기 '완료'에서 한 장 더
/// 원본 크기로 그려(48MP면 장당 약 190MB) 메모리가 작은 기기에선 강제 종료될 수 있었다.
/// - 긴 변을 `maxPixel`(4096)까지만 남긴다. 자르기는 최소 배율의 4배까지 확대되고 업로드는 긴 변 1024라,
///   흔한 12MP(4032×3024) 사진은 지금과 똑같고, 그보다 큰 사진만 줄어든다 — 확대해 자른 결과의 화질은 12MP와 같은 수준.
/// - 회전 정보를 픽셀에 반영해(위쪽이 위) 자르기 화면이 다시 돌려 그릴 일을 없앤다.
/// - 무거운 그리기 · 인코딩은 메인 스레드 밖에서 한다.
enum PickedImagePreparer {
    static let maxPixel: CGFloat = 4096
    static let quality: CGFloat = 0.95

    static func jpegData(from image: UIImage) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            prepare(image)
        }.value
    }

    private static func prepare(_ image: UIImage) -> Data? {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longSide = max(pixelWidth, pixelHeight)
        guard longSide > 0 else { return nil }

        // 이미 작고 바로 선 사진은 다시 그리지 않는다.
        if longSide <= maxPixel, image.imageOrientation == .up {
            return image.jpegData(compressionQuality: quality)
        }

        let ratio = min(1, maxPixel / longSide)
        // size는 회전 정보가 반영된 크기라, 이대로 그리면 위쪽이 위인 사진이 된다.
        let targetSize = CGSize(width: (pixelWidth * ratio).rounded(), height: (pixelHeight * ratio).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: quality)
    }
}
