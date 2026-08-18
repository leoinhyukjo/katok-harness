#!/bin/zsh
# katok 상주 감시 — 카톡이 로컬 DB 에 쓰는 순간 sync 를 띄운다. 지연 ~2초.
#
# 왜 launchd WatchPaths 가 아닌가 (2026-08-11 실측):
#   WatchPaths 는 카톡 샌드박스 컨테이너 경로에서 발동하지 않는다. WAL 이 15:38:44 에
#   바뀌었는데 60초 넘도록 runs=0 이었다. 같은 plist 구조를 일반 경로에 걸면 쓰기와
#   같은 초에 발동하므로 메커니즘이 아니라 경로 문제다 — launchd 의 FSEvents 중계
#   (UserEventAgent)가 남의 앱 컨테이너 이벤트를 못 받는다.
#
# 그래서 mtime 을 직접 본다. stat 1회 0.3ms(하루 43,200회 = CPU 13초)로 공짜에 가깝고,
# 비싼 쪽(sync 0.5초, DB 복호화)은 실제로 바뀌었을 때만 돈다. 10초 폴링으로 sync 를
# 통째로 돌리면 하루 CPU 75분인데, 이 방식은 그보다 350배 싸면서 5배 빠르다.
set -u
DIR="$HOME/Library/Containers/com.kakao.KakaoTalkMac/Data/Library/Application Support/com.kakao.KakaoTalkMac"
SYNC="$HOME/.claude/scripts/katok_sync.sh"
INTERVAL=2
FORCE_EVERY=150   # 5분마다는 변화가 없어도 한 번 — 감시가 헛돌아도 스스로 복구된다

LAST=""
i=0
while true; do
  # 파일명은 카톡 계정 해시라 계정마다 다르다. 매번 글롭해서 재로그인·재설치에도 따라간다.
  # WAL 만 보면 충분하다 — 모든 쓰기가 WAL 을 먼저 거치고, 체크포인트로 WAL 이 잘릴 때도
  # mtime 이 바뀐다. 같은 초 안의 연속 쓰기를 놓치지 않게 나노초(%Fm)와 크기를 함께 본다.
  STAMP="$(stat -f '%Fm %z' "$DIR"/*-wal(N) 2>/dev/null)"
  i=$(( i + 1 ))

  if [[ -n "$STAMP" && "$STAMP" != "$LAST" ]] || (( i % FORCE_EVERY == 0 )); then
    LAST="$STAMP"
    "$SYNC"
  fi

  sleep "$INTERVAL"
done
