# Session 13: Signing and Notarization
**Date:** 2026-02-15 22:04 UTC
**Conversation:** `898325d7-49e2-4c53-95d8-1ee869fe4b14`

## Commits
- `12324ac` Add code signing and notarization to release pipeline (5 files changed)
- `e4879d5` Fix workflow: use job-level env for secrets conditionals (1 file changed)
- `a61b62f` Fix base64 decode in import_certificate.sh for macOS runners (1 file changed)
- `5505ecc` Debug certificate import: add file size/header logging and -f pkcs12 (1 file changed)
- `aa1c46b` Remove debug logging from import_certificate.sh (1 file changed)
- `09889de` Update README download link to v0.9.1 and add releases page link (1 file changed)
- `fdf8d6e` Update README screenshot with current scanning view (1 file changed)

## Prompts

### Prompt 1
> Implement the following plan:
>
> # Plan: Publish DiskCleaner to the Mac App Store (+ Notarized DMG)
>
> [Full plan: Phase 0 Apple Developer enrollment, Phase 1 signed+notarized DMG with CI scripts (import_certificate.sh, notarize.sh), Phase 2 Mac App Store with sandbox adaptation and security-scoped bookmarks]

### Prompt 2
> i've enrolled and success to apple developer program. Can you create the certificates etc from cli xcodebuild?

### Prompt 3
> option A

### Prompt 4
> ok, this is done

### Prompt 5
> ok, it's there

### Prompt 6
> ok, all done

### Prompt 7
> i can paste everything here:
> APPLE_ID=jarkko.lietolahti@gmail.com
> APPLE_APP_PASSWORD=[REDACTED]

### Prompt 8
> yes please. i've revoked the old password and updated new to github secrets.

### Prompt 9
> yes

### Prompt 10
> ok, it's done

### Prompt 11
> ok, it's done

### Prompt 12
> the password is:
> [REDACTED]

### Prompt 13
> ok, update the README to point to releases url and also point the current version there too

### Prompt 14
> get image from clipboard and use that as a reference screenshot in readme

### Prompt 15
> ok, now store all prompts used in the development of this app into prompts-directory. Assosiate each prompt with relevant code changes, git commits near the prompt etc.
