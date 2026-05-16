# プライバシーポリシー / Privacy Policy

最終更新日 / Last Updated: 2026-05-15

## 概要 / Summary

dailio（以下「本アプリ」）は、ユーザーの気分と睡眠データを記録するためのツールです。本アプリは**メンタルヘルスに関わるデータの取り扱いに最大限の配慮**を行い、第三者へのデータ送信を一切行いません。

dailio (the "App") is a tool for recording mood and sleep data. Because this is mental health data, we treat it with extra care and **never transmit your records to any third party**.

---

## 収集するデータ / Data We Collect

| 項目 | 用途 | 保管場所 | 第三者送信 |
|---|---|---|---|
| 気分スコア（0〜10） | グラフ表示・統計 | 端末内 + ユーザーの iCloud | しない |
| 睡眠時間 | グラフ表示・相関分析 | 端末内 + ユーザーの iCloud | しない |
| HealthKit 睡眠データ | 睡眠時間の自動取込 | 端末内処理のみ | しない |
| 通知設定 | リマインダー時刻 | 端末内 + ユーザーの iCloud | しない |
| 課金状態 | 機能解放判定 | Apple StoreKit | StoreKit 経由のみ |
| 広告識別子（無料版のみ） | AdMob バナー表示 | AdMob | Google AdMob のみ |

| Item | Purpose | Storage | Sent to third party |
|---|---|---|---|
| Mood (0–10) | Charts and stats | On-device + your iCloud | Never |
| Sleep hours | Charts and correlation | On-device + your iCloud | Never |
| HealthKit sleep | Auto-import sleep | Local processing only | Never |
| Reminder settings | Notification time | On-device + your iCloud | Never |
| Purchase state | Pro feature unlock | Apple StoreKit | StoreKit only |
| Ad ID (free tier) | AdMob banner | AdMob | Google AdMob only |

## クラウド同期 / Cloud Sync

記録は Apple の iCloud（あなた専用の Container `iCloud.niki.kibun-log`）に同期されます。Apple のプライバシーポリシーに従い、Apple や本アプリ開発者を含む第三者は内容を閲覧できません。同期を停止するには iOS 設定 > Apple ID > iCloud から dailio をオフにしてください。

Records sync to your private iCloud container (`iCloud.niki.kibun-log`). Per Apple's privacy policy, no one—including Apple or the developer—can read the contents. To stop syncing, disable dailio in iOS Settings > Apple ID > iCloud.

## HealthKit

本アプリは HealthKit から「睡眠分析（Sleep Analysis）」のみを**読み取り**ます。HealthKit データはサーバ送信されず、デバッグログにも一切残しません。

The app **reads only Sleep Analysis** from HealthKit. HealthKit data is never sent to any server and never written to logs.

## 広告 / Advertising

無料版には Google AdMob のバナー広告（記録画面下部のみ）を表示します。AdMob はパーソナライズドまたは非パーソナライズド広告のために、IDFA（広告 ID）と一般的な利用情報を収集することがあります。Pro プランでは広告を完全に非表示にし、AdMob SDK 自体も呼び出されません。

The free tier shows a Google AdMob banner at the bottom of the entry screen. AdMob may collect IDFA and basic usage data for personalized or non-personalized ads. The Pro plan hides ads entirely and does not load the AdMob SDK.

AdMob のデータ取り扱いについては Google のプライバシーポリシーをご参照ください: https://policies.google.com/privacy

For AdMob's data practices, see Google's privacy policy: https://policies.google.com/privacy

## データのセキュリティ / Security

- 端末内データは iOS の Data Protection（`NSFileProtectionComplete` 相当）で暗号化されます
- 任意で Face ID / Touch ID / パスコードによるアプリロックを有効化できます
- iCloud 同期は Apple の暗号化通信を使います

- Local data is encrypted with iOS Data Protection
- Optional Face ID / Touch ID / passcode lock is available
- iCloud sync uses Apple's encrypted transport

## ユーザーの権利 / Your Rights

- 全データの削除: iOS 設定 > 一般 > iPhone ストレージ > dailio > App を削除
- iCloud 上のデータ削除: iOS 設定 > Apple ID > iCloud > データの管理 > dailio
- 課金の取消: iOS 設定 > Apple ID > サブスクリプション

- Delete all data: iOS Settings > General > iPhone Storage > dailio > Delete App
- Delete iCloud data: iOS Settings > Apple ID > iCloud > Manage Account Storage > dailio
- Cancel subscription: iOS Settings > Apple ID > Subscriptions

## お問い合わせ / Contact

本ポリシーに関するお問い合わせは GitHub Issues までお願いします: https://github.com/a-yuto/dailio-jp

For questions about this policy, please file an issue at https://github.com/a-yuto/dailio-jp.
