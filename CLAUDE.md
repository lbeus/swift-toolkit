# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Readium Swift Toolkit** is a toolkit for ebooks, audiobooks and comics written in Swift. It provides libraries for parsing, rendering, and interacting with digital publications in formats like EPUB, PDF, audiobooks (Readium Audiobook, standalone audio), and image collections (DIVINA, CBZ). It includes support for Readium LCP DRM.

## Common Commands

### Testing
```bash
# Run all tests
make test

# Run tests for specific module (via xcodebuild)
xcodebuild test -scheme "Readium-Package" -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:ReadiumSharedTests
```

### Code Formatting
```bash
# Format code (required before submitting PRs)
make format

# Check formatting without modifying files
make lint-format
```

### EPUB Navigator JavaScript Development
When modifying JavaScript files in `Sources/Navigator/EPUB/Scripts`:
```bash
# Rebuild JavaScript bundles after making changes
make scripts

# Update JavaScript dependencies
make update-scripts
```

The EPUB Navigator injects JavaScript into publications. `index-reflowable.js` is the entry point for reflowable EPUBs, while `index-fixed.js` is for fixed-layout EPUBs. Fixed-layout EPUBs use HTML wrapper pages (`fxl-spread-one.html`, `fxl-spread-two.html`) with corresponding wrapper scripts (`index-fixed-wrapper-one.js`, `index-fixed-wrapper-two.js`).

### Other Commands
```bash
# Generate Carthage Xcode project
make carthage-project

# Update accessibility localization files
make update-a11y-l10n
```

## Architecture

### Module Organization

The toolkit is organized into six core libraries and two adapter libraries:

#### **ReadiumShared** (`Sources/Shared`)
- Core data models: `Publication`, `Manifest`, `Metadata`, `Link`, `Locator`
- Resource abstractions: `Resource`, `Container`, `Asset` for file access
- Publication services framework: extensible services like `PositionsService`, `SearchService`, `CoverService`
- HTTP server abstraction for serving local publications
- OPDS catalog models
- Toolkit utilities: format detection, XML/ZIP/PDF parsing, logging

#### **ReadiumStreamer** (`Sources/Streamer`)
- Parses publication files into `Publication` objects
- Format-specific parsers: `EPUBParser`, `PDFParser`, `AudioParser`, `ImageParser`, `ReadiumWebPubParser`
- `PublicationOpener`: High-level API orchestrating parsing, DRM unlocking, and service injection
- Handles encryption, font deobfuscation, and content transformations

#### **ReadiumNavigator** (`Sources/Navigator`)
- UIView-based rendering of publications
- Base `Navigator` protocol with directional navigation
- Format-specific navigators: `EPUBNavigatorViewController`, PDF/Audiobook/CBZ navigators
- Preference/settings system for reader customization
- Decorator API for highlights, underlines, and visual decorations
- Supports text selection (`SelectableNavigator`) and visual decorations (`DecorableNavigator`)

#### **ReadiumOPDS** (`Sources/OPDS`)
- OPDS 1.2 and 2.0 catalog parsing
- Feed structures, acquisition links, availability metadata
- For library and bookstore integrations

#### **ReadiumLCP** (`Sources/LCP`)
- Readium LCP (Lightweight Content Protection) DRM support
- License validation, authentication, content decryption
- Requires `R2LCPClient.framework` from EDRLab (contact@edrlab.org)

#### **ReadiumAdapterGCDWebServer & ReadiumAdapterLCPSQLite** (`Sources/Adapters`)
- Adapters for third-party dependencies
- GCDWebServer: HTTP server implementation for serving local publications
- SQLite: Database backend for LCP license storage

### Key Architectural Patterns

#### Publication Flow
Publications move through this pipeline:
```
File/URL → Asset → Parser → Publication.Builder → [Transforms] → Publication → Navigator
```

1. **Asset**: Wraps file/URL with format detection
2. **Parser**: Format-specific parser extracts manifest from package structure
3. **Builder**: Accumulates manifest, container, and services
4. **Transforms**: Applied for DRM, service injection, content modifications
5. **Publication**: Immutable publication object
6. **Navigator**: Renders publication content to user

#### Service-Oriented Architecture
- Publications are extended via `PublicationService` protocol
- Services injected at publication creation time
- Examples: `PositionsService` (pagination), `SearchService`, `CoverService`, `ContentService`
- Services use `Weak<Publication>` references to prevent circular dependencies

#### Container/Resource Abstraction
- `Container`: Protocol providing access to multiple `Resource` entries (files in ZIP, HTTP endpoints)
- `Resource`: Proxy to actual content with transparent access
- `CompositeContainer`: Chains multiple containers for layered access
- `TransformingContainer`: Applies transformations (CSS injection, deobfuscation, decryption)
- Enables transparent access to packaged, remote, and encrypted publications

#### EPUB Navigator JavaScript Bridge
The EPUB Navigator uses WKWebView with bidirectional JavaScript communication:

**Swift → JavaScript:**
- `evaluateJavaScript()` executes scripts in loaded resources
- Used for: navigation commands, decorator updates, preference changes

**JavaScript → Swift:**
- JavaScript calls `window.webkit.messageHandlers.NAME.postMessage(data)`
- Registered handlers: "log", "logError", "tap", "pointerEvent", "keyEvent"
- Swift receives via `WKScriptMessageHandler` protocol

**Script Injection:**
- Scripts injected at `atDocumentStart` (before DOM loads)
- Separate bundles for reflowable (`readium-reflowable.js`) and fixed layouts (`readium-fixed.js`)
- Handles: pagination, selection, events, decorations, spread measurement

