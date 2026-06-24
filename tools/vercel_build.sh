#!/usr/bin/env bash
# Vercel 빌드 스크립트 — Flutter가 없는 빌드 환경에서 cliker 웹을 빌드한다.
#
# repo가 push되면 Vercel이 vercel.json의 buildCommand로 이 스크립트를 실행하고,
# 결과물(build/web)을 정적 호스팅한다. Vercel 빌드환경엔 Flutter가 없으므로 여기서
# Flutter SDK를 받아 웹을 빌드한다.
#
# Flutter 버전 고정: Vercel 프로젝트 환경변수 FLUTTER_REF=3.41.7 처럼 지정 가능
# (기본 stable). 로컬과 버전을 맞추려면 고정 권장.
set -euo pipefail

FLUTTER_REF="${FLUTTER_REF:-stable}"

# git 'dubious ownership' 회피 (CI 환경)
git config --global --add safe.directory '*' || true

if [ ! -x flutter/bin/flutter ]; then
  echo "==> Cloning Flutter ($FLUTTER_REF)"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_REF" flutter
fi

export PATH="$PWD/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release

echo "==> Done: build/web ($(du -sh build/web 2>/dev/null | cut -f1))"
