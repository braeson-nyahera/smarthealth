# SmartHealth Logo Setup Instructions

## Step 1: Save the Logo Image
1. Save the SmartHealth logo image as `smarthealth_logo.png` in the `assets/icons/` directory
2. The image should be at least 1024x1024 pixels for best results across all platforms
3. Make sure it's a PNG file with transparent background if desired

## Step 2: Generate Launcher Icons
After placing the image, run the following commands:

```bash
flutter pub get
flutter packages pub run flutter_launcher_icons
```

## Step 3: Verify Installation
The launcher icons will be automatically generated for:
- Android (various densities)
- iOS 
- Web
- Windows
- macOS

## Current Configuration
The pubspec.yaml has been configured to:
- Use `assets/icons/smarthealth_logo.png` as the source image
- Generate icons for all platforms
- Set minimum Android SDK to 21
- Enable web and desktop icon generation

## Next Steps
1. Place your SmartHealth logo in `assets/icons/smarthealth_logo.png`
2. Run the generation commands above
3. Test the app to see the new launcher icon