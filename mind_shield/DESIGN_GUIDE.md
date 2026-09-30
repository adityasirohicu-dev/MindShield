# MIND SHIELD — Design Guide

## 1. Visual System

The Mind Shield app uses a modern, supportive, and trustworthy visual design system optimized for a premium personal wellness experience. The goal is to avoid militaristic, clinical, or overly authoritative elements (such as harsh borders, zero radius corners, pure black shadows, or ALL CAPS typography) while maintaining clear visual hierarchy.

### Core Philosophy
- **Supportive & Optimistic:** Bright backgrounds, pastel gradients, and soft color palettes.
- **Trustworthy:** Consistent component styling and readable typography. 
- **Modern & Approachable:** Generous spacing, softly rounded elements (`BorderRadius.circular(16)` or `24`), subtle shadows (`Color(0x11000000)`), and no harsh borders.

## 2. Shared Components & Theme

The presentation styles are centralized in `lib/theme/` to ensure a consistent experience across all screens.

### Design Tokens
- **Theme (`app_theme.dart`):** Central Material 3 theme applying the foundational `ColorScheme`, `TextTheme`, and component themes.
- **Colors (`colors.dart`):** Defines the core semantic palette.
  - *Primary:* Soft, welcoming blues (`Color(0xFF3B82F6)`).
  - *Backgrounds:* Bright, slightly tinted surfaces to create depth without relying heavily on shadows.
- **Typography (`typography.dart`):** Standard, legible Title Case phrasing replacing the aggressive "TACTICAL" uppercase labels.
- **Radii (`design_tokens.dart`):** Soft curves (`AppRadii.control`, `AppRadii.panel`, `AppRadii.card`) are standardized here to eliminate the previously brutalist "zero border-radius" approach.

### Key Widgets (`lib/widgets/`)
Reusable UI components that embody the wellness aesthetic:
- **`PrimaryButton`:** The main call-to-action button, ensuring comfortable touch targets and rounded corners.
- **`GlassCard`:** A softly elevated, rounded container used for grouping related data or insights.
- **`StatusChip`:** A rounded indicator for statuses or tags.
- **`TrendChart` & `RadialGauge`:** Data visualization tools rendered with pleasing palettes to communicate metrics clearly without alarming the user.

## 3. How to Change the Design

To modify the visual style without hunting through widget trees:

1. **Colors & Gradients:** Edit `lib/theme/colors.dart` or `lib/theme/design_tokens.dart`. All screens pull their background colors, gradients, and semantic status colors from these files.
2. **Typography:** Update `lib/theme/typography.dart` to change font families or text sizes globally.
3. **Spacing & Radii:** Adjust values in `lib/theme/design_tokens.dart` (e.g., `AppSpacing.md`, `AppRadii.card`).
4. **Core Widgets:** If a major visual element needs a structural change across the app, edit the respective widget in `lib/widgets/` (like `primary_button.dart` or `glass_card.dart`).

*Note: Changes made in the theme files will instantly propagate to the `Login`, `Home`, `Analytics`, `Check-in`, `Support`, and `Dashboard` screens since they strictly use shared tokens.*
