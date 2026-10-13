# SGAutoMix.dylib

This directory builds the original `SGAutoMixCore` as an **arm64 iOS 17+
dynamic library**. The GitHub Actions workflow produces a downloadable,
unsigned `SGAutoMix.dylib` artifact.

The library exports the C planner API in `SGAutoMixCore.h` plus
`SGAutoMixVersion()`. It contains no Spotify code, no private Spotify hooks,
and no entitlement or authentication bypass.

## Important installation limitation

An unsigned dylib cannot be installed directly on a stock iPhone. It must be
embedded in an iOS app that you build and sign with an Apple development or
distribution certificate. It is not a drop-in replacement for
`spotifyglass.dylib`, and it will not enable AutoMix inside Spotify.

## Obtain the build without a Mac

1. Open the **Build SGAutoMix dylib** GitHub Actions run in this repository.
2. Wait for the arm64 verification job to pass.
3. Download the `SGAutoMix-iOS-arm64` artifact.

The artifact is built with the iPhoneOS SDK and checked with `lipo` to ensure
that it contains only the required arm64 device slice.
