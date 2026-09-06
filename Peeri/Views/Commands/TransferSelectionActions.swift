import SwiftUI

struct TransferSelectionActions {
    let canInspect: Bool
    let canReveal: Bool
    let inspect: () -> Void
    let reveal: () -> Void
    let remove: () -> Void
    let open: () -> Void
}
