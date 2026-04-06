# DeskRu macOS Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a rebranded macOS RustDesk client named "DeskRu" with hardcoded server settings and automated GitHub Actions build.

**Architecture:** Fork of rustdesk/rustdesk with source-level modifications. Server settings and app name are hardcoded in the `hbb_common` submodule config. macOS bundle metadata updated in Flutter project files. GitHub Actions workflow adapted from existing `flutter-nightly.yml` to build only macOS with `workflow_dispatch` trigger.

**Tech Stack:** Rust, Flutter 3.24.5, GitHub Actions, create-dmg

---

## File Map

| Action | File | Purpose |
|--------|------|---------|
| Modify | `libs/hbb_common/src/config.rs:96,109,111,159,160` | APP_NAME, ORG, PROD_RENDEZVOUS_SERVER, RENDEZVOUS_SERVERS, RS_PUB_KEY |
| Modify | `src/common.rs:1084` | API server fallback URL |
| Modify | `flutter/macos/Runner/Configs/AppInfo.xcconfig` | PRODUCT_NAME, PRODUCT_BUNDLE_IDENTIFIER, PRODUCT_COPYRIGHT |
| Modify | `flutter/macos/Runner/Info.plist:28-33` | URL scheme and URL identifier |
| Modify | `Cargo.toml:2,4,7,8,217-218,235-236` | Package name, description, Windows metadata, bundle ID |
| Create | `.github/workflows/deskru-macos-build.yml` | macOS-only build workflow with workflow_dispatch |
| Modify | `.github/workflows/flutter-build.yml:730` | DMG icon/app name references |

---

### Task 1: Hardcode Server Settings in hbb_common

**Files:**
- Modify: `libs/hbb_common/src/config.rs:96,109,111,159,160`

- [ ] **Step 1: Edit `libs/hbb_common/src/config.rs` - change ORG**

Line 96, change:
```rust
pub static ref ORG: RwLock<String> = RwLock::new("com.carriez".to_owned());
```
to:
```rust
pub static ref ORG: RwLock<String> = RwLock::new("ru.deskru".to_owned());
```

- [ ] **Step 2: Edit `libs/hbb_common/src/config.rs` - change PROD_RENDEZVOUS_SERVER**

Line 109, change:
```rust
pub static ref PROD_RENDEZVOUS_SERVER: RwLock<String> = RwLock::new("".to_owned());
```
to:
```rust
pub static ref PROD_RENDEZVOUS_SERVER: RwLock<String> = RwLock::new("deskru.ru".to_owned());
```

- [ ] **Step 3: Edit `libs/hbb_common/src/config.rs` - change APP_NAME**

Line 111, change:
```rust
pub static ref APP_NAME: RwLock<String> = RwLock::new("RustDesk".to_owned());
```
to:
```rust
pub static ref APP_NAME: RwLock<String> = RwLock::new("DeskRu".to_owned());
```

- [ ] **Step 4: Edit `libs/hbb_common/src/config.rs` - change RENDEZVOUS_SERVERS and RS_PUB_KEY**

Lines 159-160, change:
```rust
pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];
pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";
```
to:
```rust
pub const RENDEZVOUS_SERVERS: &[&str] = &["deskru.ru"];
pub const RS_PUB_KEY: &str = "IIHJ75Hqj8IEjQvQ/eNOnEZb2+D3MjGKL4GIJLdooBU=";
```

- [ ] **Step 5: Commit**

```bash
git add libs/hbb_common/src/config.rs
git commit -m "feat: hardcode DeskRu server settings in hbb_common config"
```

---

### Task 2: Change API Server Fallback

**Files:**
- Modify: `src/common.rs:1084`

- [ ] **Step 1: Edit `src/common.rs` - change API fallback**

Line 1084, change:
```rust
    "https://admin.rustdesk.com".to_owned()
```
to:
```rust
    "https://api.deskru.ru".to_owned()
```

- [ ] **Step 2: Commit**

```bash
git add src/common.rs
git commit -m "feat: change API server fallback to api.deskru.ru"
```

---

### Task 3: Update Cargo.toml Package Metadata

**Files:**
- Modify: `Cargo.toml:2,4,7,8,217-218,235-236`

- [ ] **Step 1: Edit `Cargo.toml` - package section (lines 2-8)**

Change:
```toml
name = "rustdesk"
version = "1.4.6"
authors = ["rustdesk <info@rustdesk.com>"]
edition = "2021"
build= "build.rs"
description = "RustDesk Remote Desktop"
default-run = "rustdesk"
```
to:
```toml
name = "rustdesk"
version = "1.4.6"
authors = ["DeskRu <info@deskru.ru>"]
edition = "2021"
build= "build.rs"
description = "DeskRu Remote Desktop"
default-run = "rustdesk"
```

Note: Keep `name = "rustdesk"` and `default-run = "rustdesk"` unchanged - these are Rust crate/binary names used throughout the build system. Changing them would break compilation.

- [ ] **Step 2: Edit `Cargo.toml` - Windows metadata (lines 217-218)**

