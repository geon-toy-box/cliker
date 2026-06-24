#!/usr/bin/env bash
# cliker 웹(Flutter) → Vercel 정적 배포 헬퍼.
#
# Flutter 웹은 정적 파일(build/web)로 빌드되고 Vercel이 이를 호스팅한다.
# web/vercel.json(SPA rewrite + 캐싱)은 빌드 시 build/web/로 복사된다.
#
# 사용:
#   1) (최초 1회) Vercel CLI 설치 + 로그인:  npm i -g vercel && vercel login
#   2) 이 스크립트 실행:                      tools/deploy_web.sh
#   3) 안내되는 vercel 명령으로 배포(프리뷰/프로덕션).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> flutter build web --release"
flutter build web --release

# web/vercel.json이 build/web에 들어갔는지 보장(혹시 미복사 시 직접 복사).
[ -f build/web/vercel.json ] || cp web/vercel.json build/web/vercel.json
echo "==> build/web 준비 완료 ($(du -sh build/web | cut -f1))"

cat <<'EOF'

다음 명령으로 배포하세요 (Vercel CLI 로그인 필요):

  # 프리뷰 배포 (URL 생성)
  cd build/web && vercel --yes

  # 프로덕션 배포
  cd build/web && vercel --prod --yes

참고:
  - build/web 폴더 자체를 정적 사이트로 올립니다(프레임워크 자동감지 'Other').
  - vercel.json의 rewrite로 SPA 라우팅이 처리됩니다.
  - GitHub 연동 자동배포를 원하면 별도 설정 필요(Vercel 빌드환경엔 Flutter가 없어
    prebuilt 업로드 방식이 가장 안정적입니다).
EOF
