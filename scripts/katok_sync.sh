#!/bin/zsh
# katok 증분 sync — 이벤트 구동(launchd com.gowid.katok-sync).
#
# 카톡이 로컬 DB에 쓰는 순간 launchd WatchPaths 가 이걸 띄운다. 지연 ~10초.
# katok 은 카톡 DB 를 복사 없이 read-only 로 직접 열어(reader.rs) SQLite 가 WAL 을
# 따라 읽으므로, 카톡 앱의 체크포인트(수십 분 주기)를 기다리지 않는다.
#
# 첨부 백필은 여기 없다 — CDN 을 타므로 katok_daily.sh(09:30) 하루 1회가 담당한다.
# 조용한 실행은 로그를 남기지 않는다. 하루 수백 번 도는데 전부 남기면 로그만 부푼다.
set -u
K="$HOME/.cargo/bin/katok"
LOG="$HOME/.claude/logs/katok-sync.log"
[[ -x "$K" ]] || exit 0
mkdir -p "$(dirname "$LOG")"

OUT="$("$K" sync --source macos --json 2>/dev/null)"
if [[ $? -ne 0 || -z "$OUT" ]]; then
  print -r -- "$(date '+%F %T')  SYNC FAIL" >>"$LOG"
  exit 1
fi

N="$(print -r -- "$OUT" | /usr/bin/jq -r '.inserted_messages // 0' 2>/dev/null)"
[[ -z "$N" || "$N" == "0" ]] && exit 0

T="$(print -r -- "$OUT" | /usr/bin/jq -r '.total_messages // "?"' 2>/dev/null)"
print -r -- "$(date '+%F %T')  +${N}건 (총 ${T})" >>"$LOG"
