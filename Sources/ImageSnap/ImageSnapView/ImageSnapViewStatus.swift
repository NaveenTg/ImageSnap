//
//  ImageSnapViewStatus.swift
//  
//
//  Created by Navi on 31/05/21.
//

import Foundation

enum ImageSnapViewStatus {
    case initial
    case rotating(angle: CGAngle)
    case degree90Rotating
    case touchImage
    case touchRotationBoard
    case touchImageSnapboxHandle(tappedEdge: ImageSnapViewOverlayEdge = .none)
    case betweenOperation
}
