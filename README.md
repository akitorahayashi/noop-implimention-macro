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

## 動作環境

*   **Swift:** 5.9 以上
*   **Platforms:**
    *   macOS: 10.15 以上
    *   iOS: 13 以上
    *   tvOS: 13 以上
    *   watchOS: 6 以上
    *   macCatalyst: 13 以上

## 注意事項

*   **`associatedtype`:** `associatedtype` を含むプロトコルのサポートは制限される場合があります。
*   **デフォルト値が自動生成されない型:** 一部の複雑な型（引数付きクロージャ、`Result` 等）は、自動でデフォルト値が生成されません。該当するメソッドやプロパティを呼び出すと、意図的にエラー（`fatalError` または `NoopError`）が発生します。これを避けるには `overrides` パラメータで値を指定してください。

## 対応しているデフォルト値

以下の型に対しては、自動的にデフォルト値が生成されます。これらの値は `overrides` パラメータで上書き可能です。

*   基本的な数値型 (`Int`, `Double`, `Float`, etc.): `0`
*   `String`: `""`
*   `Bool`: `false`
*   `Array`: `[]`
*   `Dictionary`: `[:]`
*   `Optional`: `nil`
*   `() -> Void` 型のクロージャ: `{}`
*   シンプルなイニシャライザを持つ型: `Type()`

## 利用方法

1.  **パッケージの追加:**
    Swift Package Manager を利用して、このマクロをプロジェクトに追加します。

    ```swift
    // Package.swift
    dependencies: [
        // 最新版を利用する場合は main ブランチを指定
        .package(url: "https://github.com/terrio32/noop-implimention-macro", branch: "main")
        // または、特定のバージョン範囲を指定
        // .package(url: "https://github.com/terrio32/noop-implimention-macro", from: "1.1.1") // 例: v1.1.1 を使う場合
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

2.  **マクロの適用:**
    No-Op実装を生成したいプロトコルの前 `@NoopImplementation` を付与します。
    `overrides` パラメータに `[型名文字列: 値]` の形式で辞書リテラルを渡すことで、特定の型のデフォルト値をカスタマイズできます。
    (注: マクロは型チェック前にコードの構文に基づいて動作するため、型名は `"String"` や `"URL"` のように文字列リテラルで指定する必要があります。`String.self` のような形式はマクロ引数として直接使用できません。)

    ```swift
    import NoopImplementation // マクロ定義を含むモジュールをインポート
    import Foundation // URL など Foundation 型を使う場合

    // 基本的な使い方
    @NoopImplementation
    protocol MyServiceProtocol {
        func fetchData() -> String?
        func performAction(with value: Int)
    }

    // デフォルト値をカスタマイズする例
    @NoopImplementation(overrides: [
        "String": "\"Overridden String\"",
        "Int": 100,
        "URL": URL(string: "https://custom.example.com")!,
        "[String]": "[\"A\", \"B\"]" // 配列なども文字列キーで指定
    ])
    protocol CustomizedService {
        func getMessage() -> String
        var identifier: Int { get }
        var endpoint: URL { get }
        var tags: [String] { get }
        var standardValue: Bool { get } // これは標準の false
    }
    ```

3.  **インスタンスの利用:**
    生成されたクラス (Noop + プロトコル名) のインスタンスを直接初期化して利用します。

    ```swift
    let dummyService: MyServiceProtocol = NoopMyServiceProtocol()
    let customService: CustomizedService = NoopCustomizedService()

    print(dummyService.fetchData()) // nil (Optionalのデフォルト)
    print(customService.getMessage()) // "Overridden String"
    print(customService.identifier) // 100
    print(customService.tags) // ["A", "B"]
    print(customService.standardValue) // false
    ```