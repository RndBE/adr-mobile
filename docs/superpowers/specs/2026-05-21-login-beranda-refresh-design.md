# Login Beranda Refresh Design

## Scope

Refresh the mobile frontend for the login and beranda screens only. Backend calls, routing, authentication behavior, and repository behavior stay unchanged.

## Design

Login should feel compact and focused on small mobile screens. The illustration remains as a brand signal, but it should not push the form too far down. The form card gets clearer hierarchy, a stronger submit button, concise copy, and a calmer footer for partner logos and app version.

Beranda should read as an operational dashboard. The header keeps user identity, date, and logout, while the main content emphasizes current RTS status first. Sensor values should appear as consistent metric cards. Feature navigation should be a clean, tappable grid with stable spacing.

## Components

Create small shared widgets for repeated mobile dashboard UI:

- `AppSurfaceCard`: white card with the existing app shadow, radius, and padding.
- `StatusPill`: compact status indicator with icon/dot, label, and semantic color.
- `MetricTile`: compact metric card for sensor values and units.
- `EmptyPanel`: calm empty state for unavailable RTS data.

## Testing

Add a focused widget test for the new shared dashboard component so future UI changes have at least one stable behavior check. Run `flutter analyze` and `flutter test` after implementation.
