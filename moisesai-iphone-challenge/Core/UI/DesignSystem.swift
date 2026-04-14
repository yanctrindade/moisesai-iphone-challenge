import SwiftUI

// MARK: - Typography

enum Typography {
    // Song/Track rows (Home, Album)
    static let songTitle: Font = .system(size: 16, weight: .medium)
    static let songSubtitle: Font = .system(size: 12, weight: .medium)

    // Player
    static let playerSongTitle: Font = .system(size: 32, weight: .semibold)
    static let playerArtistName: Font = .system(size: 16, weight: .medium)

    // Navigation
    static let navBarTitle: Font = .system(size: 16, weight: .semibold)

    // Sections
    static let sectionHeader: Font = .headline
    static let searchTitle: Font = .system(size: 24, weight: .semibold)

    // Album
    static let albumTitle: Font = .system(size: 20, weight: .bold)
    static let albumArtist: Font = .system(size: 14, weight: .medium)

    // More Options
    static let sheetTitle: Font = .system(size: 16, weight: .semibold)
    static let sheetButton: Font = .system(size: 16, weight: .medium)

    // Timeline
    static let timeLabel: Font = .caption

    // Controls
    static let transportIcon: Font = .title2
    static let playPauseIcon: Font = .system(size: 32)
    static let repeatIcon: Font = .title3
}

// MARK: - Colors

enum AppColors {
    static let background = Color.black
    static let textPrimary = Color.white
    static let textSecondary = Color.secondary

    // Splash
    static let splashGradientStart = Color(hex: 0x000000)
    static let splashGradientEnd = Color(hex: 0x0086A0)

    // More Options Sheet
    static let sheetBackground = Color(hex: 0x262626, opacity: 0.8)
}

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 40
}

// MARK: - Sizing

enum Sizing {
    // Artwork
    static let songRowArtwork: CGFloat = 50
    static let albumTrackArtwork: CGFloat = 44
    static let albumHeaderArtwork: CGFloat = 120
    static let playerArtwork: CGFloat = 264
    static let splashIcon: CGFloat = 100

    // Controls
    static let playPauseButton: CGFloat = 64
    static let tapTarget: CGFloat = 44

    // Corner radius
    static let cornerRadiusSmall: CGFloat = 6
    static let cornerRadiusMedium: CGFloat = 10
    static let cornerRadiusLarge: CGFloat = 12
    static let cornerRadiusSheet: CGFloat = 16

    // Sheet
    static let moreOptionsSheetHeight: CGFloat = 250
    static let sheetButtonIconSize: CGFloat = 14
    static let sheetButtonPadding: CGFloat = 14

    // MarqueeText
    static let marqueeMaxWidth: CGFloat = 200
}

// MARK: - Timing

enum Timing {
    static let splashFadeIn: Double = 0.3
    static let splashHold: Double = 0.7
    static let splashFadeOut: Double = 0.3
    static let searchDebounce: Duration = .milliseconds(500)
    static let seekDebounce: Duration = .milliseconds(300)
    static let timeObserverThreshold: Double = 0.1
}
