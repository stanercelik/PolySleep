import SwiftUI
import UIKit

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
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
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Crop to circle and resize
                let croppedImage = cropToCircle(image: image, targetSize: CGSize(width: 300, height: 300))
                parent.completion(croppedImage)
            } else {
                parent.completion(nil)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            parent.dismiss()
        }
        
        private func cropToCircle(image: UIImage, targetSize: CGSize) -> UIImage? {
            // Önce square crop yap
            let squareCroppedImage = cropToSquare(image)
            
            // Sonra resize yap
            let resizedImage = resizeImage(squareCroppedImage, to: targetSize)
            
            // Son olarak circular mask uygula
            return applyCircularMask(to: resizedImage)
        }
        
        private func cropToSquare(_ image: UIImage) -> UIImage {
            let originalSize = image.size
            let sideLength = min(originalSize.width, originalSize.height)
            
            let xOffset = (originalSize.width - sideLength) / 2
            let yOffset = (originalSize.height - sideLength) / 2
            
            let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)
            
            guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
                return image
            }
            
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
        
        private func applyCircularMask(to image: UIImage) -> UIImage? {
            let imageSize = image.size
            let renderer = UIGraphicsImageRenderer(size: imageSize)
            
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: imageSize)
                
                // Circular clipping path oluştur
                let path = UIBezierPath(ovalIn: rect)
                path.addClip()
                
                // Image'i çiz
                image.draw(in: rect)
            }
        }
    }
} 
