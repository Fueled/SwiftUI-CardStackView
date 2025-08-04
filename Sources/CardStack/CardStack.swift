import SwiftUI

public struct CardStack<Direction, ID: Hashable, Data: RandomAccessCollection, Content: View, NoContentView: View>: View
where Data.Index: Hashable {
    
    @Environment(\.cardStackConfiguration) private var configuration: CardStackConfiguration
    @Binding private var currentIndex: Data.Index
    @State private var translation: CGSize = .zero
    @State private var interactingIndex: Data.Index?
    
    private let direction: (Double) -> Direction?
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let onSwipe: (Data.Element, Direction) -> Void
    private let content: (Data.Element, Direction?, Bool) -> Content
    private let noContentView: () -> NoContentView
    
    public init(
        direction: @escaping (Double) -> Direction?,
        data: Data,
        id: KeyPath<Data.Element, ID>,
        currentIndex: Binding<Data.Index>,
        onSwipe: @escaping (Data.Element, Direction) -> Void,
        @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content,
        @ViewBuilder noContentView: @escaping () -> NoContentView
    ) {
        self.direction = direction
        self.data = data
        self.id = id
        self.onSwipe = onSwipe
        self.content = content
        self.noContentView = noContentView
        self._currentIndex = currentIndex
    }
    
    @ViewBuilder private func cardViewOrEmpty(index: Data.Index) -> some View {
        let relativeIndex = self.data.distance(from: self.currentIndex, to: index)
        if relativeIndex >= 0 && relativeIndex < self.configuration.maxVisibleCards {
            self.card(index: index, relativeIndex: relativeIndex)
        } else {
            EmptyView()
        }
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                noContentView()
                    .scaleEffect(
                        1 - self.configuration.cardScale * CGFloat( self.data.distance(from: self.currentIndex, to: self.data.endIndex)),
                        anchor: .bottom
                    )
                    .zIndex(Double(self.data.distance(from: self.data.endIndex, to: self.data.startIndex)))
                ForEach(data.indices.reversed(), id: \.self) { index in
                    cardViewOrEmpty(index: index)
                        .zIndex(Double(self.data.distance(from: index, to: self.data.startIndex)))
                }
            }
            .gesture(self.dragGesture(proxy))
        }
    }
    
    private func dragGesture(_ geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = self.configuration.dragDirection.normalisedTranslation(for: value.translation)
                if translation.width < 0 {
                    self.translation = translation
                } else {
                    if interactingIndex == nil, self.currentIndex != self.data.startIndex {
                        withAnimation(self.configuration.animation) {
                            self.currentIndex = self.data.index(before: currentIndex)
                            self.interactingIndex = currentIndex
                        }
                    }
                    if interactingIndex == nil { return }
                    self.translation = .init(width: translation.width - geometry.size.width, height: translation.height)
                }
            }
            .onEnded { value in
                let translation = self.configuration.dragDirection.normalisedTranslation(for: value.translation)
                if translation.width < 0 {
                    withAnimation {
                        self.translation = translation
                    }
                    if let direction = self.swipeDirection(geometry), currentIndex < self.data.endIndex {
                        withAnimation(self.configuration.animation) {
                            self.onSwipe(self.data[currentIndex], direction)
                            self.translation = .zero
                            withAnimation(self.configuration.animation.delay(self.configuration.revealAnimationDelay)) {
                                self.currentIndex = self.data.index(after: currentIndex)
                            }
                        }
                    } else {
                        withAnimation { self.translation = .zero }
                    }
                } else {
                    if self.swipeDirection(geometry, reversed: true) != nil {
                        withAnimation { self.translation = .zero }
                    } else {
                        withAnimation {
                            self.translation = .init(width: -geometry.size.width - 44, height: 0)
                            withAnimation(self.configuration.animation.delay(self.configuration.revealAnimationDelay)) {
                                if let interactingIndex {
                                    self.currentIndex = self.data.index(after: interactingIndex)
                                }
                                self.translation = .zero
                            }
                        }
                    }
                }
                interactingIndex = nil
            }
    }
    
    private var degree: Double {
        var degree = atan2(translation.width, translation.height) * 180 / .pi
        if degree < 0 { degree += 360 }
        return Double(degree)
    }
    
    private func swipeDirection(_ geometry: GeometryProxy, reversed: Bool = false) -> Direction? {
        guard let direction = direction(degree) else { return nil }
        let threshold = self.configuration.dragDirection.normalisedThresold(in: geometry.size, swipeThresold: configuration.swipeThreshold)
        var distance = hypot(translation.width, translation.height)
        if reversed {
            distance = geometry.size.width - distance
        }
        return distance > threshold ? direction : nil
    }
    
    private func card(index: Data.Index, relativeIndex: Int) -> some View {
        CardView(
            direction: direction,
            isOnTop: relativeIndex == 0,
            translation: relativeIndex == 0 ? translation : .zero,
            onSwipe: { direction in
                self.onSwipe(self.data[index], direction)
                self.currentIndex = self.data.index(after: index)
            },
            content: { direction in
                self.content(self.data[index], direction, relativeIndex == 0)
                    .offset(
                        x: 0,
                        y: CGFloat(relativeIndex) * self.configuration.cardOffset
                    )
                    .scaleEffect(
                        1 - self.configuration.cardScale * CGFloat(relativeIndex),
                        anchor: .bottom
                    )
            }
        )
    }
    
}

extension CardStack where Data.Element: Identifiable, ID == Data.Element.ID {
    
    public init(
        direction: @escaping (Double) -> Direction?,
        data: Data,
        currentIndex: Binding<Data.Index>,
        onSwipe: @escaping (Data.Element, Direction) -> Void,
        @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content,
        @ViewBuilder noContentView: @escaping () -> NoContentView
    ) {
        self.init(
            direction: direction,
            data: data,
            id: \Data.Element.id,
            currentIndex: currentIndex,
            onSwipe: onSwipe,
            content: content,
            noContentView: noContentView
        )
    }
    
}

extension CardStack where Data.Element: Hashable, ID == Data.Element {
    
    public init(
        direction: @escaping (Double) -> Direction?,
        data: Data,
        currentIndex: Binding<Data.Index>,
        onSwipe: @escaping (Data.Element, Direction) -> Void,
        @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content,
        @ViewBuilder noContentView: @escaping () -> NoContentView
    ) {
        self.init(
            direction: direction,
            data: data,
            id: \Data.Element.self,
            currentIndex: currentIndex,
            onSwipe: onSwipe,
            content: content,
            noContentView: noContentView
        )
    }
    
}
