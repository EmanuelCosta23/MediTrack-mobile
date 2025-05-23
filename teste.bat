@echo off
taskkill /F /IM dart.exe
taskkill /F /IM java.exe
timeout /t 2
rmdir /s /q .dart_tool
rmdir /s /q build
rmdir /s /q .idea
rmdir /s /q .vscode
flutter pub get
timeout /t 2