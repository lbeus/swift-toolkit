//
//  Copyright 2025 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import ReadiumShared
import UIKit

class CustomTypeSpreadViewWrapper: UIView, Loggable, PageView, EPUBSpreadViewContainer {
    
    let spread: EPUBSpread
    
    init(spread: EPUBSpread) {
        self.spread = spread
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func progression(in index: ReadingOrder.Index) -> ClosedRange<Double> {
        // To be overridden in subclasses if the resource supports a progression.
        0 ... 1
    }
    
    func go(to location: PageLocation) async {
        // Custom layout resources are always fully visible so we don't use the location
    }
}
