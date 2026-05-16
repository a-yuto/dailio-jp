# dailio-jp リリース手作業チェックリスト

CLI で完結しない、ユーザー手作業の項目を順序立てて記載。
各項目はそれ以降の作業の前提になっているので、**上から順に消化**することを推奨。

---

## A. Apple Developer Portal 設定

- [ ] **App ID 登録**: Bundle ID `niki.kibun-log` を Identifiers から登録
- [ ] **Capability 有効化** (App ID 編集画面)
  - [ ] HealthKit
  - [ ] iCloud (CloudKit)
  - [ ] Push Notifications（リマインダー以外でも将来用）
  - [ ] In-App Purchase
  - [ ] App Groups
- [ ] **App Group 作成**: `group.niki.kibun-log`（ウィジェット用、Phase 6.5 で使用）
- [ ] **iCloud Container 作成**: `iCloud.niki.kibun-log`（CloudKit Dashboard でスキーマ初回保存）

## B. AdMob

- [ ] [AdMob](https://admob.google.com/) でアカウント作成
- [ ] iOS アプリ登録 → AdMob App ID 取得
- [ ] バナー広告ユニット作成 → Banner Unit ID 取得
- [ ] 取得した App ID と Banner Unit ID を共有（Phase 5b で実装に取り込む）

## C. App Store Connect

- [ ] アプリ登録（プラットフォーム iOS、Bundle ID `niki.kibun-log`、SKU = 任意）
- [ ] **In-App Purchase 3 つ作成**
  - [ ] `niki.kibun-log.pro.monthly` 自動更新サブスク ¥200/月
  - [ ] `niki.kibun-log.pro.yearly` 自動更新サブスク ¥1,980/年
  - [ ] `niki.kibun-log.pro.lifetime` 非消耗型 ¥4,980
  - [ ] サブスクリプショングループは「Pro」1 つにまとめる
- [ ] App Privacy（収集データ申告）
  - [ ] 「データを収集していない」フォーム
  - [ ] AdMob 経由の Identifiers / Usage Data を申告
- [ ] **アプリアイコン**（1024×1024 PNG、角丸なし、背景不透明）を `Assets.xcassets/AppIcon` に配置
- [ ] **スクリーンショット**を `docs/STORE_LISTING.md` のリストに従って撮影
  - サイズ: 6.7"（1290×2796）, 6.5"（1242×2688）, 5.5"（1242×2208）, iPad 13"（2064×2752）
- [ ] **ストア説明文**を `docs/STORE_LISTING.md` から貼付
- [ ] **キーワード / プロモーションテキスト**設定
- [ ] **サポート URL / プライバシー URL** を GitHub Pages の URL で設定

## D. GitHub Pages（プライバシー / 利用規約のホスティング）

- [ ] リポジトリ設定 > Pages > Source = `main` ブランチ `docs/` フォルダ
- [ ] `docs/PRIVACY.md` と `docs/TERMS.md` がそれぞれ
  - `https://a-yuto.github.io/dailio-jp/PRIVACY.html`（または `.md`）
  - `https://a-yuto.github.io/dailio-jp/TERMS.html`（または `.md`）
  でアクセスできることを確認

## E. Xcode 側の手作業

### E-1. Configuration.storekit を scheme に紐付け
- [ ] Xcode > Edit Scheme > Run > Options
- [ ] StoreKit Configuration: `dailio-jp/StoreKit/Configuration.storekit` を選択

### E-2. Google Mobile Ads SDK 追加（AdMob 統合時）
- [ ] File > Add Package Dependencies
- [ ] `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
- [ ] `Info.plist` に `GADApplicationIdentifier` = AdMob App ID を追加
- [ ] `BannerSlot.swift` を `GADBannerView` ラッパーに置換

### E-3. Widget Extension 追加（Phase 6.5）
- [ ] File > New > Target > Widget Extension
  - Product Name: `dailio-jpWidget`
  - Bundle ID: `niki.kibun-log.widget`
- [ ] App Group `group.niki.kibun-log` を main ターゲットと widget の両方で有効化
- [ ] Widget 側で SwiftData の `ModelContainer` を共有 App Group の URL に向ける

### E-4. アプリアイコン配置
- [ ] `dailio-jp/Assets.xcassets/AppIcon.appiconset` に 1024 + 全サイズを配置

## F. TestFlight

- [ ] Xcode > Product > Archive
- [ ] Distribute App > App Store Connect > Upload
- [ ] App Store Connect > TestFlight タブ
  - [ ] 内部テストグループに自分を追加して動作確認
  - [ ] 外部テストグループ作成（10〜20 名募集）
  - [ ] 1 週間モニタリング: 入力継続率、Pro 転換率、クラッシュレポート

## G. 申請

- [ ] App Store Connect > 「審査へ提出」
- [ ] **想定リジェクト対応バッファ 1〜2 サイクル**
  - HealthKit 利用目的の説明文確認
  - 課金プランの自動更新条件の明示
  - プライバシー収集データの正確性
  - メンタル健康関連表現が「医療機器・診断ツールではない」旨を含んでいるか

## H. 公開後

- [ ] AdMob eCPM、無料 → Pro 転換率、退会率を 1 週間モニタリング
- [ ] クラッシュフリー率 99.5% 以上を確認
- [ ] レビュー対応（特に最初の 100 ダウンロード分）

---

## 参考

- 価格戦略・コピーライティング: `docs/STORE_LISTING.md`
- プライバシーポリシー: `docs/PRIVACY.md`
- 利用規約: `docs/TERMS.md`
- 実装ロードマップ: `IMPLEMENTATION_PLAN.md`
