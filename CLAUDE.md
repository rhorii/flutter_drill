# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

子ども向けの算数ドリルアプリ。足し算・引き算・掛け算の問題をCSV形式で管理し、複数のドリルを組み合わせて出題できる。

## 開発コマンド

```bash
# テスト実行
flutter test

# 単一テストファイル実行
flutter test test/widget_test.dart

# アプリ起動
flutter run

# 依存関係インストール
flutter pub get
```

## アーキテクチャ

### ファイル構成

- `lib/main.dart` - アプリ全体の実装（データクラス、ウィジェット）
- `lib/responsive_utils.dart` - 画面サイズに応じたレスポンシブサイズ計算

### データフロー

1. `assets/drill_collections.json` でドリル集合を定義（タイトルとCSVパスのリスト）
2. 各ドリル集合は複数のCSVファイルを参照可能（問題の組み合わせ）
3. CSVは `問題,回答` の単純な形式
4. 回答が数値の場合は数値キーボード、それ以外は標準キーボードを表示

### レスポンシブ設計

`ResponsiveSizes` クラスが画面短辺を基準にサイズを計算：
- 問題フォント: 短辺の25%（48〜256px）
- 回答フォント: 短辺の20%（40〜256px）
- ボタン/タイトル: 短辺の8%（24〜64px）

### テスト構成

`test/widget_test.dart` に全テストが集約：
- データクラスのユニットテスト
- CSV解析テスト
- ウィジェットテスト（MockAudioPlayerを使用）
- 5種類のデバイスサイズでのレスポンシブテスト
