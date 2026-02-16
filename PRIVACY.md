# Privacy Policy

**DiskCleaner: Smart Cleanup**
Last updated: February 16, 2026

## Overview

DiskCleaner is a macOS utility that analyzes disk usage on your Mac. Your privacy is important to us. This policy explains how DiskCleaner handles your data.

## Data Collection

DiskCleaner does **not** collect, store, or transmit any personal data. Specifically:

- **No analytics or tracking** — the app contains no analytics frameworks or tracking code.
- **No network requests** — the app operates entirely offline and never connects to the internet.
- **No data sharing** — no data is sent to us, third parties, or any external servers.

## Local Data

All data stays on your device:

- **Scan results** are held in memory during the app session and are not persisted to disk.
- **User preferences** (auto-scan settings, exclusion rules, trash history) are stored locally using macOS UserDefaults within the app's sandbox container.
- **Folder bookmarks** are stored locally to remember which folders you have granted access to.

## File Access

DiskCleaner requires access to folders on your Mac to analyze disk usage. This access is granted explicitly by you through the macOS file picker (NSOpenPanel) and is governed by the App Sandbox. The app can only access folders you have selected.

## Deletion

Files you choose to delete are moved to the macOS Trash, not permanently deleted. You can restore them from Trash at any time using Finder or the app's Trash History feature.

## Changes to This Policy

If this policy is updated, the revised version will be posted here with an updated date.

## Contact

If you have questions about this privacy policy, please open an issue at:
https://github.com/ljack/macos-disk-cleaner/issues
