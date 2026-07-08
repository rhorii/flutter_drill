# 改善アイデア一覧

コードベース全体（`lib/main.dart`、`lib/responsive_utils.dart`、`test/widget_test.dart`、アセット構成）をレビューして洗い出した改善点です。優先度順に整理しています。

## 1. バグ・不具合（優先度: 高）

### 1-1. `TextEditingController` と `AudioPlayer` が dispose されていない
`_DrillViewState` に `dispose()` がなく、`_controller` と `_player` が解放されないためリソースリークになる。

```dart
@override
void dispose() {
  _controller.dispose();
  if (widget.audioPlayer == null) {
    _player.dispose(); // 自分で生成した場合のみ解放
  }
  super.dispose();
}
```

### 1-2. 正解しても同じ問題が連続で出ることがある
`_randomIndex()` は単純な `Random().nextInt()` のため、正解直後に同じ問題が再抽選されうる。問題数が2問以上のときは直前の index を除外すべき。

```dart
int _nextIndex() {
  if (widget.drills.length <= 1) return 0;
  int next;
  do {
    next = _random.nextInt(widget.drills.length);
  } while (next == _index);
  return next;
}
```

### 1-3. ドリルが空のときにクラッシュする
CSV が空（または該当パスの読み込み結果が0件）だと `Random().nextInt(0)` が例外を投げる。`DrillPage` 側で空リスト時のガード（「問題がありません」表示など）が必要。

### 1-4. 不正な CSV 行でクラッシュする
`row[0]` / `row[1]` を検証なしで参照しているため、列が足りない行や空行があると `RangeError` になる。行のバリデーション（列数チェック、スキップまたはエラー表示）を追加する。

### 1-5. `FutureBuilder` の future を `build()` 内で生成している
`DrillCollectionListPage` / `DrillPage` は `StatelessWidget` で、`build()` のたびに `_loadDrills()` / `_loadDrillCollections()` の新しい Future が作られる。親のリビルドでアセットの再読み込みと画面のチラつきが起きる。`StatefulWidget` にして `initState` で Future を保持するか、読み込み済みデータをキャッシュする。

### 1-6. 不正解時の効果音が `await` されていない
正解時は `await _player.play(...)` だが不正解時は fire-and-forget で、連打すると再生が重なる。挙動を揃え、再生中の多重再生を防ぐ（もしくは `AudioPlayer` を正解用・不正解用で分ける）。

## 2. 判定ロジックの改善（優先度: 高）

### 2-1. 全角数字・前後空白で不正解になる
判定が `_controller.text == _currentDrill().answer` の完全一致のみ。日本語IMEで「１２」と全角入力した場合や前後に空白が入った場合に不正解扱いになる。子ども向けアプリとしては正規化（全角→半角変換、`trim()`）してから比較すべき。

```dart
String _normalize(String s) => s.trim().replaceAllMapped(
      RegExp(r'[０-９]'),
      (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0xFEE0),
    );
```

### 2-2. `_isNumeric` の判定と入力制限が噛み合っていない
`double.tryParse` で数値判定しているが、入力側は `digitsOnly`（整数のみ）。将来「3.5」や負数が答えの問題を追加すると入力できなくなる。当面は `int.tryParse` に揃えるのが正確。

## 3. UX・機能改善（優先度: 中〜高）

### 3-1. 正誤の視覚的フィードバックがない
現状は効果音のみ。音が出せない環境（ミュート、電車内）では正誤が分からない。◯／✕ のオーバーレイ表示や色の変化などの視覚フィードバックを追加する。

### 3-2. 「1回のセッション」の概念がない
問題が無限にランダム出題されるだけで、終わりも成績もない。以下のような形にすると学習アプリとして成立する：

- 1セット10問などの出題数を決め、終了時に結果画面（正答数・かかった時間）を表示
- 間違えた問題を後で再出題（弱点復習）
- 連続正解数（ストリーク）や履歴の保存（`shared_preferences`）

### 3-3. キーボードの Enter で回答できない
`TextField` に `onSubmitted` がなく、必ずボタンをタップする必要がある。`onSubmitted` で判定処理を呼び、`autofocus: true` にして正解後もフォーカスを維持すると回答テンポが大きく改善する。

