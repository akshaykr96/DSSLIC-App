
import UIKit

public struct pixel {
    public var value: UInt32
    
    //red
    public var R: UInt8 {
        get { return UInt8(value & 0xFF) }
        set {
            let v = max(min(newValue, 255), 0)
            value = UInt32(v) | (value & 0xFFFFFF00)
        }
    }
    
    //green
    public var G: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
        set {
            let v = max(min(newValue, 255), 0)
            value = (UInt32(v) << 8) | (value & 0xFFFF00FF)
        }
    }
    
    //blue
    public var B: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
        set {
            let v = max(min(newValue, 255), 0)
            value = (UInt32(v) << 16) | (value & 0xFF00FFFF)
        }
    }
    
    //alpha
    public var A: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
        set {
            let v = max(min(newValue, 255), 0)
            value = (UInt32(v) << 24) | (value & 0x00FFFFFF)
        }
    }
    
    public var Rf: Double {
        get { return Double(self.R) / 255.0 }
        set {
            self.R = UInt8(max(min(newValue, 1.0), 0.0) * 255.0)
        }
    }
    
    public var Gf: Double {
        get { return Double(self.G) / 255.0 }
        set {
            self.G = UInt8(max(min(newValue, 1.0), 0.0) * 255.0)
        }
    }
    
    public var Bf: Double {
        get { return Double(self.B) / 255.0 }
        set {
            self.B = UInt8(max(min(newValue, 1.0), 0.0) * 255.0)
        }
    }
    
    public var Af: Double {
        get { return Double(self.A) / 255.0 }
        set {
            self.A = UInt8(max(min(newValue, 1.0), 0.0) * 255.0)
        }
    }
}

public struct RGBAImage {
    public var pixels: UnsafeMutableBufferPointer<pixel>
    public var width: Int
    public var height: Int
    
    public init?(image: UIImage) {
        // CGImage로 변환이 가능해야 한다.
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        // 주소 계산을 위해서 Float을 Int로 저장한다.
        width = Int(image.size.width)
        height = Int(image.size.height)
        
        // 4 * width * height 크기의 버퍼를 생성한다.
        let bytesPerRow = width * 4
        let imageData = UnsafeMutablePointer<pixel>.allocate(capacity: width * height)
        
        // 색상공간은 Device의 것을 따른다
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // BGRA로 비트맵을 만든다
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo = bitmapInfo | CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        // 비트맵 생성
        guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        // cgImage를 imageData에 채운다.
        imageContext.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
        
        pixels = UnsafeMutableBufferPointer<pixel>(start: imageData, count: width * height)
    }
    
    
    public init(width: Int, height: Int) {
        let image = RGBAImage.newUIImage(width: width, height: height)
        self.init(image: image)!
    }
    
    public func clone() -> RGBAImage {
        let cloneImage = RGBAImage(width: self.width, height: self.height)
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                cloneImage.pixels[index] = self.pixels[index]
            }
        }
        return cloneImage
    }
    
    public func toUIImage() -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        let bytesPerRow = width * 4
        
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        guard let imageContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil) else {
            return nil
        }
        
        guard let cgImage = imageContext.makeImage() else {
            return nil
        }
        
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    public func pixel(x : Int, _ y : Int) -> pixel? {
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return nil
        }
        
        let address = y * width + x
        return pixels[address]
    }
    
    public mutating func pixel(x : Int, _ y : Int, _ pixel: pixel) {
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return
        }
        
        let address = y * width + x
        pixels[address] = pixel
    }
    
    public mutating func process( functor : ((pixel) -> pixel) ) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let outPixel = functor(pixels[index])
                pixels[index] = outPixel
            }
        }
    }
    
    public func enumerate( functor : (Int, pixel) -> Void) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                functor(index, pixels[index])
            }
        }
    }
    
    private static func newUIImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: CGFloat(width), height: CGFloat(height));
        UIGraphicsBeginImageContextWithOptions(size, true, 0);
        UIColor.black.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
}
