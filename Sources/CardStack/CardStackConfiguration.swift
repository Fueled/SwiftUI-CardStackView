import SwiftUI

public struct CardStackConfiguration: EnvironmentKey {
    
    public static var defaultValue = CardStackConfiguration()
    
    let maxVisibleCards: Int
    let swipeThreshold: Double
    let cardOffset: CGFloat
    let cardScale: CGFloat
    let animation: Animation
    let dragDirection: DragDirection
    let revealAnimationDelay: Double
    
    public init(
        maxVisibleCards: Int = 3,
        swipeThreshold: Double = 0.5,
        cardOffset: CGFloat = 10,
        cardScale: CGFloat = 0.1,
        animation: Animation = .default,
        dragDirection: DragDirection = .horizontal,
        revealAnimationDelay: Double = 0.25
    ) {
        self.maxVisibleCards = maxVisibleCards
        self.swipeThreshold = swipeThreshold
        self.cardOffset = cardOffset
        self.cardScale = cardScale
        self.animation = animation
        self.dragDirection = dragDirection
        self.revealAnimationDelay = revealAnimationDelay
    }
}

extension EnvironmentValues {
    public var cardStackConfiguration: CardStackConfiguration {
        get { self[CardStackConfiguration.self] }
        set { self[CardStackConfiguration.self] = newValue }
    }
}
