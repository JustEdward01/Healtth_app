@echo off
REM ====================================================================
REM VERIFY_HEALTHAPP_ALLERGEN.bat - Verificare HealthApp Allergen Detection
REM ====================================================================

echo.
echo 🔍 HEALTHAPP ALLERGEN DETECTION - VERIFICATION
echo ===============================================
echo.

set PROJECT_ROOT=E:\Projects\HealthApp\healthapp
set ALL_GOOD=true

REM Verifică că suntem în directorul corect
if not exist "%PROJECT_ROOT%\lib" (
    echo ❌ ERROR: HealthApp not found at %PROJECT_ROOT%
    pause
    exit /b 1
)

cd /d "%PROJECT_ROOT%"
echo 📁 Working Directory: %CD%
echo.

REM ====================================================================
REM 1. VERIFICĂ FIȘIERELE ESENȚIALE
REM ====================================================================
echo 📂 1. CHECKING ESSENTIAL FILES...
echo ─────────────────────────────────

if exist "lib\models\allergen\allergen_match.dart" (
    echo ✅ allergen_match.dart found
) else (
    echo ❌ MISSING: lib\models\allergen\allergen_match.dart
    set ALL_GOOD=false
)

if exist "lib\models\allergen\hybrid_detection_result.dart" (
    echo ✅ hybrid_detection_result.dart found
) else (
    echo ❌ MISSING: lib\models\allergen\hybrid_detection_result.dart
    set ALL_GOOD=false
)

if exist "lib\services\hybrid_detection_service.dart" (
    echo ✅ hybrid_detection_service.dart found
) else (
    echo ❌ MISSING: lib\services\hybrid_detection_service.dart
    set ALL_GOOD=false
)

if exist "pubspec.yaml" (
    echo ✅ pubspec.yaml found
) else (
    echo ❌ MISSING: pubspec.yaml
    set ALL_GOOD=false
)

echo.

REM ====================================================================
REM 2. VERIFICĂ CONȚINUTUL FIȘIERELOR
REM ====================================================================
echo 🧩 2. CHECKING FILE CONTENT...
echo ─────────────────────────────

REM Verifică AllergenMatch
if exist "lib\models\allergen\allergen_match.dart" (
    findstr /C:"class AllergenMatch" "lib\models\allergen\allergen_match.dart" >nul
    if errorlevel 1 (
        echo ❌ AllergenMatch class NOT found in allergen_match.dart
        set ALL_GOOD=false
    ) else (
        echo ✅ AllergenMatch class found
    )
    
    REM Verifică că nu este HybridDetectionResult în același fișier
    findstr /C:"class HybridDetectionResult" "lib\models\allergen\allergen_match.dart" >nul
    if not errorlevel 1 (
        echo ❌ CONFLICT: HybridDetectionResult found in allergen_match.dart
        echo    ^(should be only in hybrid_detection_result.dart^)
        set ALL_GOOD=false
    ) else (
        echo ✅ No conflicting classes in allergen_match.dart
    )
    
    REM Verifică parametrul method
    findstr /C:"required this.method" "lib\models\allergen\allergen_match.dart" >nul
    if errorlevel 1 (
        echo ❌ AllergenMatch missing 'method' parameter
        set ALL_GOOD=false
    ) else (
        echo ✅ AllergenMatch has 'method' parameter
    )
) else (
    echo ❌ Cannot check allergen_match.dart - file missing
)

REM Verifică HybridDetectionResult
if exist "lib\models\allergen\hybrid_detection_result.dart" (
    findstr /C:"class HybridDetectionResult" "lib\models\allergen\hybrid_detection_result.dart" >nul
    if errorlevel 1 (
        echo ❌ HybridDetectionResult class NOT found
        set ALL_GOOD=false
    ) else (
        echo ✅ HybridDetectionResult class found
    )
    
    findstr /C:"import 'allergen_match.dart'" "lib\models\allergen\hybrid_detection_result.dart" >nul
    if errorlevel 1 (
        echo ❌ Missing import for AllergenMatch
        set ALL_GOOD=false
    ) else (
        echo ✅ Imports AllergenMatch correctly
    )
    
    findstr /C:"required this.metadata" "lib\models\allergen\hybrid_detection_result.dart" >nul
    if errorlevel 1 (
        echo ❌ Missing 'metadata' parameter
        set ALL_GOOD=false
    ) else (
        echo ✅ Has 'metadata' parameter
    )
) else (
    echo ❌ Cannot check hybrid_detection_result.dart - file missing
)

REM Verifică Service
if exist "lib\services\hybrid_detection_service.dart" (
    findstr /C:"class HybridDetectionService" "lib\services\hybrid_detection_service.dart" >nul
    if errorlevel 1 (
        echo ❌ HybridDetectionService class NOT found
        set ALL_GOOD=false
    ) else (
        echo ✅ HybridDetectionService class found
    )
    
    findstr /C:"detectAllergens" "lib\services\hybrid_detection_service.dart" >nul
    if errorlevel 1 (
        echo ❌ detectAllergens method NOT found
        set ALL_GOOD=false
    ) else (
        echo ✅ detectAllergens method found
    )
    
    findstr /C:"localhost:5000" "lib\services\hybrid_detection_service.dart" >nul
    if errorlevel 1 (
        echo ⚠️  BERT API URL might not be configured
    ) else (
        echo ✅ BERT API URL configured (localhost:5000)
    )
) else (
    echo ❌ Cannot check hybrid_detection_service.dart - file missing
)

