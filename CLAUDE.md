# dailio-jp

Daylio対抗の超シンプル気分×睡眠トラッカー（iOS）。記録項目は「気分10点スライダー」と「睡眠時間（HealthKit自動取込）」の2つだけ。Daylio Pro ¥400/月の半額（¥200/月）でポジショニング。

仕様の唯一の正本は GitHub issue **a-yuto/niki-sandbox#63**。要件追加・変更時は issue を先に更新する。

## プロジェクト構成

- `dailio-jp.xcodeproj` — Xcode プロジェクト（PBXFileSystemSynchronizedRootGroup 方式 = ファイル追加で `project.pbxproj` の手編集は不要）
- `dailio-jp/` — アプリ本体ソース（`dailio_jpApp.swift` がエントリポイント）
- `dailio-jpTests/` — ユニットテスト（Swift Testing。`@Test` を使う、XCTest ではない）
- `dailio-jpUITests/` — UI テスト（XCTest）

### ビルド設定（`project.pbxproj` より）

- Bundle ID: `niki.dailio-jp`
- Deployment Target: **iOS 26.4**（最新 API 前提で進める。issue 記載の「iOS 17+」より引き上げ確定）
- Swift 5.0 / `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`（既定で MainActor 隔離）
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`（ローカライズは String Catalog を使う）
- 対応デバイス: iPhone + iPad（`TARGETED_DEVICE_FAMILY = "1,2"`）
- Development Team: `4L2W8Y4RLS`

## 技術スタック（採用予定）

| 領域 | スタック |
|---|---|
| UI | SwiftUI |
| データ永続化 | SwiftData + CloudKit 同期 |
| グラフ | Swift Charts（`import Charts`） |
| 健康データ | HealthKit（睡眠カテゴリ読み取り） |
| 通知 | UserNotifications |
| 課金 | StoreKit 2 |
| 広告 | Google Mobile Ads SDK（AdMob バナー） |
| ウィジェット | WidgetKit |
| ロック | LocalAuthentication（Face ID / パスコード） |

## ビルド・テスト

```bash
# ビルド（iPhone 15 シミュレータ）
xcodebuild -project dailio-jp.xcodeproj -scheme dailio-jp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# ユニットテスト
xcodebuild -project dailio-jp.xcodeproj -scheme dailio-jp \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

ファイル追加は Xcode の同期グループ機能により自動認識される。`project.pbxproj` の編集は基本的に不要。

## コード規約

- SwiftUI のモダン API を優先（`@Observable`、`@Bindable`、SwiftData の `@Query` / `@Model` など）
- Concurrency は MainActor 隔離をデフォルトに、HealthKit / StoreKit など I/O は明示的に `Task` / `async` で逃がす
- ローカライズは String Catalog（`Localizable.xcstrings`）に集約。日本語が一次言語、英語は後追い対応
- ハードコードしたユーザー向け文字列を残さない（`String(localized:)` または `Text(...)` 経由）
- `import Foundation` は SwiftUI / SwiftData がカバーする範囲では省略
- `// MARK: -` で論理ブロックを区切る
- ファイルあたり 1 つの主たる型を原則
- swiftui-pro スキルでレビューしたくなったら `Skill(swiftui-pro:swiftui-pro)` を呼ぶ

## ドメインモデル（最小）

```swift
@Model final class MoodEntry {
    var date: Date           // 記録日（その日の代表時刻 = 22:00 など）
    var mood: Double         // 0〜10、連続値、表示は整数丸め
    var sleepHours: Double?  // 直前の夜の睡眠時間（HealthKit or 手動）
    var sleepSource: SleepSource  // .healthKit / .manual
    var createdAt: Date
}
```

- 「日」の同一性: アプリ内の論理日 = 入力時刻が属するカレンダー日（ユーザータイムゾーン）
- 同一論理日の重複入力は upsert（直近のもので上書き）
- 睡眠は「前夜」を表すため、論理日の前日 18:00 〜 当日 12:00 を HealthKit クエリ範囲とする

## プライバシー / セキュリティ

メンタルデータを扱うため、issue にあるとおり「第三者送信は一切しない」を明確に守る。

- AdMob は記録画面下部のバナーのみ。リワード動画/インタースティシャルは入れない。AdMob の収集データは App Privacy で正確に申告
- CloudKit 同期はユーザーの iCloud Container 内に閉じる（オプトアウト可）
- 端末内データは Data Protection（`NSFileProtectionComplete` 相当）で保護
- HealthKit データはサーバ送信しない。デバッグログにも出さない
- パスコード / Face ID は LocalAuthentication で実装、起動時とバックグラウンド復帰時にロック

## 課金 / 広告

| プラン | 価格 | プロダクト ID（仮） |
|---|---|---|
| Pro 月額 | ¥200/月 | `niki.dailio-jp.pro.monthly` |
| Pro 年額 | ¥1,980/年 | `niki.dailio-jp.pro.yearly` |
| Lifetime | ¥4,980（買い切り） | `niki.dailio-jp.pro.lifetime` |

- StoreKit 2 のトランザクション監視を `App` 起動直後に開始
- Pro 機能ゲート: 移動平均期間カスタム / PDF エクスポート / Watch コンプリ / テーマ / 散布図 / AI 振り返り
- 無料版は AdMob バナーを記録画面下部のみに表示
- Lifetime と年額のカニバリ評価は Phase 2 以降に実データで判断（issue 「ビジネス上の検討事項」）

## UI 仕様（決定済み）

issue 末尾「未決事項」はユーザー確認済み。

- **スライダー**: 赤（0）→ 緑（10）のカラーグラデーション
- **数字ラベル**: 10=最高 / 5=普通 / 0=最悪 を常時表示
- **ストリーク**: 連続記録日数を表示する（プレッシャー懸念は文言・配置で和らげる）

## リリース計画

実装フェーズの全体像は `IMPLEMENTATION_PLAN.md` を参照。
