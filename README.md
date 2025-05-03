# Noop Implementation Macro

## 概要

`@NoopImplementation` は、何もしない（No-Op）実装を自動生成するためのマクロです

## 主要機能

`@NoopImplementation` は、特に以下のシーンで利用できます

*   **SwiftUIプレビュー**
    *   副作用のない依存性を注入できます
    *   プレビューのためのコード記述を削減できます
    *   軽量なため、Viewの描画パフォーマンスへの影響を抑えることができます
*   **テスト**
    *   明示的なモックやスパイを用意せず、単に「何もしない」依存性が必要な場合に役立ちます
*   **メモリ・パフォーマンス**
    *   メソッド呼び出しの記録などを行わないため、軽量です


## `@Mockable` / `@Spyable` との違い

`@NoopImplementation` は、テスト用のモック生成マクロ（例: `@Mockable`, `@Spyable`）とは目的が異なります

| 比較項目             | `@Mockable` | `@Spyable` | `@NoopImplementation` |
| :------------------- | :---------- | :--------- | :-------------------- |
| 呼び出し記録         | ○           | ○          | ❌                    |
| 戻り値のカスタマイズ   | ○           | △          | ❌（固定値）          |
| テスト              | ◎           | ◎          | △（開発・プレビュー向き） |
| プレビュー          | △           | ×          | ◎                    |
| 軽量さ               | ×           | ×          | ◎                    |

## ディレクトリ構成

```
.
├── .github/
│   └── workflows/
├── .gitignore
├── Package.swift
├── Package.resolved
├── README.md
├── Sources/
│   ├── NoopImplementation/
│   ├── NoopImplementationClient/
│   └── NoopImplementationMacros/
└── Tests/
    └── NoopImplementationTests/
```

### 主要ディレクトリの役割

*   `Sources/NoopImplementationMacros/`: マクロの **実装** (コード生成ロジック)
*   `Sources/NoopImplementation/`: マクロの **定義** と公開 (利用者が使うインターフェース)
*   `Sources/NoopImplementationClient/`: マクロの **利用例** (動作確認用サンプル)

## 技術スタック

**言語:** Swift
**主要技術:** Swift Macros
**依存性管理:** Swift Package Manager (SPM)

## 注意事項

*   **デフォルト値:** 複雑な型（クロージャ、`Result` 等）やイニシャライザのない型に対するデフォルト値の自動生成は限定的で、`fatalError` になる可能性があります

*   **`associatedtype`:** `associatedtype` を含むプロトコルのサポートは制限される場合があります

## 利用方法

Swift Package Manager を利用して、このマクロをプロジェクトに追加します

```swift
// Package.swift
dependencies: [
    // 最新版を利用する場合は main ブランチを指定
    .package(url: "https://github.com/terrio32/noop-implimention-macro", branch: "main")
    // または、特定のバージョン範囲を指定
    // .package(url: "https://github.com/terrio32/noop-implimention-macro", from: "1.0.0")
],
targets: [
    .target(
        name: "YourAppTarget",
        dependencies: [
            .product(name: "NoopImplementation", package: "noop-implementation-macro")
        ]
    )
]
```

No-Op実装を生成したいプロトコルの前 `@NoopImplementation` を付与します

```swift
import NoopImplementation // マクロ定義を含むモジュールをインポート

@NoopImplementation
protocol MyServiceProtocol {
    func fetchData() -> String?
    func performAction(with value: Int)
}

// NoopMyServiceProtocol クラスのインスタンスを直接初期化して利用します
let dummyService: MyServiceProtocol = NoopMyServiceProtocol()

let specificInstance = NoopMyServiceProtocol()
```