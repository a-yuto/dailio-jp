# dailio-jp 実装計画（リリースまで）

GitHub issue **a-yuto/niki-sandbox#63** をリリース v1.0 まで持っていくための実装ロードマップ。
現状: Xcode テンプレートそのまま（`Item.swift` / `ContentView.swift` がデフォルト）。

## マイルストーン全体像

| Phase | 目的 | 完了の定義 |
|---|---|---|
| 0 | プロジェクト基盤 | ビルド設定・依存解決・CI まで通る |
| 1 | データモデル + 記録フロー | 気分・睡眠の手動入力で記録が永続化 |
| 2 | HealthKit 統合 | 前夜の睡眠が自動取込される |
| 3 | 可視化 | ダブル折れ線 + 7 日移動平均が動く |
| 4 | 通知 | 22:00 リマインダーで入力フローへ遷移 |
| 5 | 課金 + 広告 | StoreKit 2 で Pro 解放、AdMob バナー表示 |
| 6 | 補助機能 | ロック / iCloud / ウィジェット |
| 7 | オンボーディング | 初回起動 6 ステップ完走 |
| 8 | ローカライズ + プライバシー | App Store 申請に必要なメタ整備 |
| 9 | リリース | TestFlight → 本番審査通過 |

各 Phase は **直前の Phase のテストが緑であること** を条件に着手。

---

## Phase 0 — プロジェクト基盤（半日〜1日）

**ゴール:** 雑多な前提を整え、後続 Phase が機能実装に集中できる状態にする。

- [x] iOS deployment target = **26.4**（確定）
- [x] Bundle ID = **`niki.dailio-jp`** / Team = **`4L2W8Y4RLS`**（確定）
- [ ] Xcode capability 追加: HealthKit / Push Notifications / iCloud (CloudKit) / In-App Purchase / App Groups（ウィジェット用）
- [ ] `Info.plist` キー追加: `NSHealthShareUsageDescription`、`NSHealthUpdateUsageDescription`（睡眠は読み取りのみだが警告回避のため両方）
- [ ] StoreKit プロダクト ID 確定: `niki.dailio-jp.pro.{monthly,yearly,lifetime}`
- [ ] CloudKit Container 作成、Schema を SwiftData に合わせる
- [ ] AdMob アカウント作成・iOS アプリ登録、テスト広告ユニット ID 取得（本番ユニットは Phase 5 で）
- [ ] Swift Package 追加: Google Mobile Ads SDK
- [ ] テンプレート由来の `Item.swift` / `ContentView.swift` の削除予定をマーキング（Phase 1 で置換）
- [ ] CI 雛形（GitHub Actions、`xcodebuild test` のみ）

---

## Phase 1 — データモデル + 記録フロー（2〜3日）

**ゴール:** HealthKit なしでも気分と睡眠を手動入力でき、SwiftData に永続化される。

- [ ] `MoodEntry` モデル定義（CLAUDE.md のスキーマ）
- [ ] `SleepSource` 列挙型（`healthKit` / `manual`）
- [ ] `MoodRepository`（同一論理日 upsert を含む CRUD）
- [ ] 記録画面 `EntryView`
  - [ ] 気分スライダー（0〜10、連続値、表示は整数、**赤→緑のカラーグラデーション**）
  - [ ] スライダー脇に**「10=最高 / 5=普通 / 0=最悪」ラベル**を常時表示
  - [ ] 睡眠時間入力（時刻 / 時間直接入力の 2 モード）
  - [ ] 保存ボタン → upsert
- [ ] **ストリーク表示**コンポーネント（連続記録日数。文言は柔らかめ：「○日連続で記録中」など）
- [ ] 履歴画面 `HistoryView`（簡易リスト、Phase 3 で本格的なグラフに）
- [ ] ユニットテスト
  - [ ] 同一論理日 upsert の検証
  - [ ] 日跨ぎ（深夜入力）でも論理日が正しい
  - [ ] ストリーク計算（連続日数のロジック、空白日でリセット）

---

## Phase 2 — HealthKit 統合（2日）

**ゴール:** 記録画面を開いた瞬間に「前夜の睡眠」が自動入力される。

- [ ] `HealthKitClient`（`HKHealthStore` ラッパー、`async/await` API）
- [ ] 睡眠許可リクエスト（`HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)`）
- [ ] 前夜の集計クエリ（前日 18:00 〜 当日 12:00、`asleepCore` + `asleepDeep` + `asleepREM` の合算）
- [ ] 取得失敗時のフォールバック → 手動入力 only にグレースフルダウン
- [ ] 記録画面で source バッジ表示（HealthKit 自動 / 手動）
- [ ] 手動上書き時に source = manual に切り替わる
- [ ] テスト: HealthKit クエリ範囲のロジック単体テスト（クライアントはモック化）

---

## Phase 3 — 可視化（3日）

**ゴール:** 気分と睡眠の関係が一目で見える。

- [ ] Swift Charts でダブル折れ線（気分: 左軸 0〜10、睡眠: 右軸 0〜12h）
- [ ] 7 日移動平均の重ね描画（生データを薄く、移動平均を濃く）
- [ ] 移動平均 ON/OFF トグル
- [ ] 期間切替（1 週 / 1 ヶ月 / 3 ヶ月 / 1 年）
- [ ] 月次サマリー: 最高気分の曜日 / 最低気分の曜日
- [ ] 空データ時のプレースホルダー（オンボ直後）
- [ ] テスト: 移動平均の数値計算

---

## Phase 4 — 通知（1日）

