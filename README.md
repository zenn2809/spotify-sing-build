# Spotify Sing model build

This repository rebuilds the legitimate MIT-licensed Mel-Band RoFormer spectral Core ML separator
used by the Spotify 9.1.78 Sing implementation. It intentionally contains no Spotify IPA, no
prebuilt model weights, and no workaround for model validation.

## What the workflow builds

The manual **Build Sing Core ML model** workflow checks out the pinned conversion/reference source,
downloads the pinned MIT checkpoint and test goldens, verifies their SHA-256 values, compiles
`separator.mlmodelc` for iOS 18, and stages the five files required by the app for upload to:

`https://huggingface.co/ralphguu/spotify-sing-model`

It uploads `sing-model-host-files` as a GitHub Actions artifact. Download it, unpack it, and upload
its *contents* to the Hugging Face model repository. The generated manifest is emitted by
`stage_model.py`; its hashes must be copied into the downloader only after the export and native
model checks succeed.

The runtime contract is fixed by the existing implementation: `spectrum` float32
`[1, 2050, 201, 2]` in and `vocals_spectrum` of that same shape out. This build does not claim that
the resulting model has been device validated; physical iPhone validation is still required.

## Important

This is a model build only. Rebuilding a patched IPA also requires the complete compatible tweak
source, the decrypted Spotify 9.1.78 IPA, a signing certificate/provisioning profile, and device
testing. None of those are published here.
