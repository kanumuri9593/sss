# App Theme Guide

## Color Scheme Overview

This document outlines the complete color theme for the SSS (Search & Scan) app.

### Primary Colors - Deep Blue
**Purpose**: Main brand color, primary actions, navigation

- **Primary Blue**: `#2563EB` - Main brand color
- **Primary Blue Dark**: `#1E40AF` - Darker variant for gradients
- **Primary Blue Light**: `#3B82F6` - Lighter variant for highlights

**Usage**: Buttons, app bars, primary CTAs, links

### Secondary Colors - Teal
**Purpose**: Secondary actions, accents, modern feel

- **Secondary Teal**: `#14B8A6` - Secondary brand color
- **Secondary Teal Dark**: `#0D9488` - Darker variant
- **Secondary Teal Light**: `#5EEAD4` - Lighter variant

**Usage**: Secondary buttons, badges, icons, gradient ends

### Accent Colors - Amber/Gold
**Purpose**: Highlights, star icon, important indicators

- **Accent Amber**: `#F59E0B` - Main accent color
- **Accent Amber Light**: `#FCD34D` - Lighter variant
- **Accent Gold**: `#D97706` - For star icon

**Usage**: Star in icon, highlights, warnings, important badges

## Icon Color Recommendations

For your house search icon:

### Option 1: Blue-to-Teal Gradient (Recommended)
- **House & Magnifying Glass**: Gradient from `#2563EB` (Primary Blue) to `#14B8A6` (Secondary Teal)
- **Star**: `#F59E0B` (Accent Amber) or `#FCD34D` (Accent Amber Light)

### Option 2: Blue Gradient
- **House & Magnifying Glass**: Gradient from `#2563EB` (Primary Blue) to `#1E40AF` (Primary Blue Dark)
- **Star**: `#F59E0B` (Accent Amber)

### Option 3: Teal Gradient
- **House & Magnifying Glass**: Gradient from `#14B8A6` (Secondary Teal) to `#0D9488` (Secondary Teal Dark)
- **Star**: `#F59E0B` (Accent Amber)

## Theme Features

### Light Theme
- **Background**: `#F8FAFC` - Light gray background
- **Surface**: `#FFFFFF` - White cards and surfaces
- **Text Primary**: `#1E293B` - Dark text
- **Text Secondary**: `#64748B` - Secondary text

### Dark Theme
- **Background**: `#0F172A` - Dark background
- **Surface**: `#1E293B` - Dark cards and surfaces
- **Text Primary**: `#FFFFFF` - Light text
- **Text Secondary**: `#CBD5E1` - Secondary text

## Status Colors

- **Success**: `#10B981` - Green for success states
- **Error**: `#EF4444` - Red for errors
- **Warning**: `#F59E0B` - Amber for warnings
- **Info**: `#3B82F6` - Blue for informational messages

## Usage in Code

```dart
import 'package:your_app/theme/app_theme.dart';

// Access colors
AppTheme.primaryBlue
AppTheme.secondaryTeal
AppTheme.accentAmber

// Access theme
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.secondary
Theme.of(context).colorScheme.tertiary
```

## Design Principles

1. **Professional**: Deep blue conveys trust and professionalism
2. **Modern**: Teal adds a fresh, contemporary feel
3. **Accessible**: High contrast ratios for readability
4. **Consistent**: All UI elements follow the same color scheme
5. **Scalable**: Works well at all sizes (16px to 512px icons)

## Platform-Specific Colors

### Web Manifest
- **Theme Color**: `#2563EB` (Primary Blue)
- **Background Color**: `#2563EB` (Primary Blue)

### iOS/Android
- Use the same primary blue (`#2563EB`) for app icons and splash screens
- Ensure icon star color (`#F59E0B`) has sufficient contrast

