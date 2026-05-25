//
//  ProfileImageCropView.swift
//  Presentation
//
//  Created by suni on 5/20/26.
//

import SwiftUI
import UIKit
import ComposableArchitecture
import DesignSystem
import CoreKit

public struct ProfileImageCropView: View {
    @Bindable var store: StoreOf<ProfileImageCropFeature>

    public init(store: StoreOf<ProfileImageCropFeature>) {
        self.store = store
    }

    /// 자식 `UIScrollView`로 직접 호출하기 위한 크롭 트리거.
    /// "완료" 탭 시 SwiftUI에서 이 토큰을 변경하면 ScrollView가 현재 위치를 기준으로 크롭한 Data를 반환.
    @State private var cropRequestID: UUID? = nil

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                let cropSide = min(geometry.size.width, geometry.size.height) - 40
                let cropRect = CGRect(
                    x: (geometry.size.width - cropSide) / 2,
                    y: (geometry.size.height - cropSide) / 2,
                    width: cropSide,
                    height: cropSide
                )

                ZStack {
                    if let image = UIImage(data: store.originalImageData) {
                        CropScrollView(
                            image: image,
                            cropRect: cropRect,
                            containerSize: geometry.size,
                            cropRequestID: cropRequestID,
                            onCropped: { data in
                                store.send(.view(.confirmTapped(croppedImageData: data)))
                            }
                        )
                    }

                    // 크롭 영역 외 dimmed 마스크 + 정사각형 가이드
                    CropMaskOverlay(cropRect: cropRect)
                        .allowsHitTesting(false)
                }
            }

            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(true)
    }

    // MARK: - Top / Bottom Bars

    private var topBar: some View {
        HStack {
            Button {
                store.send(.view(.cancelTapped))
            } label: {
                Text("취소")
                    .font(Font.pretendard.bodyM)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private var bottomBar: some View {
        HStack {
            Spacer()
            Button {
                cropRequestID = UUID()
            } label: {
                Text("완료")
                    .font(Font.pretendard.buttonM)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 16)
    }
}

// MARK: - CropMaskOverlay

/// 크롭 영역 바깥을 어둡게 가리고 정사각형 가이드를 그린다.
private struct CropMaskOverlay: View {
    let cropRect: CGRect

    var body: some View {
        ZStack {
            // dim
            Color.black.opacity(0.5)
                .mask(
                    Rectangle()
                        .overlay(
                            Rectangle()
                                .frame(width: cropRect.width, height: cropRect.height)
                                .position(x: cropRect.midX, y: cropRect.midY)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                )

            // 가이드 라인
            Rectangle()
                .stroke(Color.white, lineWidth: 1)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
        }
    }
}

// MARK: - CropScrollView (UIScrollView 래퍼)

/// `UIScrollView`로 핀치 줌·팬을 처리해 1:1 크롭을 수행하는 SwiftUI 호스트.
///
/// - `cropRect`(컨테이너 좌표계)는 화면 가운데 정사각형 영역.
/// - 사용자가 줌/팬으로 이미지를 원하는 위치에 맞추면 `onCropped`가 해당 영역을 잘라 PNG Data로 돌려준다.
/// - `cropRequestID`가 변할 때마다 크롭을 실행 (부모에서 "완료" 버튼이 트리거).
private struct CropScrollView: UIViewRepresentable {
    let image: UIImage
    let cropRect: CGRect
    let containerSize: CGSize
    let cropRequestID: UUID?
    let onCropped: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCropped: onCropped)
    }

    func makeUIView(context: Context) -> CropScrollContainerView {
        let view = CropScrollContainerView(image: image, cropRect: cropRect, containerSize: containerSize)
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: CropScrollContainerView, context: Context) {
        context.coordinator.onCropped = onCropped
        uiView.update(cropRect: cropRect, containerSize: containerSize)

        if let cropRequestID, cropRequestID != context.coordinator.lastHandledRequestID {
            context.coordinator.lastHandledRequestID = cropRequestID
            uiView.performCrop()
        }
    }

    final class Coordinator {
        var onCropped: (Data) -> Void
        var lastHandledRequestID: UUID?
        init(onCropped: @escaping (Data) -> Void) { self.onCropped = onCropped }
    }
}

// MARK: - CropScrollContainerView (UIView)

/// `UIScrollView` + 내부 `UIImageView`로 핀치 줌·팬을 처리한다.
private final class CropScrollContainerView: UIView, UIScrollViewDelegate {
    weak var coordinator: CropScrollView.Coordinator?

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let image: UIImage

    private var currentCropRect: CGRect
    private var currentContainerSize: CGSize
    private var hasConfiguredInitialZoom = false

    init(image: UIImage, cropRect: CGRect, containerSize: CGSize) {
        self.image = image
        self.currentCropRect = cropRect
        self.currentContainerSize = containerSize
        super.init(frame: .zero)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func configure() {
        backgroundColor = .clear

        scrollView.delegate = self
        scrollView.bouncesZoom = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentInsetAdjustmentBehavior = .never

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size

        scrollView.addSubview(imageView)
        addSubview(scrollView)
    }

    func update(cropRect: CGRect, containerSize: CGSize) {
        currentCropRect = cropRect
        currentContainerSize = containerSize
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = CGRect(
            x: currentCropRect.minX,
            y: currentCropRect.minY,
            width: currentCropRect.width,
            height: currentCropRect.height
        )
        scrollView.clipsToBounds = false

        if !hasConfiguredInitialZoom, image.size.width > 0, image.size.height > 0 {
            hasConfiguredInitialZoom = true
            configureZoomScales()
            centerImage()
        }
    }

    private func configureZoomScales() {
        let cropSide = currentCropRect.width
        // 정사각형 크롭 박스를 이미지의 짧은 변에 맞추는 최소 배율
        let minScale = max(cropSide / image.size.width, cropSide / image.size.height)
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = max(minScale * 4, 1)
        scrollView.zoomScale = minScale
    }

    private func centerImage() {
        let scaled = imageView.frame.size
        let offsetX = max((scaled.width - scrollView.bounds.width) / 2, 0)
        let offsetY = max((scaled.height - scrollView.bounds.height) / 2, 0)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    // MARK: - Crop

    func performCrop() {
        // contentOffset/zoom으로 이미지 좌표계상의 크롭 영역을 계산
        let zoom = scrollView.zoomScale
        let visibleRect = CGRect(
            x: scrollView.contentOffset.x / zoom,
            y: scrollView.contentOffset.y / zoom,
            width: scrollView.bounds.width / zoom,
            height: scrollView.bounds.height / zoom
        )

        guard let cgImage = image.cgImage else {
            Log.trace("CropScrollContainerView: cgImage 없음 — 크롭 실패", category: .system, level: .error)
            return
        }

        // UIImage의 orientation을 반영해 픽셀 좌표계로 변환
        let orientedImage = image.normalizedOrientation()
        guard let orientedCG = orientedImage.cgImage else {
            Log.trace("CropScrollContainerView: 정규화된 cgImage 없음", category: .system, level: .error)
            _ = cgImage
            return
        }

        // imageView는 scaleAspectFit이지만 frame을 image.size로 직접 깔았으므로
        // visibleRect는 곧 픽셀 좌표(orientedImage.size 기준).
        let scaleX = CGFloat(orientedCG.width) / orientedImage.size.width
        let scaleY = CGFloat(orientedCG.height) / orientedImage.size.height

        let pixelRect = CGRect(
            x: visibleRect.minX * scaleX,
            y: visibleRect.minY * scaleY,
            width: visibleRect.width * scaleX,
            height: visibleRect.height * scaleY
        ).integral

        guard let cropped = orientedCG.cropping(to: pixelRect) else {
            Log.trace("CropScrollContainerView: cropping(to:) 실패 — rect=\(pixelRect)", category: .system, level: .error)
            return
        }

        let croppedImage = UIImage(cgImage: cropped, scale: orientedImage.scale, orientation: .up)
        guard let data = croppedImage.jpegData(compressionQuality: 0.9) else {
            Log.trace("CropScrollContainerView: JPEG 인코딩 실패", category: .system, level: .error)
            return
        }
        coordinator?.onCropped(data)
    }
}

// MARK: - UIImage helper

private extension UIImage {
    /// EXIF orientation을 픽셀 데이터에 적용해 `.up`으로 정규화한 이미지를 반환.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size, format: imageRendererFormat)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
