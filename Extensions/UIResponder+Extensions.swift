//

import UIKit

extension UIResponder {
    /// Access parent controller
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