### 3-4. 子ども向けの数字キーパッド
低学年向けにはシステムキーボードより、画面内に大きな 0〜9 のカスタムキーパッドを置いたほうが操作しやすい（誤タップ・キーボード切り替え問題も回避できる）。

### 3-5. 効果音のミュート設定
設定画面またはアプリバーにミュートトグルを追加する。

### 3-6. 不正解時のヒント・答え表示
何度か間違えたら答えを表示して次に進める仕組み（詰まり防止）。

## 4. コード構成（優先度: 中）

### 4-1. `main.dart` にすべて詰まっている
310行に App / モデル / ページ / ビューが同居している。次のような分割を推奨：

```
lib/
  main.dart
  models/drill.dart            # Drill, DrillCollection
  repositories/drill_repository.dart  # JSON/CSV 読み込み
  pages/drill_collection_list_page.dart
  pages/drill_page.dart
  widgets/drill_view.dart
  responsive_utils.dart
```

### 4-2. データ読み込みロジックがウィジェットに埋め込まれている
`rootBundle` からの JSON / CSV 読み込みを `DrillRepository` に切り出すと、テストで実アセットを使わずにモックでき、エラーハンドリングも一元化できる。

### 4-3. Material 3 への移行
`primarySwatch` は旧 API。`ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true)` へ移行し、ついでにダークモード対応（`darkTheme`）も検討。

### 4-4. エラー表示が生の英語メッセージ
`Text('Error: ${snapshot.error}')` は利用者（子ども）に見せる文言として不適切。「よみこみに しっぱいしました」＋再試行ボタンのようなエラーUIにする。

### 4-5. モデルの堅牢化
`DrillCollection.fromJson` はキー欠落時に実行時エラーになる。バリデーション付きにし、`==` / `hashCode` / `toString` も定義するとテストしやすい。

## 5. テスト・CI（優先度: 中）

### 5-1. CI がない
`.github/workflows` が存在しない。GitHub Actions で push / PR ごとに以下を実行する：

```yaml
- flutter pub get
- dart format --set-exit-if-changed .
- flutter analyze
- flutter test
```

### 5-2. 非推奨 API を使ったテスト
`tester.binding.window.physicalSizeTestValue` は deprecated。`tester.view.physicalSize` / `tester.view.devicePixelRatio` に移行する。

### 5-3. テストの重複を整理
画面サイズ設定の3行が多くのテストにコピペされている。ヘルパー関数か `setUp` に集約する。

### 5-4. 実アセットに対するバリデーションテスト
`assets/drill_collections.json` の全パスが実在すること、全 CSV が2列で答えが正しいこと（例: `1+1=` → `2` を実際に計算して検証）を確認するテストを追加すると、ドリル追加時の事故を防げる。

## 6. その他（優先度: 低）

- **README が雛形のまま**: アプリの概要、スクリーンショット、ドリルの追加方法（JSON/CSV の書式）を記載する。
- **pubspec の description が雛形のまま**: `A new Flutter project.` を実態に合わせる。
- **アプリ名**: Android の `applicationId` が `com.example.flutter_drill` のまま。ストア公開するなら変更が必要。
- **多言語化**: UI 文言がハードコードされている。現状日本語のみで問題ないが、`flutter_localizations` 導入の余地あり。
- **CSV の動的生成**: たしざん・かけざんの問題は規則的なので、CSV アセットではなくコードで生成する選択肢もある（アセット管理が不要になる一方、CSV 方式は非算数ドリルへの拡張性があるためトレードオフ）。

## 推奨する着手順

1. **リソースリーク修正**（1-1）と**空・不正データのガード**（1-3, 1-4）— 小さくて効果が大きい
2. **回答判定の正規化**（2-1）と**同一問題の連続出題防止**（1-2）— 体感品質に直結
3. **CI 導入**（5-1）— 以降の変更の安全網
4. **セッション化と結果画面**（3-2）＋**視覚フィードバック**（3-1）— 機能面の本命
5. **コード分割**（4-1, 4-2）— 機能追加の前提整備
