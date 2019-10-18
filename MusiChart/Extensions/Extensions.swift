import Foundation
import UIKit
import ImageIO

// MARK: UIImageView extensions
extension UIImageView {

    // Apply drop shadow
    func applyShadow() {
        let layer           = self.layer
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOffset  = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.4
        layer.shadowRadius  = 2
    }

    // Load image from URL without caching it
    func loadImageWithURL(url: URL, callback: @escaping (UIImage) -> Void) {
        let session = URLSession.shared

        let downloadTask = session.downloadTask(with: url, completionHandler: { [weak self] url, _, error in

            guard let url = url, error == nil else { return }
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data as Data)  else { return }
                
                DispatchQueue.main.async(execute: {
                    guard let strongSelf = self else { return }
                    strongSelf.image = image
                    callback(image)
                })
                
            } catch {
                print(error.localizedDescription)
            }
        })

        downloadTask.resume()
    }
}

// MARK: String extensions

extension String {

    func decodeAll() -> String {
        
        guard let dataStr = data(using: String.Encoding.utf8) else { return "" }
        guard let decodedString = String(data: dataStr, encoding: String.Encoding.utf8) else { return "" }
        return decodedString
    }

    func encodeURIComponent() -> String? {
        
        let allowedCharacterSet = (CharacterSet(charactersIn: "^!*'();:@&=+$/?%#[]").inverted)
        return addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }

    func refineForLastFM() -> String? {
        
        let newString = (self.replacingOccurrences(of: "&", with: "and")).replacingOccurrences(of: "(CH)", with: "")
        return newString
    }
    
    func combine(with label: UILabel) -> NSAttributedString? {
        
        guard let font1 = UIFont(name: label.font.fontName, size: 15.0), let text = label.text else { return nil }
        let attribute1 = [NSAttributedString.Key.font: font1]
        let placeholderString = NSAttributedString(string: text, attributes: attribute1)
        
        guard let font2 = UIFont(name: label.font.fontName, size: 18.0) else { return nil }
        let attribute2 = [NSAttributedString.Key.font: font2]
        let nameString = NSAttributedString(string: "  \(self)", attributes: attribute2)
        
        let combination = NSMutableAttributedString()
        combination.append(placeholderString)
        combination.append(nameString)
        
        return combination
    }
}

// MARK: UIColor extensions

extension UIColor {
    
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}

// MARK: UIView extensions

extension UIView {
    
    func getImage() -> UIImage? {
        let view = self

        scaler(view)

        let rescale: CGFloat = 4

        // Create a large Image by rendering the scaled view
        let bigSize = CGSize(width: view.frame.size.width*rescale, height: view.frame.size.height*rescale)
        UIGraphicsBeginImageContextWithOptions(bigSize, true, 1)
        let context = UIGraphicsGetCurrentContext()!

        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: CGPoint(x: 0, y: 0), size: bigSize))

        // Must increase the transform scale
        context.scaleBy(x: rescale, y: rescale)

        view.layer.render(in: context)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    private func scaler(_ view: UIView) {
        if !view.isKind(of: UIStackView.self) {
            view.contentScaleFactor = 8
        }
        for stackView in view.subviews {
            scaler(stackView)
        }
    }
}

// MARK: UIViewController extensions

extension UIViewController {
    
    func showAlert(withTitle title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
    
    func hideAlert() {
        guard let presentedViewController = presentedViewController else { return }
        let isAlertPresented = presentedViewController.isKind(of: UIAlertController.self)
        
        if isAlertPresented {
            presentedViewController.dismiss(animated: false, completion: nil)
        }
    }
}

// MARK: ViewModel Extensions

protocol ViewModelBased: class {

    associatedtype ViewModelType

    var viewModel: ViewModelType? { get set }

    func bindViewModel()

}

extension ViewModelBased where Self: UIViewController {

    func bindViewModel(to model: Self.ViewModelType) {
        viewModel = model
        loadViewIfNeeded()
        bindViewModel()
    }

}
