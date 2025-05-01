//
//  FilterScrollView.swift


import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct FilterScrollView: View {
    let filterOptions: [FilterOption] = [
    .sepia,
    .blackAndWhite,
    .vignette,
    .chrome,
    .fade,
    .tone,
    .transfer]
    
    let inputImage: UIImage // The UIImage to be filtered
    
    var filteredImageHandler: ((UIImage) -> Void)? // Closure to handle the filtered image

    @State private var selectedFilter: FilterOption?
       
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem()]) {
                ForEach(filterOptions, id: \.self) { filter in
                    FilterView(filter: filter)
                        .frame(width: 75, height: 75)
                        .padding(4)
                        .background(selectedFilter == filter ? Color.black : Color.brown)
                        .cornerRadius(8)
                        .onTapGesture {
                            // Action when filter is tapped
                            selectedFilter = filter
                            if let filteredImage = applyFilter(filter, to: inputImage) {
                                // Pass the filtered image to the handler closure
                                filteredImageHandler?(filteredImage)
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

extension FilterScrollView {
    // Function to apply Core Image filter based on selected FilterOption
    func applyFilter(_ filterOption: FilterOption, to inputImage: UIImage) -> UIImage? {
        let context = CIContext()
        guard let ciImage = CIImage(image: inputImage) else { return nil }

        let filter: CIFilter
        switch filterOption {
            case .sepia:
                filter = CIFilter(name: "CISepiaTone")!
            case .blackAndWhite:
                filter = CIFilter(name: "CIColorMonochrome")!
            
                // addtional parameters for the fix for the real black and white
                filter.setValue(CIColor(red: 0.6, green: 0.6, blue: 0.6), forKey: kCIInputColorKey) // Set to pure black
                filter.setValue(1.0, forKey: kCIInputIntensityKey) // Full intensity for black-and-white
              
            case .vignette:
                filter = CIFilter(name: "CIVignette")!
            case .chrome:
                filter = CIFilter(name: "CIPhotoEffectChrome")!
            case .fade:
                filter = CIFilter(name: "CIPhotoEffectFade")!
            case .tone:
                filter = CIFilter(name: "CIPhotoEffectTonal")!
            case .transfer:
                filter = CIFilter(name: "CIPhotoEffectTransfer")!
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        if let outputCIImage = filter.outputImage,
           let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
            return UIImage(cgImage: outputCGImage)
        } else {
            return nil
        }
    }
}
