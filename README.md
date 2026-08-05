# Ticket Reservation API

## 概要
Docer Composeを利用して構築した、GoとMySQLによるチケット予約システムのローカル環境です。
Go,MySQL,Dockerで実装して、AWS上の実行基盤をTerraformで構築しています
学習目的で構築している環境です。

## 現在のスコープ
| レイヤ | 状態 |
|---|---|
| アプリケーション（Go + MySQL） | Docker Compose でローカル動作。動作確認済み |
| AWSインフラ（Terraform） | VPC / ALB / ECS Fargate / Aurora MySQL まで構築・apply確認済み。**現在は削除済み** |
| アプリのAWSデプロイ | **未実装**。ECSタスク定義は動作確認用のコンテナを起動する構成のまま |

## 構成

```mermaid
graph TB
    Internet([Internet])

    subgraph VPC["VPC 10.0.0.0/16"]
        subgraph Public["Public Subnets (1a / 1c)"]
            ALB["ALB<br/>Listener :80"]
            NAT["NAT Gateway<br/>(1a only)"]
        end

        subgraph Private["Private Subnets (1a / 1c)"]
            ECS["ECS Fargate<br/>0.25 vCPU / 512MB"]
            DB[("Aurora MySQL<br/>db.t4g.medium")]
        end
    end

    Internet --> ALB
    ALB -->|":8080"| ECS
    ECS -->|":3306"| DB
    ECS -.->|"egress"| NAT
```

## ディレクトリ構成

```
.
├── *.tf                    # AWSインフラ定義（Terraform）
│   ├── main.tf             # VPC / サブネット / ルーティング
│   ├── security_group.tf   # ALB / ECS / DB のセキュリティグループ
│   ├── alb.tf              # ALB / ターゲットグループ / リスナー
│   ├── ecs.tf              # ECSクラスター / タスク定義 / サービス
│   └── df.tf               # Aurora MySQL クラスター
└── ticket-reserve-api/     # アプリケーション
    ├── main.go
    ├── init.sql
    ├── Dockerfile
    └── docker-compose.yml
```

## 動作確認
①ヘルスチェック

②チケット一覧
$ curl -s http://localhost:8080/tickets | jq
[
  {
    "id": "T001",
    "title": "Cirque du Soleil Tokyo",
    "price": 15000,
    "available": 42
  },
  {
    "id": "T002",
    "title": "Lion King",
    "price": 12000,
    "available": 5
  }
]

③予約
$ curl -i -X POST http://localhost:8080/reserve \
> -H "Content-Type: application/json" \
> -d '{"ticket_id":"T001","amount":1}'
HTTP/1.1 200 OK
Content-Type: application/json
Date: Tue, 04 Aug 2026 22:38:45 GMT
Content-Length: 38

{"message":"Reservation successful!"}


## 技術選定の理由（8/6）

## 設計上のトレードオフ（8/7）

## 今後の展望（8/7）

## 起動手順
1. リポジトリをクローンする
2. 以下のコマンドを実行する
    `docker-compose up -d --build`
3. http://localhost:8080/tickets にアクセスしてデータが返るか確認する
