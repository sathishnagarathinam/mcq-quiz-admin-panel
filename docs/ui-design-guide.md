# MCQ Quiz System - UI Design Guide

This document outlines the design system and UI guidelines for the MCQ Quiz System, based on the provided mobile app mockups.

## Design Philosophy

The MCQ Quiz System follows a clean, modern, and user-friendly design approach that prioritizes:
- **Clarity**: Clear information hierarchy and easy-to-read content
- **Accessibility**: High contrast ratios and readable fonts
- **Consistency**: Uniform design patterns across all screens
- **Engagement**: Motivating and encouraging user experience

## Color Palette

### Primary Colors
- **Primary Purple**: `#6366F1` - Main brand color for buttons, highlights
- **Light Purple**: `#8B5CF6` - Secondary actions, gradients
- **Dark Purple**: `#4F46E5` - Hover states, emphasis

### Secondary Colors
- **Cyan**: `#06B6D4` - Success states, progress indicators
- **Green**: `#10B981` - Correct answers, achievements
- **Orange**: `#F59E0B` - Warnings, time alerts
- **Red**: `#EF4444` - Errors, wrong answers

### Neutral Colors
- **Background**: `#F8FAFC` - Main background
- **Surface**: `#FFFFFF` - Cards, modals
- **Text Primary**: `#1E293B` - Main text
- **Text Secondary**: `#64748B` - Supporting text
- **Border**: `#E2E8F0` - Dividers, borders

## Typography

### Font Family
- **Primary**: Poppins (Google Fonts)
- **Fallback**: System fonts (Roboto, SF Pro, Helvetica)

### Font Weights
- **Regular**: 400 - Body text
- **Medium**: 500 - Subheadings
- **SemiBold**: 600 - Headings
- **Bold**: 700 - Emphasis, titles

### Font Sizes
- **Display Large**: 32px - Main titles
- **Display Medium**: 28px - Section headers
- **Headline**: 24px - Page titles
- **Title Large**: 20px - Card titles
- **Title Medium**: 18px - Subtitles
- **Body Large**: 16px - Main content
- **Body Medium**: 14px - Secondary content
- **Caption**: 12px - Labels, hints

## Layout & Spacing

### Grid System
- **Mobile**: 16px margins, 16px gutters
- **Tablet**: 24px margins, 24px gutters
- **Desktop**: 32px margins, 32px gutters

### Spacing Scale
- **4px**: Micro spacing
- **8px**: Small spacing
- **12px**: Medium spacing
- **16px**: Standard spacing
- **24px**: Large spacing
- **32px**: Extra large spacing
- **48px**: Section spacing

### Border Radius
- **Small**: 8px - Buttons, chips
- **Medium**: 12px - Cards, inputs
- **Large**: 16px - Modals, sheets
- **Extra Large**: 24px - Hero sections

## Component Guidelines

### Buttons

#### Primary Button
```css
background: #6366F1
color: #FFFFFF
padding: 16px 24px
border-radius: 12px
font-weight: 600
```

#### Secondary Button
```css
background: transparent
color: #6366F1
border: 2px solid #6366F1
padding: 14px 22px
border-radius: 12px
font-weight: 600
```

#### Text Button
```css
background: transparent
color: #6366F1
padding: 12px 16px
font-weight: 600
```

### Cards

#### Standard Card
```css
background: #FFFFFF
border-radius: 12px
padding: 20px
box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1)
```

#### Quiz Question Card
```css
background: #FFFFFF
border-radius: 16px
padding: 24px
margin: 16px
box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05)
```

### Input Fields

#### Text Input
```css
background: #F8FAFC
border: 1px solid #E2E8F0
border-radius: 12px
padding: 16px
font-size: 16px
```

#### Focused State
```css
border-color: #6366F1
box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1)
```

### Navigation

#### Bottom Navigation
- Height: 80px
- Background: #FFFFFF
- Active color: #6366F1
- Inactive color: #64748B
- Icons: 24px