echo.

REM ====================================================================
REM 3. VERIFICĂ DEPENDENCIES ÎN PUBSPEC.YAML
REM ====================================================================
echo 📦 3. CHECKING FLUTTER DEPENDENCIES...
echo ─────────────────────────────────────

if exist "pubspec.yaml" (
    findstr /C:"http:" "pubspec.yaml" >nul
    if errorlevel 1 (
        echo ❌ MISSING: http dependency
        set ALL_GOOD=false
    ) else (
        echo ✅ http dependency found
    )
    
    findstr /C:"provider:" "pubspec.yaml" >nul
    if errorlevel 1 (
        echo ❌ MISSING: provider dependency
        set ALL_GOOD=false
    ) else (
        echo ✅ provider dependency found
    )
    
    REM Optional dependencies
    findstr /C:"camera:" "pubspec.yaml" >nul
    if errorlevel 1 (
        echo ⚠️  OPTIONAL: camera dependency missing
    ) else (
        echo ✅ camera dependency found (optional)
    )
    
    findstr /C:"google_mlkit_text_recognition:" "pubspec.yaml" >nul
    if errorlevel 1 (
        echo ⚠️  OPTIONAL: google_mlkit_text_recognition missing
    ) else (
        echo ✅ google_mlkit_text_recognition found (optional)
    )
) else (
    echo ❌ Cannot check dependencies - pubspec.yaml missing
)

echo.

REM ====================================================================
REM 4. VERIFICĂ PYTHON PENTRU BERT SERVER
REM ====================================================================
echo 🐍 4. CHECKING PYTHON ENVIRONMENT...
echo ───────────────────────────────────

python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found in PATH
    echo    Download from: https://python.org/downloads/
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do echo ✅ Python found: %%i
)

pip --version >nul 2>&1
if errorlevel 1 (
    echo ❌ pip not found in PATH
) else (
    echo ✅ pip found
)

echo.

REM ====================================================================
REM 5. VERIFICĂ FLUTTER
REM ====================================================================
echo 📱 5. CHECKING FLUTTER...
echo ───────────────────────

flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter not found in PATH
    echo    Download from: https://flutter.dev/docs/get-started/install
) else (
    echo ✅ Flutter found
)

echo.

REM ====================================================================
REM 6. CREEAZĂ TEST DE COMPILARE
REM ====================================================================
echo ⚙️  6. TESTING DART COMPILATION...
echo ─────────────────────────────────

REM Creează un test simplu
echo // Test compilation > test_compilation_check.dart
echo import 'lib/models/allergen/allergen_match.dart'; >> test_compilation_check.dart
echo import 'lib/models/allergen/hybrid_detection_result.dart'; >> test_compilation_check.dart
echo import 'lib/services/hybrid_detection_service.dart'; >> test_compilation_check.dart
echo. >> test_compilation_check.dart
echo void main() { >> test_compilation_check.dart
echo   final service = HybridDetectionService(); >> test_compilation_check.dart
echo   service.initialize(); >> test_compilation_check.dart
echo   print('Compilation test OK'); >> test_compilation_check.dart
echo } >> test_compilation_check.dart

dart analyze test_compilation_check.dart >nul 2>&1
if errorlevel 1 (
    echo ❌ Dart compilation test FAILED
    echo    Run: dart analyze test_compilation_check.dart for details
    set ALL_GOOD=false
) else (
    echo ✅ Dart compilation test PASSED
)

REM Cleanup
del test_compilation_check.dart >nul 2>&1

echo.

REM ====================================================================
REM REZULTAT FINAL
REM ====================================================================
echo 📋 VERIFICATION SUMMARY
echo ======================

if "%ALL_GOOD%"=="true" (
    echo.
    echo 🎉 ALL CRITICAL CHECKS PASSED!
    echo.
    echo ✅ Ready for next steps:
    echo    1. Run: flutter pub get
    echo    2. Setup BERT server: run bert_server_setup.bat
    echo    3. Add provider to main.dart
    echo    4. Test the integration
    echo.
    echo 🚀 Your HealthApp Allergen Detection is READY!
    
) else (
    echo.
    echo ❌ SOME ISSUES FOUND!
    echo.
    echo ⚠️  Common fixes needed:
    echo    • Remove duplicate classes from allergen_match.dart
    echo    • Add missing 'method' and 'metadata' parameters
    echo    • Add http and provider dependencies to pubspec.yaml
    echo    • Install Python 3 and Flutter SDK
    echo.
    echo 🔧 Fix these issues and run the script again.
)

echo.
echo 📞 Need help? Check your file structure and imports.
echo.

pause