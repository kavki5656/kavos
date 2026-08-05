# Ticket Reservation API

## 概要
一時的な高負荷を想定したチケット予約APIの学習用プロジェクト。
Go/MySQL/Dockerでアプリケーションを実装して、AWS上の実行基盤をTerraformで構築しています。

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

### 起動

```bash
cd ticket-reserve-api
docker-compose up -d --build
```

>初回起動時のみ`init.sql`が実行されます。スキーマを変更した場合は `docker compose down -v` でボリュームごと削除してください。

### エンドポイント

**ヘルスチェック**

```bash
$ curl -i http://localhost:8080/health
HTTP/1.1 200 OK
Date: Wed, 05 Aug 2026 05:51:34 GMT
Content-Length: 2
Content-Type: text/plain; charset=utf-8

OK
```

**チケット一覧**

```bash
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
```

**予約**

```bash
$ curl -i -X POST http://localhost:8080/reserve \
> -H "Content-Type: application/json" \
> -d '{"ticket_id":"T001","amount":1}'
HTTP/1.1 200 OK
Content-Type: application/json
Date: Tue, 04 Aug 2026 22:38:45 GMT
Content-Length: 38

{"message":"Reservation successful!"}
```

### 同時実行時の在庫整合性

**在庫5枚のチケットに7回リクエスト → 200が5回、409が2回。**

```bash
$ for i in $(seq 1 7); do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8080/reserve \
    -H "Content-Type: application/json" \
    -d '{"ticket_id":"T002","amount":1}'
done
200
200
200
200
200
409
409
```

**20並列でリクエスト → 20件すべて成功し、在庫はちょうど20減少。**

```bash
$ seq 1 20 | xargs -P 20 -I{} curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST http://localhost:8080/reserve \
  -H "Content-Type: application/json" \
  -d '{"ticket_id":"T001","amount":1}'
200
200
200
200
200
200
200
200
200
200
200
200
200
200
200
200
200
200
200
200
```

## 技術選定の理由（8/6）

## 設計上のトレードオフ（8/7）

## 今後の展望（8/7）