Change:
```toml
ProductName = "RustDesk"
FileDescription = "RustDesk Remote Desktop"
```
to:
```toml
ProductName = "DeskRu"
FileDescription = "DeskRu Remote Desktop"
```

- [ ] **Step 3: Edit `Cargo.toml` - bundle metadata (lines 235-236)**

Change:
```toml
name = "RustDesk"
identifier = "com.carriez.rustdesk"
```
to:
```toml
name = "DeskRu"
identifier = "ru.deskru.client"
```

- [ ] **Step 4: Commit**

```bash
git add Cargo.toml
git commit -m "feat: update Cargo.toml metadata for DeskRu branding"
```

---

### Task 4: Update macOS Bundle Configuration

**Files:**
- Modify: `flutter/macos/Runner/Configs/AppInfo.xcconfig`
- Modify: `flutter/macos/Runner/Info.plist:28-33`

- [ ] **Step 1: Edit `AppInfo.xcconfig`**

Change the entire file content to:
```
// Application-level settings for the Runner target.
//
// This may be replaced with something auto-generated from metadata (e.g., pubspec.yaml) in the
// future. If not, the values below would default to using the project name when this becomes a
// 'flutter create' template.

// The application's name. By default this is also the title of the Flutter window.
PRODUCT_NAME = DeskRu

// The application's bundle identifier
PRODUCT_BUNDLE_IDENTIFIER = ru.deskru.client

// The copyright displayed in application information
PRODUCT_COPYRIGHT = DeskRu - Client based on RustDesk (AGPL-3.0)
```

- [ ] **Step 2: Edit `Info.plist` - URL scheme (lines 28-33)**

Change:
```xml
			<key>CFBundleURLName</key>
			<string>com.carriez.rustdesk</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>rustdesk</string>
			</array>
```
to:
```xml
			<key>CFBundleURLName</key>
			<string>ru.deskru.client</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>deskru</string>
			</array>
```

- [ ] **Step 3: Commit**

```bash
git add flutter/macos/Runner/Configs/AppInfo.xcconfig flutter/macos/Runner/Info.plist
git commit -m "feat: update macOS bundle config for DeskRu branding"
```

---

### Task 5: Update DMG References in flutter-build.yml

**Files:**
- Modify: `.github/workflows/flutter-build.yml:730`

- [ ] **Step 1: Edit `flutter-build.yml` - unsigned DMG creation (line 730)**

Change:
```yaml
          create-dmg --icon "RustDesk.app" 200 190 --hide-extension "RustDesk.app" --window-size 800 400 --app-drop-link 600 185 rustdesk-${{ env.VERSION }}-${{ matrix.job.arch }}.dmg ./flutter/build/macos/Build/Products/Release/RustDesk.app
```
to:
```yaml
          create-dmg --icon "DeskRu.app" 200 190 --hide-extension "DeskRu.app" --window-size 800 400 --app-drop-link 600 185 deskru-${{ env.VERSION }}-${{ matrix.job.arch }}.dmg ./flutter/build/macos/Build/Products/Release/DeskRu.app
```

- [ ] **Step 2: Edit `flutter-build.yml` - artifact upload name (lines 736-737)**

Change:
```yaml
          name: rustdesk-unsigned-macos-${{ matrix.job.arch }}
          path: rustdesk-${{ env.VERSION }}-${{ matrix.job.arch }}.dmg
```
to:
```yaml
          name: deskru-unsigned-macos-${{ matrix.job.arch }}
          path: deskru-${{ env.VERSION }}-${{ matrix.job.arch }}.dmg
```

- [ ] **Step 3: Edit `flutter-build.yml` - signed DMG (lines 751-752)**

Change:
```yaml
          codesign --force --options runtime -s ${{ secrets.MACOS_CODESIGN_IDENTITY }} --deep --strict ./flutter/build/macos/Build/Products/Release/RustDesk.app -vvv
          create-dmg --icon "RustDesk.app" 200 190 --hide-extension "RustDesk.app" --window-size 800 400 --app-drop-link 600 185 rustdesk-${{ env.VERSION }}.dmg ./flutter/build/macos/Build/Products/Release/RustDesk.app
```
to:
```yaml
          codesign --force --options runtime -s ${{ secrets.MACOS_CODESIGN_IDENTITY }} --deep --strict ./flutter/build/macos/Build/Products/Release/DeskRu.app -vvv
          create-dmg --icon "DeskRu.app" 200 190 --hide-extension "DeskRu.app" --window-size 800 400 --app-drop-link 600 185 deskru-${{ env.VERSION }}.dmg ./flutter/build/macos/Build/Products/Release/DeskRu.app
```

- [ ] **Step 4: Edit `flutter-build.yml` - codesign and notarize (lines 753-755)**

