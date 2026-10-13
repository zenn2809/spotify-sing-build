# AutoMix iOS Sample

An iOS 17+ SwiftUI demonstration app for `SGAutoMixCore`. It uses the phone's
own audio engine and two user-selected local audio files; it does not access or
modify Spotify, `spotifyglass.dylib`, or any third-party playback process.

## Run on an iPhone 14 Pro

1. Clone this repository on a Mac with Xcode 16 or later.
2. Open `AutoMixSample.xcodeproj`.
3. Select your signing team and a unique bundle identifier in the target's
   Signing & Capabilities settings.
4. Choose the connected iPhone 14 Pro and press Run.
5. In the app, choose two local audio files with the same sample rate, then
   tap **Start AutoMix**.

The sample begins the second file six seconds before the first file ends and
uses `SGAutoMixCore` to apply an equal-power transition. It is intentionally a
reference integration, not a Spotify AutoMix tweak.
