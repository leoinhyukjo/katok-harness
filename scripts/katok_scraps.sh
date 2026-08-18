#!/bin/bash
# 카톡 「나에게 보내기」에 넣어둔 링크를 스크랩 델타로 뽑는다. /scraps-organize 의 입구.
# list          — 워터마크 이후 새 링크만 TSV(timestamp \t url \t 원문) 로 출력
# commit <ts>   — 그 항목까지 처리 완료로 워터마크 전진 (오름차순으로 건별 호출)
# mark          — 현재 워터마크
set -euo pipefail

DB="$HOME/Library/Application Support/katok/archive.sqlite3"
CHAT=173719932601453   # 「나에게 보내기」. group 타입이지만 발신자가 조인혁/leo 단독인 방
MARK="$HOME/.claude/state/scraps-katok.watermark"

case "${1:-list}" in
list)
  since=$(cat "$MARK" 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%S+00:00)
  sqlite3 -separator $'\t' "$DB" \
    "SELECT timestamp, replace(replace(text, char(10), ' '), char(9), ' ')
       FROM messages
      WHERE chat_id = '$CHAT' AND message_type = 'text'
        AND text LIKE '%http%' AND timestamp > '$since'
      ORDER BY timestamp;" |
  LC_ALL=C awk -F'\t' '{
    url = ""
    if (match($2, /https?:\/\/[!-~]+/)) url = substr($2, RSTART, RLENGTH)
    if (url != "") print $1 "\t" url "\t" $2
  }'
  ;;
commit)
  mkdir -p "$(dirname "$MARK")"
  printf '%s' "${2:?commit 은 timestamp 인자가 필요합니다}" > "$MARK"
  ;;
mark)
  cat "$MARK" 2>/dev/null || echo "(없음 — 최근 7일로 시작)"
  ;;
*)
  echo "usage: $0 {list|commit <timestamp>|mark}" >&2
  exit 1
  ;;
esac
