# dailio-jp 実装計画（リリースまで）

GitHub issue **a-yuto/niki-sandbox#63** をリリース v1.0 まで持っていくための実装ロードマップ。

## マイルストーン全体像

| Phase | 目的 | 完了の定義 | 状態 |
|---|---|---|---|
| 0 | プロジェクト基盤 | ビルド設定・依存解決・CI まで通る | ✅ 完了（一部手作業残） |
| 1 | データモデル + 記録フロー | 気分・睡眠の手動入力で記録が永続化 | ✅ 完了 |
| 2 | HealthKit 統合 | 前夜の睡眠が自動取込される | ✅ 完了 |
| 3 | 可視化 | ダブル折れ線 + 7 日移動平均が動く | ✅ 完了 |
| 4 | 通知 | 22:00 リマインダーで入力フローへ遷移 | ✅ 完了 |
| 5 | 課金 + 広告 | StoreKit 2 で Pro 解放、AdMob バナー表示 | ✅ コア完了（AdMob SDK は手作業） |
| 6 | 補助機能 | ロック / iCloud | ✅ ロック + iCloud 完了 |
| 6.5 | ウィジェット | ホームウィジェット表示 | ⏳ Xcode で Widget Extension 追加 |
| 7 | オンボーディング | 初回起動 5 ステップ完走 | ✅ 完了（ウィジェットステップは 6.5 後に追加） |
| 8 | ローカライズ + プライバシー | App Store 申請に必要なメタ整備 | ✅ 完了 |
| 9 | リリース | TestFlight → 本番審査通過 | ⏳ 手作業（`docs/RELEASE_CHECKLIST.md`） |

各 Phase は **直前の Phase のテストが緑であること** を条件に着手。

---

## Phase 0 — プロジェクト基盤

- [x] iOS deployment target = **26.4**
- [x] Bundle ID = **`niki.kibun-log`** / Team = **`4L2W8Y4RLS`**
- [x] CI 雛形（`.github/workflows/ci.yml`、`xcodebuild test` を macOS 15 + Xcode 26 で）
- [x] テンプレート由来の `Item.swift` を削除、`ContentView.swift` を置換
- [ ] **手作業**: Xcode capability 追加（Apple Developer Portal）
- [ ] **手作業**: CloudKit Container `iCloud.niki.kibun-log` 作成
- [ ] **手作業**: AdMob アカウント作成・iOS アプリ登録
- [ ] **手作業**: StoreKit プロダクトを App Store Connect で確定

→ 詳細は `docs/RELEASE_CHECKLIST.md` セクション A〜D。

---

## Phase 1 — データモデル + 記録フロー ✅

- [x] `MoodEntry` モデル定義（CloudKit 互換の既定値付与）
- [x] `SleepSource` 列挙型（`healthKit` / `manual`）
- [x] `MoodRepository`（同一論理日 upsert を含む CRUD）
- [x] `LogicalDay` / `StreakCalculator`（純関数）
- [x] 記録画面 `EntryView`
  - [x] 気分スライダー（赤→緑グラデーション）
  - [x] 「10/5/0」ラベル常時表示
  - [x] 睡眠時間 Stepper
  - [x] 保存 → upsert
- [x] ストリーク表示（柔らかめ文言）
- [x] ユニットテスト（同一論理日 upsert / ストリーク）

---

## Phase 2 — HealthKit 統合 ✅

- [x] `SleepProvider` プロトコル + Environment 注入
- [x] `HealthKitSleepProvider`（`HKSampleQueryDescriptor` で async 取得）
- [x] 前夜の集計（前日 18:00 〜 当日 12:00、`asleepCore` + `Deep` + `REM` + `Unspecified`）
- [x] 取得失敗時のフォールバック → 手動入力
- [x] source バッジ（HealthKit 自動 / 手動）
- [x] 手動上書きで source = manual に切替
- [x] `SleepAggregator` のユニットテスト

---

## Phase 3 — 可視化 ✅

- [x] Swift Charts でダブル折れ線（気分 + 睡眠）— **2 段表示**で実装
- [x] 7 日移動平均の重ね描画
- [x] 移動平均 ON/OFF トグル
- [x] 期間切替（1 週 / 1 ヶ月 / 3 ヶ月 / 1 年）
- [x] 月次サマリー（最高気分 / 最低気分の曜日）
- [x] 空データ時のプレースホルダー
- [x] `MovingAverage` / `WeekdayMoodAggregator` のユニットテスト

---

## Phase 4 — 通知 ✅

