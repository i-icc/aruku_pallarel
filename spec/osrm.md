# OSRM データ/イメージ運用

## 目的
- OSM/OSRM サービスを東京データ入りのカスタムイメージで運用する
- Cloud Run では OSRM の `nearest` API を利用する

## データソース
- BBBike Tokyo extract を既定の入力データとする  
  `https://download.bbbike.org/osm/bbbike/Tokyo/Tokyo.osm.pbf`
- 取得元は `OSRM_PBF_URL` で差し替え可能

## データ配置
- 生成データは `tmp/osrm` 配下に置く（git 管理しない）
- `tmp/osrm/<basename>.osrm*` がイメージに内包される

## 再現手順（Make）
```bash
make osrm-download
make osrm-build
make osrm-image
make osrm-push
```

主な変数:
- `OSRM_BASENAME` (default: `tokyo`)
- `OSRM_PBF_URL` (default: BBBike Tokyo)
- `OSRM_BASE_IMAGE` (default: `ghcr.io/project-osrm/osrm-backend:v6.0.0`)
- `OSRM_IMAGE` (ローカルは `osrm-tokyo:latest`、push 時は GAR を指定)
- `OSRM_IMAGE_PLATFORM` (default: `linux/amd64`)

## Cloud Run での起動
- カスタムイメージの entrypoint が `osrm-routed` を起動する
- `PORT` を利用して 8080 で待ち受ける
- Terraform の `osm_image` は GAR イメージを指定する
- Cloud Run は `linux/amd64` を想定するため、イメージは `OSRM_IMAGE_PLATFORM=linux/amd64` でビルドする

## API 利用
- `GET /nearest/v1/driving/{lon},{lat}?number=1`
- `waypoints[0].location` の `[lon, lat]` を採用する