#### Tab Bar
- Height: 48px
- Background: #F8FAFC
- Active background: #6366F1
- Active text: #FFFFFF
- Inactive text: #64748B

## Screen-Specific Guidelines

### Onboarding Screens
- **Background**: Gradient or solid color per screen
- **Illustrations**: Centered, 200px height
- **Title**: 28px, bold, centered
- **Subtitle**: 16px, regular, centered, max 2 lines
- **Button**: Full width, 16px margin

### Login Screen
- **Logo**: 80x80px, centered
- **Title**: 28px, bold
- **Input fields**: Full width, 16px spacing
- **Button**: Full width, primary style
- **Links**: 14px, medium weight

### Dashboard
- **Header**: User greeting, profile image
- **Categories**: Grid layout, 2 columns on mobile
- **Banners**: Full width, 16:9 aspect ratio
- **Quick stats**: Horizontal scroll cards

### Quiz Interface
- **Progress bar**: Top of screen, 4px height
- **Question number**: Top right corner
- **Question text**: 18px, medium weight
- **Options**: Full width buttons, 16px spacing
- **Timer**: Circular progress, top center

### Results Screen
- **Score display**: Large, centered, colored
- **Progress ring**: 120px diameter
- **Analysis cards**: Vertical list
- **Action buttons**: Horizontal layout

## Icons

### Icon Style
- **Style**: Outlined (Material Design)
- **Size**: 24px standard, 20px small, 32px large
- **Color**: Inherit from parent or theme

### Common Icons
- Home: `home`
- Quiz: `quiz`
- Profile: `person`
- Settings: `settings`
- Bookmark: `bookmark`
- Timer: `timer`
- Check: `check_circle`
- Close: `close`
- Arrow: `arrow_forward`

## Animations

### Transitions
- **Duration**: 300ms standard
- **Easing**: Ease-out for entrances, ease-in for exits
- **Properties**: Transform, opacity, color

### Micro-interactions
- **Button press**: Scale down to 0.95
- **Card tap**: Slight elevation increase
- **Loading**: Shimmer effect
- **Success**: Bounce animation

## Accessibility

### Color Contrast
- **Normal text**: 4.5:1 minimum ratio
- **Large text**: 3:1 minimum ratio
- **Interactive elements**: 3:1 minimum ratio

### Touch Targets
- **Minimum size**: 44x44px
- **Recommended**: 48x48px
- **Spacing**: 8px minimum between targets

### Text Scaling
- Support up to 200% text scaling
- Maintain layout integrity
- Ensure readability at all sizes

## Dark Mode

### Color Adaptations
- **Background**: `#0F172A`
- **Surface**: `#1E293B`
- **Text Primary**: `#F1F5F9`
- **Text Secondary**: `#CBD5E1`
- **Border**: `#475569`

### Implementation
- Use semantic color tokens
- Test all components in both modes
- Maintain contrast ratios
- Preserve brand colors where appropriate

## Responsive Design

### Breakpoints
- **Mobile**: 0-767px
- **Tablet**: 768-1023px
- **Desktop**: 1024px+

### Layout Adaptations
- **Mobile**: Single column, full width
- **Tablet**: Two columns, increased margins
- **Desktop**: Multi-column, sidebar navigation

## Brand Guidelines

### Logo Usage
- Minimum size: 32px height
- Clear space: 16px on all sides
- Color variations: Full color, white, black

### Voice & Tone
- **Encouraging**: Positive reinforcement
- **Clear**: Simple, direct language
- **Supportive**: Helpful guidance
- **Professional**: Appropriate for exam prep

## Implementation Notes

### Flutter (Mobile)
- Use Material Design 3 components
- Implement custom theme with brand colors
- Use Google Fonts package for typography
- Follow Flutter design guidelines

### React (Web)
- Use Material-UI components
- Customize theme with brand colors
- Implement responsive breakpoints
- Follow web accessibility standards

### Assets
- Use SVG for icons when possible
- Optimize images for different screen densities
- Provide dark mode variants
- Include accessibility descriptions