Change:
```yaml
          codesign --force --options runtime -s ${{ secrets.MACOS_CODESIGN_IDENTITY }} --deep --strict rustdesk-${{ env.VERSION }}.dmg -vvv
          # notarize the rustdesk-${{ env.VERSION }}.dmg
          rcodesign notary-submit --api-key-path ${{ github.workspace }}/rustdesk.json  --staple rustdesk-${{ env.VERSION }}.dmg
```
to:
```yaml
          codesign --force --options runtime -s ${{ secrets.MACOS_CODESIGN_IDENTITY }} --deep --strict deskru-${{ env.VERSION }}.dmg -vvv
          # notarize the deskru-${{ env.VERSION }}.dmg
          rcodesign notary-submit --api-key-path ${{ github.workspace }}/rustdesk.json  --staple deskru-${{ env.VERSION }}.dmg
```

- [ ] **Step 5: Edit `flutter-build.yml` - rename and publish (lines 760-771)**

Change:
```yaml
          for name in rustdesk*??.dmg; do
              mv "$name" "${name%%.dmg}-${{ matrix.job.arch }}.dmg"
          done
```
to:
```yaml
          for name in deskru*??.dmg; do
              mv "$name" "${name%%.dmg}-${{ matrix.job.arch }}.dmg"
          done
```

And in publish step change:
```yaml
          files: |
            rustdesk*-${{ matrix.job.arch }}.dmg
```
to:
```yaml
          files: |
            deskru*-${{ matrix.job.arch }}.dmg
```

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/flutter-build.yml
git commit -m "feat: rename DMG artifacts from rustdesk to deskru"
```

---

### Task 6: Create macOS-only Build Workflow

**Files:**
- Create: `.github/workflows/deskru-macos-build.yml`

- [ ] **Step 1: Create the workflow file**

Create `.github/workflows/deskru-macos-build.yml`:

```yaml
name: Build DeskRu macOS Client

on:
  workflow_dispatch:
    inputs:
      upload-artifact:
        type: boolean
        default: true
        description: "Upload build artifacts"

jobs:
  build:
    uses: ./.github/workflows/flutter-build.yml
    secrets: inherit
    with:
      upload-artifact: ${{ inputs.upload-artifact }}
      upload-tag: "deskru-macos"
```

Note: This workflow reuses `flutter-build.yml` which builds ALL platforms. The macOS job (`build-for-macOS`) will run and produce DeskRu DMGs. Windows/Linux jobs will also run but that's fine - they use the same rebranded config. In a future iteration we can create a macOS-only extraction of the build workflow.

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/deskru-macos-build.yml
git commit -m "feat: add DeskRu macOS build workflow with manual trigger"
```

---

### Task 7: Update build.py DMG References

**Files:**
- Modify: `build.py:411,414,417,418`

- [ ] **Step 1: Edit `build.py` - macOS DMG function (lines 411-418)**

Change in `build_flutter_dmg()`:
```python
    system2(
        "cp target/release/liblibrustdesk.dylib target/release/librustdesk.dylib")
```
Keep this line unchanged (it's a Rust library name tied to `Cargo.toml` crate name).

Change line 414:
```python
    system2('cp -rf ../target/release/service ./build/macos/Build/Products/Release/RustDesk.app/Contents/MacOS/')
```
to:
```python
    system2('cp -rf ../target/release/service ./build/macos/Build/Products/Release/DeskRu.app/Contents/MacOS/')
```

Change line 417:
```python
    system2(
        "create-dmg --volname \"RustDesk Installer\" --window-pos 200 120 --window-size 800 400 --icon-size 100 --app-drop-link 600 185 --icon RustDesk.app 200 190 --hide-extension RustDesk.app rustdesk.dmg ./build/macos/Build/Products/Release/RustDesk.app")
```
to:
```python
    system2(
        "create-dmg --volname \"DeskRu Installer\" --window-pos 200 120 --window-size 800 400 --icon-size 100 --app-drop-link 600 185 --icon DeskRu.app 200 190 --hide-extension DeskRu.app deskru.dmg ./build/macos/Build/Products/Release/DeskRu.app")
```

Change line 418:
```python
    os.rename("rustdesk.dmg", f"../rustdesk-{version}.dmg")
```
to:
```python
    os.rename("deskru.dmg", f"../deskru-{version}.dmg")
```

- [ ] **Step 2: Commit**

```bash
git add build.py
git commit -m "feat: update build.py DMG references for DeskRu"
```

---

### Task 8: Push and Trigger Build

- [ ] **Step 1: Push all changes to GitHub**

```bash
git push origin master
```

- [ ] **Step 2: Trigger the macOS build workflow**

```bash
gh workflow run "Build DeskRu macOS Client" --ref master -f upload-artifact=true
```

- [ ] **Step 3: Monitor the build**

```bash
gh run list --workflow="Build DeskRu macOS Client" --limit 1
```

Wait for the build to complete. Check logs if it fails:
```bash
gh run view <run-id> --log-failed
```

- [ ] **Step 4: Download artifacts**

```bash
gh run download <run-id> -n deskru-unsigned-macos-aarch64
gh run download <run-id> -n deskru-unsigned-macos-x86_64
```

Expected artifacts:
- `deskru-1.4.6-aarch64.dmg`
- `deskru-1.4.6-x86_64.dmg`
