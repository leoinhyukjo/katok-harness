#!/bin/zsh
# katok 일일 아카이브: 카톡 로컬 DB → 아카이브 → 첨부 보존
# 첨부 백필이 핵심 — 카카오 presigned 링크는 ~14일 뒤 410으로 영구 소멸한다.
#
# semantic 인덱스(katok index)는 뺐다. 아카이브 텍스트 전량이 0.1MB / 4,438건이라
# SQL LIKE 전수 스캔이 6ms 로 끝나는데, 그걸 위해 214MB 임베딩 모델을 유지할 이유가 없다.
# 게다가 katok 은 EmbeddingGemma 에 E5 계열 접두어(query:/passage:)를 붙이는 버그가 있어
# 추상 질의 품질도 낮다. 검색은 ~/.zshrc 의 kt / ktc 함수(SQL 직접) 사용.
# 되돌리려면 이 줄 복원: "$K" index --json >>"$LOG" 2>&1   (모델을 다시 내려받는다)
set -u
K="$HOME/.cargo/bin/katok"
LOG="$HOME/.claude/logs/katok-daily.log"
mkdir -p "$(dirname "$LOG")"

echo "=== $(date '+%F %T') ===" >>"$LOG"
"$K" sync --source macos --json >>"$LOG" 2>&1
"$K" media backfill --kind file --kind image --kind video --json >>"$LOG" 2>&1
echo "" >>"$LOG"
