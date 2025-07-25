//
//  DragDirection.swift
//  CardStack
//
//  Created by Ratnesh Jain on 25/07/25.
//


import Foundation

public enum DragDirection: Sendable {
    case horizontal
    case vertical
    case all
}

extension DragDirection {
    func normalisedTranslation(for translation: CGSize) -> CGSize {
        switch self {
        case .horizontal:
            CGSize(width: translation.width, height: 0)
        case .vertical:
            CGSize(width: 0, height: translation.height)
        case .all:
            translation
        }
    }
    
    func normalisedThresold(in size: CGSize, swipeThresold: CGFloat) -> CGFloat {
        switch self {
        case .horizontal:
            size.width * swipeThresold
        case .vertical:
            size.height * swipeThresold
        case .all:
            min(size.width, size.height) * swipeThresold
        }
    }
}
