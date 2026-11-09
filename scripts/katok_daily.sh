#!/bin/zsh
# katok 일일 아카이브: 카톡 로컬 DB → 아카이브 → 원문 백업
# 개인 카톡 첨부 백필은 끈다(Leo 261021). 첨부 보존은 법인 카톡만(~/brain/infra/katok_corp/katok_corp_sync.sh).
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
# 예외: 아래 개인 방만 첨부 보존(Leo 261109). 법인폰이 없는 방이라 법인 쪽으로는 못 받는다.
# 473672778156664 [코리너스 전략 논의] / 458333507363369 이동훈 부대표 1:1 / 466672740773740 정태원 대표님 1:1(태원)
# katok-media = cs 지문 없는 첨부도 크기 대조로 받는 패치판. 전체 디스크 접근 권한을 준 뒤에만 쓴다(표식 파일).
KM="$K"; [[ -e "$HOME/.config/katok/katok-media-fda-ok" ]] && KM="$HOME/.cargo/bin/katok-media"
for c in 473672778156664 458333507363369 466672740773740; do "$KM" media backfill --chat $c --kind file --kind image --kind video --json >>"$LOG" 2>&1; done
echo "" >>"$LOG"
# 원문 백업은 sync 뒤 마지막 — 푸시가 실패해도 sync 는 이미 끝나 있다
"$HOME/.claude/scripts/katok_backup.sh" >>"$LOG" 2>&1 || echo "BACKUP FAIL" >>"$LOG"