**ゴール:** デフォルト 22:00 にリマインダーが届き、タップで記録画面に遷移。

- [ ] 通知許可リクエスト（オンボーディングで実施）
- [ ] `UNCalendarNotificationTrigger` で毎日 22:00（カスタム可）
- [ ] 通知タップ → ディープリンクで `EntryView` 直行
- [ ] 設定画面で時刻変更 UI

---

## Phase 5 — 課金 + 広告（3日）

**ゴール:** 無料版は広告つき、Pro 購入で広告除去 + Pro 機能解放。

- [ ] StoreKit 2: `Product.products(for:)` でプロダクト取得
- [ ] `EntitlementStore`（`@Observable`、`Transaction.currentEntitlements` を監視）
- [ ] 購入フロー（月額 / 年額 / Lifetime の 3 つ）
- [ ] 復元購入ボタン
- [ ] App Store Connect で 3 プロダクト作成
- [ ] AdMob バナー: 記録画面下部に配置、Pro なら非表示
- [ ] 機能ゲート: 移動平均期間カスタム / PDF / テーマ
- [ ] StoreKit Configuration File でローカルテスト
- [ ] テスト: entitlement 状態に応じた UI 分岐

**Phase 2 機能（散布図 / AI 振り返り / Watch / PMS）は v1.0 のスコープ外**。issue にも Phase 2 と明記されているのでリリース後に分割。

---

## Phase 6 — 補助機能（2日）

- [ ] パスコード / Face ID（LocalAuthentication）、起動時 + バックグラウンド復帰時にロック
- [ ] iCloud バックアップ（Phase 0 の CloudKit 設定が活きる）— 設定画面に ON/OFF
- [ ] ホームウィジェット（直近 7 日のミニグラフ）— Small / Medium サイズ
  - [ ] App Group 経由で SwiftData を共有 or `WidgetKit` の TimelineProvider で再クエリ

---

## Phase 7 — オンボーディング（1〜2日）

issue「オンボーディング設計（完了率重視）」の 6 ステップを実装。

1. [ ] ようこそ画面（30 秒で「2 項目だけ」コンセプト訴求）
2. [ ] HealthKit 睡眠データ許可
3. [ ] 通知許可 + 入力時刻設定（デフォルト 22:00）
4. [ ] 初回入力チュートリアル（スライダーを動かして体験）
5. [ ] ホームウィジェット追加ガイド（任意）
6. [ ] 完了 → 翌日のグラフプレビュー

- [ ] 各ステップでスキップ可能 / 戻る可能
- [ ] 完走 / 離脱地点を `UserDefaults` に記録（後で分析できるように）

---

## Phase 8 — ローカライズ + プライバシー（1〜2日）

**ゴール:** App Store 審査に通る状態。

- [ ] `Localizable.xcstrings` を整備、まず ja を完璧に。en は最低限
- [ ] App Privacy（収集データ申告）— AdMob の収集項目を正確に
- [ ] プライバシーポリシー / 利用規約のホスティング（GitHub Pages か）
- [ ] App Store Connect スクリーンショット（6.7" / 6.5" / 5.5" / iPad 12.9"）
- [ ] アプリアイコン（1024x1024 + iOS 全サイズ）
- [ ] ストア説明文（Daylio との差別化を強調、半額・2 項目入力・睡眠相関）
- [ ] キーワード / プロモーションテキスト
- [ ] 季節要素（春の不調 / 梅雨だるさ / 五月病マーカー）の通知文言プリセット — issue「日本市場向け差別化」より

---

## Phase 9 — リリース（1週間）

- [ ] TestFlight 内部テスト（自分 + 数名）
- [ ] TestFlight 外部テスト（10〜20 人募集）
  - 1 週間使ってもらい、入力継続率 / Pro 転換率 / クラッシュレポートを観察
- [ ] クラッシュフリー率 99.5% 以上を確認
- [ ] App Store 提出
- [ ] 審査リジェクト対応バッファ（1〜2 サイクル想定。HealthKit / 課金 / プライバシーで指摘されやすい）
- [ ] 公開後: 広告 eCPM / Pro 転換率 / 退会率を 1 週間モニタリング

---

## スコープ外（v1.1 以降）

issue の **Phase 2** はリリース後に切り出す。

- 散布図（睡眠 × 気分の相関、Pro 限定）
- 移動平均期間カスタム（3 / 14 / 30 / 90 日。MVP は 7 日固定）
- PDF レポートエクスポート
- AI 振り返り
- Apple Watch コンプリ + ワンタップ入力
- PMS / 生理周期連動
- テーマカスタマイズ
- CSV エクスポート

---

## 想定スケジュール

実働 1 人・専従換算で **約 4〜5 週間** + 審査バッファ 1〜2 週間。

| 週 | Phase |
|---|---|
| 1 | 0, 1 |
| 2 | 2, 3 |
| 3 | 4, 5 |
| 4 | 6, 7 |
| 5 | 8, 9（TestFlight 開始） |
| 6〜7 | 9 残り（外部テスト + 審査） |

---

## 確定済み事項

| 項目 | 決定 |
|---|---|
| iOS deployment target | **26.4** |
| Bundle ID / Team | `niki.dailio-jp` / `4L2W8Y4RLS` |
| スライダー UI | 赤→緑 グラデーション |
| 数字ラベル | 10=最高 / 5=普通 / 0=最悪 を表示 |
| ストリーク | 表示あり（文言は柔らかめ） |
| v1.0 スコープ | issue MVP のみ。issue Phase 2 は v1.1 以降に切り出し |
