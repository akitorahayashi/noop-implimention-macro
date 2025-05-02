# Noop Implementation Macro

## 概要

`@NoopImplementation` は、Swiftプロトコルに準拠した「何もしない（No-Op）」実装を自動生成するためのSwiftマクロです。
主に以下の目的で利用します

*   SwiftUIの `.preview` における依存性の注入
*   開発中やプレースホルダー状態での一時的な依存性の注入
*   依存性注入における副作用のない代替実装の提供

## 設計方針

`@NoopImplementation` マクロは、適用されたプロトコルに対して以下の要素を生成します。

1.  **No-Opクラス** プロトコルに準拠する `Noop{プロトコル名}` という名前のクラス。ただし、元のプロトコル名が `Protocol` で終わる場合は、その `Protocol` を除いた名前になります (例: `MyServiceProtocol` -> `NoopMyService`)。
    *   **メソッド** 空の実装。
    *   **プロパティ** 型に基づいたデフォルト値。
        *   `Bool` は `false`
        *   `Int` は `0`
        *   `String` は `""`
        *   `Optional` は `nil`
        *   その他 `.init()` またはコンパイラが推論可能なデフォルト値（詳細は[注意点・設計上の懸念](#⚠️-注意点設計上の懸念)参照）。
2.  **静的アクセサ (デフォルト)** 元のプロトコルに対する `extension` として `static var noop: Self { Noop{プロトコル名}() }` を生成し、`.noop` で簡単にアクセス可能にします。

```swift
@NoopImplementation
protocol LoggerProtocol {
    func log(_ message: String)
    func error(_ message: String) -> Bool
}

// 以下が自動生成される
class NoopLogger: LoggerProtocol {
    func log(_ message: String) {}
    func error(_ message: String) -> Bool { false }
}

extension LoggerProtocol {
    static var noop: LoggerProtocol {
        NoopLogger()
    }
}
```

## 技術スタック

**言語:** Swift
**主要技術:** Swift Macros
**依存性管理:** Swift Package Manager (SPM)

## 主要機能と利用メリット

`@NoopImplementation` は、特に以下のシーンで開発効率とコードの簡潔性を向上させます。

*   **SwiftUIプレビュー**
    *   副作用のないダミー依存性を即座に注入できます。
    *   プレビューのための冗長なコード記述が不要になります。
    *   軽量なため、Viewの描画パフォーマンスへの影響を最小限に抑えられます。
*   **開発中の仮実装**
    *   まだ実装されていない機能や外部依存を、一時的にNo-Op実装で置き換えられます。
*   **テスト**
    *   明示的なモックやスパイが不要で、単に「何もしない」依存性が必要な場合に便利です。
*   **メモリ・パフォーマンス**
    *   メソッド呼び出しの記録などを行わないため、非常に軽量です。

## `@Mockable` / `@Spyable` との違い

`@NoopImplementation` は、テスト用のモック生成マクロ（例: `@Mockable`, `@Spyable`）とは目的が異なります。

| 比較項目             | `@Mockable` | `@Spyable` | `@NoopImplementation` |
| :------------------- | :---------- | :--------- | :-------------------- |
| 呼び出し記録         | ○           | ○          | ❌                    |
| 戻り値のカスタマイズ   | ○           | △          | ❌（固定値）          |
| テスト              | ◎           | ◎          | △（開発・プレビュー向き） |
| プレビュー          | △           | ×          | ◎                    |
| 軽量さ               | ×           | ×          | ◎                    |

## ⚠️ 注意点・拡張案

**現在の注意点と設計上の懸念**

*   **複雑な戻り値** メソッドの返り値が複雑な型（例: クロージャ、`Result<T, E>`）の場合、自動生成されるデフォルト値が適切でない可能性があります。デフォルト値の戦略（例: `fatalError`, `TypeName.init()`, 空実装）は検討が必要です。
*   **`associatedtype`** プロトコルが `associatedtype` を持つ場合、現在のマクロ実装では対応に制限があるか、警告を表示する必要があるかもしれません。
*   **未対応の型** 戻り値を持つメソッドが、マクロがデフォルト値を推論できない型を返す場合、コンパイルエラーになるか、特定のフォールバック戦略（例: `fatalError`）が必要です。

**将来的な拡張案・発展方向**

*   **`static` アクセサの制御** `@NoopImplementation(generateStaticAccessor: false)` のように、`.noop` アクセサの生成をON/OFFできるオプション。
*   **ビルド構成限定** `@NoopImplementation(forPreviewOnly: true)` のように、デバッグビルド（または特定のビルド構成）でのみコードを生成するオプション。
*   **デフォルト値戦略の指定** `@NoopImplementation(defaultReturnStrategy: .zero / .fatal / .empty)` のように、デフォルト値の生成方法を選択できるオプション。

## 利用方法

Swift Package Manager を利用して、このマクロをプロジェクトに追加します。

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/terrio32/noop-implimention-macro", from: "1.0.0")
],
targets: [
    .target(
        name: "YourAppTarget",
        dependencies: [
            .product(name: "NoopImplementationMacro", package: "noop-implementation-macro")
        ]
    )
    // ... 他のターゲット
]
```

No-Op実装を生成したいプロトコルの前 `@NoopImplementation` を付与します。

```swift
import NoopImplementationMacro // マクロ定義を含むモジュールをインポート

@NoopImplementation
protocol MyServiceProtocol {
    func fetchData() -> String?
    func performAction(with value: Int)
}

// これで NoopMyService クラスと MyServiceProtocol.noop が利用可能になる
let dummyService: MyServiceProtocol = .noop
let specificInstance = NoopMyService()
```
