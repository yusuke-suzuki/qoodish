# OpenTelemetry Collector Config

このディレクトリにある `collector-config.yaml` は OpenTelemetry Collector の設定ファイルです。
Cloud Run にサイドカーとしてデプロイするために、この設定ファイルを Secret Manager に登録する必要があります。

## Secret Manager への登録

以下のコマンドを実行して、`collector-config.yaml` を Secret Manager に登録します。
`$PROJECT_ID` は対象の Google Cloud プロジェクト ID に置き換えてください。

### シークレットの作成 (初回のみ)

```bash
gcloud secrets create QOODISH_OTELCOL_CONFIG --data-file=otelcol-google/collector-config.yaml --project=$PROJECT_ID
```

### シークレットの更新

設定ファイルを更新した場合は、以下のコマンドで新しいバージョンを追加します。

```bash
gcloud secrets versions add QOODISH_OTELCOL_CONFIG --data-file=otelcol-google/collector-config.yaml --project=$PROJECT_ID
```
