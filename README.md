# katok-harness

macOS 카카오톡 로컬 DB 를 상시 아카이브하고 셸에서 검색하는 개인 하네스.

본체는 [`katok`](https://crates.io/crates/katok) (NomaDamas, Rust, MIT) 0.3.0 무수정 그대로 쓴다. 상류 저장소와 crates.io 배포판은 2026-10 기준 내려가 있어 원본은 `vendor/katok-0.3.0.crate` 뿐이다.
법인 카톡 첨부 백필(`~/brain/infra/katok_corp`)만 패치판 `katok-media` 를 쓴다(아래 「패치판」). 개인 카톡 첨부 백필은 껐다.
이 레포는 그 위에 얹은 **운영 층**(상주 감시 · 첨부 백필 · 검색 함수 · 스크랩 델타)만 담는다.

## 구성

| 경로 | 역할 |
|---|---|
| `scripts/katok_watch.sh` | 상주 루프. 카톡 WAL 의 mtime 을 2초마다 stat, 바뀐 순간에만 sync (지연 3~5초 실측) |
| `scripts/katok_sync.sh` | 증분 sync 1회. 신규 0건이면 로그 무기록 |
| `scripts/katok_daily.sh` | 09:30 sync 1회 + 원문 암호화 백업. 개인 카톡 첨부 백필은 끔(Leo 261021) |
| `scripts/katok_scraps.sh` | 「나에게 보내기」 링크 델타 추출 (워터마크 기반). `/scraps-organize` 입구 |
| `zsh/katok-functions.zsh` | `kt <검색어>` / `ktc <방이름>` — 아카이브 SQL 직접 조회 |
| `launchd/*.plist` | 위 2종 잡 등록 |
| `vendor/katok-0.3.0/` | 패치판 소스. 원본 `vendor/katok-0.3.0.crate`, 차이 `vendor/katok-0.3.0-media-size-verify.patch` |

## 설치

```sh
cargo install --path vendor/katok-0.3.0 --no-default-features --locked   # crates.io 판은 내려감. send 코드 미포함 — 카카오 ToS·계정 리스크 회피
# 이 설치본은 패치판이다. 원본 그대로가 필요하면 vendor/katok-0.3.0.crate 를 풀어 같은 명령으로 설치
ln -s ~/katok-harness/scripts/katok_*.sh ~/.claude/scripts/
cp ~/katok-harness/launchd/*.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.gowid.katok-{watch,daily}.plist
echo 'source ~/katok-harness/zsh/katok-functions.zsh' >> ~/.zshrc
```

## 🚨 전제 — 전체 디스크 접근 권한

`~/.cargo/bin/katok` 에 **전체 디스크 접근**을 줘야 한다. 「앱 데이터」 승인만으로는 부족하다 —
katok 이 adhoc 서명이라 TCC 가 신원을 고정하지 못해 매번 다시 묻고, 2초 루프가 그걸 무한 팝업으로 만든다.

```sh
sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
  "SELECT auth_value FROM access WHERE service='kTCCServiceSystemPolicyAllFiles' AND client LIKE '%katok%';"
# → 2 면 허용
```

**katok 을 재빌드하면 서명 해시가 바뀌어 권한이 깨진다.** 재빌드 후에는 잡을 내리고 권한을 다시 준 뒤 올릴 것.

## 패치판 `katok-media` — 지문 없는 첨부

카카오가 일부 첨부(파일·사진·영상)의 `cs`(SHA-1) 를 null·빈 값으로 보낸다. 원본 0.3.0 은 이런 첨부를 "no cs fingerprint" 로 받지 않는다.
패치판은 `cs` 가 없을 때 받은 본문 크기가 첨부에 적힌 크기(`s`/`size`)와 정확히 같을 때만 저장한다. 크기도 없으면 원본처럼 거부한다.

```sh
cd vendor/katok-0.3.0 && cargo build --release --no-default-features --locked && cp target/release/katok ~/.cargo/bin/katok-media
```

`~/brain/infra/katok_corp/katok_corp_sync.sh`(법인)는 `~/.config/katok/katok-media-fda-ok` 가 있을 때만 패치판을 부른다.
`~/.cargo/bin/katok-media` 에 전체 디스크 접근을 준 뒤에 그 파일을 만든다. **재빌드하면 권한이 깨지므로 표식 파일부터 지우고 다시 준다.**

## 커버리지 한계 — 검색 결과를 "전체 이력"으로 말하지 말 것

1. 카톡 macOS 앱이 로컬에 두는 건 **약 30일 롤링 윈도우**뿐. 최초 sync 이전 대화는 복구 불가.
2. 일반 파일 첨부(`type_18`)는 로컬 캐시가 없고 CDN 링크가 **약 14일 뒤 영구 소멸**. 사진·영상은 로컬 캐시가 있어 무관.

정기 실행이 값의 전부 — katok 은 지우지 않고 누적하므로 시간이 갈수록 앱보다 긴 이력을 보유한다.
반대로 launchd 가 죽으면 그 구간은 영구 손실.

## 기계별로 바꿔야 하는 값

- `scripts/katok_scraps.sh` 의 `CHAT` — 「나에게 보내기」 방 id. 계정마다 다르다.
  `chat_type` 이 `direct` 가 아니라 `group` 이고 이름도 `chat-<id>` 라 이름·타입으로는 못 찾는다.
  발신자가 본인 단독인 방으로 식별할 것.
- plist `Label` 접두어 `com.gowid.*`.

## 설계 메모

- **왜 `WatchPaths` 가 아닌가**: launchd 의 FSEvents 중계가 남의 앱 샌드박스 컨테이너 이벤트를 못 받는다.
  WAL 이 바뀌어도 60초 넘게 `runs=0`. 같은 plist 를 일반 경로에 걸면 즉시 발동 — 메커니즘 아닌 경로 문제.
- **왜 semantic 인덱스를 걷어냈나**: 아카이브 텍스트 전량이 0.1MB 인데 임베딩 모델이 214MB.
  SQL LIKE 전수 스캔 6ms 로 충분하다. 아카이브가 수십 MB 로 커지면 러너에 `katok index` 한 줄 복원.

데이터(`archive.sqlite3`)와 로그는 커밋하지 않는다 — 카톡 원문에 고객 PII 가 들어 있다.
원문은 `katok_backup.sh`(일일 잡 끝)가 AES-256 으로 암호화해 private 레포 `katok-archive-backup` 에 커밋 1개로 force-push 한다.
키는 `~/.config/katok/backup.key`(Apple 암호 앱에도 보관). 복원 명령은 스크립트 머리 주석.
