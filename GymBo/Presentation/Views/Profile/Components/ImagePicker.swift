//
//  ImagePicker.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Profile Image Picker with Camera and Photo Library
//

import PhotosUI
import SwiftUI

/// Image picker for profile photo
///
/// **Features:**
/// - Photo library selection
/// - Camera capture
/// - Permission handling
/// - Image compression
struct ImagePicker: UIViewControllerRepresentable {

    @Environment(\.dismiss) private var dismiss

    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Action sheet for selecting image source
struct ImageSourcePicker: View {

    @Binding var isPresented: Bool
    let onCameraSelected: () -> Void
    let onPhotoLibrarySelected: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onCameraSelected()
                isPresented = false
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text("Kamera")
                        .font(.body)
                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                onPhotoLibrarySelected()
                isPresented = false
            } label: {
                HStack {
                    Image(systemName: "photo.fill")
                        .font(.title3)
                    Text("Fotobibliothek")
                        .font(.body)
                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            Button(role: .cancel) {
                isPresented = false
            } label: {
                Text("Abbrechen")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Image Compression Helper

extension UIImage {
    /// Compress image to JPEG with max size
    /// - Parameter maxSizeKB: Maximum size in KB (default: 500KB)
    /// - Returns: Compressed image data
    func compressedJPEG(maxSizeKB: Int = 500) -> Data? {
        var compression: CGFloat = 0.9
        var imageData = self.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = self.jpegData(compressionQuality: compression)
        }

        return imageData
    }

    /// Resize image to fit within max dimensions while maintaining aspect ratio
    /// - Parameter maxDimension: Maximum width or height (default: 512px)
    /// - Returns: Resized image
    func resized(maxDimension: CGFloat = 512) -> UIImage {
        let scale = maxDimension / max(size.width, size.height)

        if scale >= 1 {
            return self
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? self
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack {
        Text("Image Source Picker Preview")

        ImageSourcePicker(
            isPresented: .constant(true),
            onCameraSelected: {
                print("Camera selected")
            },
            onPhotoLibrarySelected: {
                print("Photo library selected")
            }
        )
    }
}
#endif