**CSS Injection:**
- `ReadiumCSS` transforms user preferences into CSS custom properties
- Applied via `ResourceTransformer` before serving resources to WebView
- Controls: typography, spacing, themes, colors, publisher style overrides

#### Preferences System
```
User Preferences → PreferencesEditor → Effective Settings → CSS/Rendering
```

- `EPUBPreferences`: User-facing settings (font size, theme, margins, etc.)
- `EPUBSettings`: Computed effective values with defaults applied
- `Preference<T>`: Individual preference handle tracking value and effectiveValue
- `PreferencesEditor`: Mutable editor with real-time validation
- Preferences can be unset (nil) to fall back to effective defaults

### Important Conventions

#### Async/Await Throughout
- All I/O and navigator operations use Swift concurrency
- `@MainActor` on UI-related protocols (`NavigatorDelegate`, `EPUBNavigatorDelegate`)
- Results wrapped in `ReadResult<T>` (success/failure enum)

#### Protocol Composition
Navigators conform to multiple protocols:
- `VisualNavigator`: Basic navigation interface
- `SelectableNavigator`: Text selection capability
- `DecorableNavigator`: Highlights/decorations support
- `Configurable`: Settings management

#### Builder Pattern for Immutable Objects
- `Publication.Builder`: Accumulates manifest, container, services
- `Transform` closures applied at each stage for modifications
- `build()` creates final immutable `Publication`

#### Resource Transformer Pattern
```swift
typealias ResourceTransformer = (AnyURL, Resource) -> Resource?
```
Applied on HTTP requests before serving content. Used for CSS injection, deobfuscation, content transformation.

#### Delegate Pattern for Callbacks
- `NavigatorDelegate`: Navigation events (location changed, jump, errors)
- `EPUBNavigatorDelegate`: EPUB-specific events (viewport, user scripts)
- `SelectableNavigatorDelegate`: Text selection events
- All delegates are `@MainActor` with optional implementations

#### Locator Model
- Represents a discrete position in a publication
- Contains: `href`, `position` (in positions list), text selection, reading progression
- Roundtrip: Navigator → Locator (bookmark) → Navigator

## Project Structure

```
Sources/
├── Shared/           # Core models, resource abstractions, services
├── Streamer/         # Publication parsers and opening logic
├── Navigator/        # Rendering components (EPUB, PDF, Audiobook, CBZ)
│   └── EPUB/Scripts/ # JavaScript layer for EPUB rendering
├── OPDS/             # OPDS catalog support
├── LCP/              # Readium LCP DRM
├── Adapters/         # Third-party library adapters
└── Internal/         # Internal utilities

Tests/                # Test suites mirror Sources structure
TestApp/              # Sample reading application
docs/Guides/          # User guides and documentation
```

## Swift Package Manager

This project uses Swift Package Manager. Dependencies are defined in `Package.swift`. The project requires:
- iOS 13.4+
- Swift 5.10+ (develop branch requires Swift 6.0)
- Xcode 15.4+ (develop branch requires Xcode 16.2)

Main dependencies: CryptoSwift, Zip, DifferenceKit, Fuzi (XML), GCDWebServer, ZIPFoundation, SwiftSoup, SQLite.swift

## Code Formatting

The project uses SwiftFormat with configuration in `.swiftformat`. Key settings:
- Swift version: 5.6
- Custom header template with copyright
- Excludes: Carthage directory
- Strip unused closure arguments only

**Always run `make format` before committing changes.**

## Testing

Tests are organized by module:
- `Tests/SharedTests`: ReadiumShared tests
- `Tests/StreamerTests`: ReadiumStreamer tests
- `Tests/NavigatorTests`: ReadiumNavigator tests
- `Tests/OPDSTests`: ReadiumOPDS tests
- `Tests/InternalTests`: ReadiumInternal tests

Tests use XCTest framework. Test fixtures are in `Tests/*/Fixtures` directories.

## Key Files to Reference

### Core Architecture
- `Sources/Shared/Publication/Publication.swift` - Central publication model
- `Sources/Shared/Publication/Manifest.swift` - Web Publication Manifest
- `Sources/Streamer/PublicationOpener.swift` - Opening flow orchestration
- `Sources/Streamer/Parser/PublicationParser.swift` - Parser protocol

### Navigation
- `Sources/Navigator/Navigator.swift` - Base navigator protocol
- `Sources/Navigator/VisualNavigator.swift` - Visual rendering interface
- `Sources/Navigator/EPUB/EPUBNavigatorViewController.swift` - Main EPUB UI
- `Sources/Navigator/EPUB/EPUBSpreadView.swift` - Spread rendering with JS bridge

### Preferences
- `Sources/Navigator/Preferences/Preference.swift` - Individual preference handle
- `Sources/Navigator/Preferences/PreferencesEditor.swift` - Editor framework
- `Sources/Navigator/EPUB/Preferences/EPUBPreferences.swift` - EPUB settings
- `Sources/Navigator/EPUB/CSS/ReadiumCSS.swift` - CSS generation

### Abstractions
- `Sources/Shared/Toolkit/Data/Container/Container.swift` - Resource collection
- `Sources/Shared/Toolkit/Data/Resource/Resource.swift` - Content proxy
- `Sources/Shared/Toolkit/Data/Asset/Asset.swift` - Publication wrapper
- `Sources/Shared/Toolkit/HTTP/HTTPServer.swift` - Local server protocol

### Decorations
- `Sources/Navigator/Decorator/DecorableNavigator.swift` - Decoration API
- `Sources/Navigator/Decorator/DiffableDecoration.swift` - Decoration change tracking

### Services
- `Sources/Shared/Publication/Services/PublicationService.swift` - Service base protocol
- `Sources/Shared/Publication/Services/Positions/PositionsService.swift` - Pagination service
