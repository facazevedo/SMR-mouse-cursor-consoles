# Test-build preview

File: `Images/test-not-ready.png`. Generated with the built-in image-generation
tool on 2026-09-27. Visually checked: the exact text is "TEST. NOT READY." in
two white uppercase lines on a dark background. PNG size: 421,009 bytes, below
the Paradox uploader's 2 MB thumbnail limit.

Final prompt:

> Create a square, high-contrast placeholder preview image for a game mod test build. Use a clean, solid dark background and very large bold white uppercase sans-serif lettering centered in two lines. The exact text must be "TEST." on the first line and "NOT READY." on the second line, with both periods included. Generous safe margins, perfectly legible at thumbnail size. Flat graphic design. No additional words, logos, pictures, gradients, or decoration.

The image is referenced by `metadata.lua` and included in local deployment.
Runtime code, debug flags and load order are unchanged; canonical version remains
2 because this changes publishing artwork only. Protected/game files were not
modified. No new game session or runtime log review was needed for this asset.
The missing short description and final publishing-package check remain separate
publishing tasks; this image does not certify console compatibility.
