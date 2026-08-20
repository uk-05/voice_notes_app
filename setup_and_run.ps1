# setup_and_run.ps1
#
# Run this from inside the voice_notes_app folder (the one that has
# pubspec.yaml in it). It will:
#   1. Clear any corrupted pub-cache copies of the desktop/web sqflite
#      packages (fixes "system cannot find the file specified" errors)
#   2. Generate fresh android/, ios/, windows/, and web/ native project
#      folders using YOUR installed Flutter SDK
#   3. Add the microphone + speech-recognition permissions Android needs
#   4. Set minSdkVersion to 21 (required by the speech_to_text package)
#   5. Disable Kotlin incremental compilation (avoids a Windows bug when
#      the project and pub-cache are on different drives)
#   6. Silence a Visual Studio 2022+/coroutine deprecation build error in
#      the Windows build (permission_handler_windows and similar plugins)
#   7. Fetch all dependencies
#   8. Copy the web-worker files sqflite needs to run in a browser
#   9. Run the app on whatever device you pick (Android/Windows/Chrome/Edge)
#
# Usage (PowerShell, from the project folder):
#   powershell -ExecutionPolicy Bypass -File setup_and_run.ps1

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: Run this script from inside the voice_notes_app folder (where pubspec.yaml is)." -ForegroundColor Red
    exit 1
}

Write-Step "Clearing any corrupted pub-cache copies of sqflite_common_ffi / sqflite_common_ffi_web"
$pubCacheHosted = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev"
if (Test-Path $pubCacheHosted) {
    Get-ChildItem $pubCacheHosted -Directory -Filter "sqflite_common_ffi*" -ErrorAction SilentlyContinue |
        ForEach-Object {
            Write-Host "Removing stale cache: $($_.FullName)"
            Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue
        }
}

Write-Step "Enabling Windows desktop + Web support in Flutter"
flutter config --enable-windows-desktop | Out-Null
flutter config --enable-web | Out-Null

Write-Step "Removing any old/partial android, ios, windows, web, and build folders"
Remove-Item -Recurse -Force "android" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "ios" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "windows" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "web" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue

Write-Step "Regenerating native project files for Android, iOS, Windows, and Web"
flutter create --platforms=android,ios,windows,web .
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: 'flutter create' failed. Is Flutter installed and on PATH?" -ForegroundColor Red
    exit 1
}

Write-Step "Adding microphone + speech-recognition permissions to AndroidManifest.xml"
$manifestPath = "android\app\src\main\AndroidManifest.xml"
$manifest = Get-Content $manifestPath -Raw

if ($manifest -notmatch "RECORD_AUDIO") {
    $permissionBlock = @"
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>
"@
    $manifest = $manifest -replace '(<manifest[^>]*>)', "`$1`n$permissionBlock"
    Set-Content -Path $manifestPath -Value $manifest -NoNewline
    Write-Host "Permissions added."
} else {
    Write-Host "Permissions already present, skipping."
}

Write-Step "Setting minSdkVersion to 21 (required by speech_to_text)"
$gradlePath = "android\app\build.gradle"
$gradleKtsPath = "android\app\build.gradle.kts"

if (Test-Path $gradlePath) {
    (Get-Content $gradlePath) `
        -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 21' `
        -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 21' |
        Set-Content $gradlePath
    Write-Host "Updated $gradlePath"
} elseif (Test-Path $gradleKtsPath) {
    (Get-Content $gradleKtsPath) `
        -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 21' |
        Set-Content $gradleKtsPath
    Write-Host "Updated $gradleKtsPath"
}

Write-Step "Disabling Kotlin incremental compilation (avoids a Windows bug when the project and pub-cache are on different drives)"
$gradlePropsPath = "android\gradle.properties"
if (Test-Path $gradlePropsPath) {
    $gradleProps = Get-Content $gradlePropsPath -Raw
    if ($gradleProps -notmatch "kotlin\.incremental") {
        Add-Content -Path $gradlePropsPath -Value "`nkotlin.incremental=false`n"
        Write-Host "Added kotlin.incremental=false to $gradlePropsPath"
    }
} else {
    Set-Content -Path $gradlePropsPath -Value "kotlin.incremental=false`n"
    Write-Host "Created $gradlePropsPath with kotlin.incremental=false"
}

Write-Step "Silencing the experimental-coroutine build error in the Windows build"
$winCMakePath = "windows\CMakeLists.txt"
if (Test-Path $winCMakePath) {
    $winCMake = Get-Content $winCMakePath -Raw
    if ($winCMake -notmatch "_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS") {
        $winCMake = $winCMake -replace `
            '(add_definitions\(-DUNICODE -D_UNICODE\))', `
            "`$1`nadd_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)"
        Set-Content -Path $winCMakePath -Value $winCMake -NoNewline
        Write-Host "Patched $winCMakePath"
    }
}

Write-Step "Fetching Flutter dependencies (flutter pub get)"
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: 'flutter pub get' failed. Check the errors above." -ForegroundColor Red
    exit 1
}

Write-Step "Copying required sqflite web-worker files into web/ (needed for the Chrome/Edge demo)"
dart run sqflite_common_ffi_web:setup

Write-Step "Cleaning any stale build artifacts"
flutter clean | Out-Null
flutter pub get | Out-Null

Write-Step "Listing available devices"
flutter devices

Write-Step "Launching the app — pick your target when prompted"
Write-Host "Android emulator/phone, Windows (desktop), or Chrome/Edge all work." -ForegroundColor Yellow
flutter run
