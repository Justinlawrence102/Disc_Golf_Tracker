// https://www.artemnovichkov.com/blog/remove-background-from-image-in-swiftui
import Foundation
import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

@Observable
class RemoveImageBackgroundModel {
 
    var image: UIImage?
    var isLoading = false
    private var processingQueue = DispatchQueue(label: "ProcessingQueue")
    var showEditProfileSheet = false
    
    init(image: UIImage? = nil) {
        self.image = image
    }
    
    func createSticker() {
        guard let inputImage = CIImage(image: image ?? UIImage()) else {
            print("Failed to create CIImage")
            return
        }
        
        processingQueue.async {
            guard let maskImage = self.subjectMaskImage(from: inputImage) else {
                print("Failed to create mask image")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            let outputImage = self.apply(mask: maskImage, to: inputImage)
            let image = self.render(ciImage: outputImage)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }

    private func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
        let handler = VNImageRequestHandler(ciImage: inputImage)
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            print(error)
            return nil
        }
        
        guard let result = request.results?.first else {
            print("No observations found")
            return nil
        }
        do {
            let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            return CIImage(cvPixelBuffer: maskPixelBuffer)
        } catch {
            print(error)
            return nil
        }
    }

    private func apply(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    private func render(ciImage: CIImage) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage)
    }

}
