# FRAME / STYLE Native (SwiftUI)

This folder contains the first native iOS/iPadOS implementation source for FRAME / STYLE.

## Create the Xcode app target

1. Open Xcode on a Mac and choose **File → New → Project → iOS → App**.
2. Product name: `FRAMEStyle`; Interface: **SwiftUI**; Language: **Swift**.
3. Set the deployment target to iOS 17 or later.
4. Add the Swift files in this folder to the app target (or replace the generated app and content view files).
5. In the app target's Info settings, add **Privacy - Photo Library Usage Description** (`NSPhotoLibraryUsageDescription`) with the value: `FRAME / STYLE finds or creates the FRAMESTYLE album and saves edited photos when you ask it to.`
6. Run on an iPhone or iPad simulator/device.

## Included in this first native foundation

- Adaptive iPhone and iPad layouts using size class and available geometry.
- iPhone compact editor with bottom navigation and touch-friendly controls.
- iPad workspace with a tool sidebar and central preview; original and edited previews side-by-side after processing.
- Local photo selection through PhotosPicker.
- On-device Core Image filters for the seven FRAME / STYLE looks.
- Two separate modes: **LOCAL** for on-device Core Image editing and **AI STUDIO** for user-initiated sharing to ChatGPT and importing the returned image.
- Explicit save action into the dedicated **FRAMESTYLE** album in the Photos library. The app creates the album if it does not exist and reuses it for later exports.

LOCAL photo selection, rendering and saving are performed on-device. In AI STUDIO, the user explicitly shares the selected image through the iOS share sheet; ChatGPT is a separate app and the edited result must be imported back manually. FRAME / STYLE does not access the user's ChatGPT session or run ChatGPT in the background.

## Current status

Native source foundation: **0.4.0**. This is source code ready to add to an Xcode app target, not yet a signed, installable IPA or App Store build. Building, signing and device installation require Xcode on a Mac and the appropriate Apple developer setup.
