# bashweb server

## 概要
これはbashだけでいい感じに動くWebフレームワークです。

## できること
こんなことができます。
- HTTP/1.0への不完全な対応
- わかりやすいrouting設定ファイルの記述
- 分離されたController, Viewの利用
- Mustacheを使用したViewの記述
- 静的ファイル（バイナリファイル含む）の配信
- POST、PUTされたFormデータの受け取り
- テキストファイルを用いたデータの永続化
- いい感じのログ出力
- 同時アクセス

## 動作を確認した環境
OS: Mac OS Catalina 10.15.5  
Bash: GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin19)

## 準備
`curl`、`shasum`、Python 3を利用できるようにしてください。HTTP処理本体はBashで、Python標準ライブラリの小さなTCPランチャーが外部入力のサイズと処理時間を制限します。

## dependency install
テンプレートエンジンとして使用している[Mustache Templates in Bash](https://github.com/tests-always-included/mo)、及び[tcpserver](http://cr.yp.to/ucspi-tcp/tcpserver.html)をインストールします。
```sh
$ ./bashweb.sh install
```

## Server start
```sh
$ ./bashweb.sh start
```

初期状態では外部公開を避けるため、`127.0.0.1:8080`だけで待ち受けます。変更する場合は`BIND_ADDRESS`と`PORT`を指定します。

```sh
BIND_ADDRESS=127.0.0.1 PORT=8081 ./bashweb.sh start
```

このリポジトリはBashでHTTPの仕組みを学ぶための実験用です。TLS、認証、堅牢なHTTPパーサーを備えた本番用Webサーバーとしては使用しないでください。

## 使い方

### routing設定

`/route.sh` でroutingの設定を行います。
書式は以下。
```sh
route [HTTP method] [route] [controller method]
```

#### example
```sh
#!/bin/bash
route get / main_show
route post /rip rip_create
```

### controller

`/controller`配下に配置したシェルスクリプトはすべて読み込まれます。  
ここに定義した関数はrouting設定ファイルに従って呼ばれます。  
ファイル名はコントローラの動作に影響ありません。  
定義する関数名は全体で一意にしてください。

コントローラーの関数の最後では必ずresponse関数を呼び出してください。  
response関数の書式は以下です。
```sh
response [HTTP status] [view file name]
```
引数はすべて省略可能です。（省略した場合は、 `[HTTP status]` : `200` 、 `[view file name]` : `関数名` と解釈されます）

`[view file name]` には拡張子を含めないでください。

#### example
```sh
#!/bin/bash
rip_show() {
  declare -r NAME=hoge
  response 200 rip
}

rip_list() {
  response
}
```


### view

mustache形式でテンプレートを `/view` 配下に配置します。  
mustacheについては[こちら](https://mustache.github.io/)  
ここではcontrollerで定義済みの変数が全て使用できます。  
bash3の制約により、連想配列は使用できません。

尚、404.mustacheはrouting設定・静的ファイルのどちらにも該当するものがない場合に呼ばれるテンプレートです。

#### example
```html
<!DOCTYPE html>
<html>
<head>
  <title>page</title>
</head>
<body>
  <h1>Hello, {{NAME}}さん！</h1>
</body>
</html>
```

### static file

画像や静的ページを配置することができます。

### log

`/log` 配下にログが吐き出されます。  
出力されるログレベルは、`DEBUG`、`INFO`、`WARN`、`ERROR`の4種類です。  
`/config`でどのレベルのログを出力するか設定することができます。

## テスト

外部入力がシェルコードとして実行されないこと、フォーム解析、ルーティング、静的ファイルのパストラバーサル防止を確認します。

```sh
bash tests/security.sh
find . -path './vendor' -prune -o -name '*.sh' -type f -exec bash -n {} +
```
