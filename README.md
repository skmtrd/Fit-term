# Fit-term

**自分だけのキーボードを組み立てる、iOS向けSSHクライアント**

Fit-term は、キーボード拡張エリアのカスタマイズ性に特化した iOS 向け SSH クライアントアプリです。iPhoneの純正キーボードでは送信できない Escape, Control, 矢印キーなどの特殊キーを、自分好みに配置・カスタマイズして使うことができます。

## Features

### Customizable Keyboard Extension Area

キーボードの上部にグリッドベースの拡張エリアを配置。ボタンの種類・位置・サイズ・色を自由にカスタマイズできます。

- **キーアクションボタン**: Escape, Tab, Ctrl+C, Shift+Tab などをワンタップで送信
- **スニペットボタン**: よく使うコマンドをワンタップで実行
- **グリッドレイアウト**: 段数・列数を自由に調整
- **ボタンのカスタマイズ**: ラベル・色を自由に設定

### Snippets

任意のコマンドをスニペットとして登録し、ワンタップで SSH セッションに送信できます。

### Multi-Session Tabs

複数のサーバーに同時接続し、タブで切り替えて操作できます。同時接続数に制限はありません。

### Connection Profiles

接続先サーバーの情報を保存し、一覧からワンタップで接続。プロファイルの複製機能で、同一サーバーへの複数設定も効率的に作成できます。

### Terminal Appearance

- 10種のカラープリセット（Dracula, Nord, Tokyo Night, Catppuccin Mocha など）
- フォント選択（SF Mono, JetBrains Mono, Fira Code, Source Code Pro, IBM Plex Mono）
- フォントサイズ・背景色・文字色のカスタム設定

## Tech Stack

- **UI**: SwiftUI
- **SSH**: [Citadel](https://github.com/orlandos-nl/Citadel) (Swift-NIO SSH)
- **Terminal Emulation**: [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) (xterm-256color)
- **Data Persistence**: SwiftData
- **Credential Storage**: Keychain

## Requirements

- iOS 17+
- iPhone

## License

TBD
