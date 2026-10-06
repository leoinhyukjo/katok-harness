#!/bin/zsh
# katok 아카이브 원문 백업: archive.sqlite3 → gzip → AES-256 암호화 → private 레포 force-push
# 맥을 잃거나 이관하면 아카이브가 영구 손실된다(2026-09-04 이관 때 실제 발생). 그걸 막는 사본.
# 레포는 커밋 1개만 유지한다 — 아카이브는 지우지 않고 누적하므로 최신본 하나면 충분하고,
# 암호화 blob 은 git delta 가 안 먹어 매일 쌓으면 1년에 GB 단위로 불어난다.
# 키: ~/.config/katok/backup.key (Apple 암호 앱에도 보관). 키를 잃으면 백업도 못 연다.
# 복원: openssl enc -d -aes-256-cbc -pbkdf2 -pass file:KEY -in archive.sqlite3.gz.enc | gunzip > archive.sqlite3
set -eu
DB="$HOME/Library/Application Support/katok/archive.sqlite3"
KEY="$HOME/.config/katok/backup.key"
REPO="$HOME/katok-archive-backup"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# cp 금지 — katok 이 WAL 로 열고 쓰는 중이라 .backup 으로 일관된 스냅숏을 뜬다
sqlite3 "$DB" ".backup '$TMP/a.sqlite3'"
N=$(sqlite3 "$TMP/a.sqlite3" "SELECT count(*) FROM messages")
gzip -c "$TMP/a.sqlite3" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:$KEY" -out "$REPO/archive.sqlite3.gz.enc"

cd "$REPO"
git add archive.sqlite3.gz.enc
MSG="backup: $(date '+%F %T') messages=$N"
if git rev-parse -q --verify HEAD >/dev/null; then
  git commit -q --amend --reset-author -m "$MSG"
else
  git commit -q -m "$MSG"
fi
git push -q --force origin main
echo "$MSG"