- [x] `NotificationScheduler`（リクエスト / スケジュール / キャンセル）
- [x] `UNCalendarNotificationTrigger` で毎日リマインダー
- [x] `NotificationDelegate`（タップで EntryView へ deep link）
- [x] 設定画面で時刻変更
- [x] `SeasonalReminderPresets`（季節別の文言、Phase 8 で追加）

---

## Phase 5 — 課金 + 広告 ✅（AdMob SDK 統合は手作業）

- [x] `ProductIDs` 定数
- [x] `EntitlementStore`（@Observable, Transaction.currentEntitlements 監視）
- [x] `PurchaseView`（3 プラン + 復元）
- [x] App Store Connect で 3 プロダクト作成 — **手作業**
- [x] `BannerSlot`（Pro なら hidden、無料はプレースホルダー）
- [x] `Configuration.storekit`（ローカルテスト用）
- [ ] **手作業**: scheme に StoreKit Configuration を紐付け
- [ ] **手作業**: Google Mobile Ads SDK を SPM で追加し `BannerSlot` を実装で置換

---

## Phase 6 — 補助機能 ✅（ウィジェットは Phase 6.5）

- [x] `AuthService`（LocalAuthentication ラッパー）
- [x] `LockController` + `LockedView`
- [x] アプリロック ON/OFF を AppStorage 永続化
- [x] scenePhase 観察で active 復帰時に再ロック
- [x] CloudKit 同期を `cloudKitDatabase: .automatic` で有効化
- [x] 設定画面に iCloud 情報行

---

## Phase 6.5 — ホームウィジェット ⏳（手作業）

- [ ] **手作業**: Xcode で Widget Extension ターゲットを追加（`dailio-jpWidget`）
- [ ] App Group `group.niki.kibun-log` を共有
- [ ] 直近 7 日のミニグラフ（Small / Medium）
- [ ] WidgetKit `TimelineProvider` で SwiftData を再クエリ

→ `docs/RELEASE_CHECKLIST.md` セクション E-3。

---

## Phase 7 — オンボーディング ✅

- [x] `OnboardingFlags` / `OnboardingStep`
- [x] `OnboardingView`（プログレス + 戻る + スキップ）
- [x] 5 ステップ: Welcome / HealthKit / Notifications / Tutorial / Complete
- [x] 完了 → ContentView へ自動遷移
- [ ] ウィジェット追加ガイド（Phase 6.5 完了後にステップを 6 つ目として追加）

---

## Phase 8 — ローカライズ + プライバシー ✅

- [x] `Localizable.xcstrings` 整備、ja 一次・en 全エントリ翻訳済
- [x] `docs/PRIVACY.md` / `docs/TERMS.md`（GitHub Pages 公開想定）
- [x] `docs/STORE_LISTING.md`（タイトル / 説明 / キーワード / プロモ / 価格戦略）
- [x] `SeasonalReminderPresets`（春の不調 / 五月病 / 梅雨 / 夏バテ / 冬季）
- [ ] **手作業**: アプリアイコン作成（1024×1024）
- [ ] **手作業**: スクリーンショット撮影（4 サイズ）
- [ ] **手作業**: App Privacy（収集データ申告）
- [ ] **手作業**: GitHub Pages の有効化

---

## Phase 9 — リリース ⏳（手作業）

`docs/RELEASE_CHECKLIST.md` の F〜H を順に消化:
- TestFlight 内部 / 外部テスト（10〜20 名）
- App Store 審査提出
- 想定リジェクト対応 1〜2 サイクル
- 公開後モニタリング

---

## スコープ外（v1.1 以降）

issue の **Phase 2** はリリース後に切り出す:
- 散布図（睡眠 × 気分の相関、Pro 限定）
- 移動平均期間カスタム（3 / 14 / 30 / 90 日）
- PDF レポートエクスポート
- AI 振り返り
- Apple Watch コンプリ + ワンタップ入力
- PMS / 生理周期連動
- テーマカスタマイズ
- CSV エクスポート

---

## 確定済み事項

| 項目 | 決定 |
|---|---|
| iOS deployment target | **26.4** |
| Bundle ID / Team | `niki.kibun-log` / `4L2W8Y4RLS` |
| スライダー UI | 赤→緑 グラデーション |
| 数字ラベル | 10=最高 / 5=普通 / 0=最悪 を表示 |
| ストリーク | 表示あり（文言は柔らかめ） |
| v1.0 スコープ | issue MVP のみ。issue Phase 2 は v1.1 以降に切り出し |
