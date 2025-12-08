//
//  Copyright 2025 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import ReadiumShared
import UIKit

class CustomTypeSpreadView: UIView, Loggable, PageView {
    func go(to location: PageLocation) async {
        // Custom layout resources are always fully visible so we don't use the location
    }
}
