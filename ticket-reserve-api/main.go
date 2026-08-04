package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

// １．データ構造（Struct）の定義
type Ticket struct {
	ID		string `json:"id"`
	Title		string `json:"title"`
	Price		int	`json:"price"`
	Available	int	`json:"available"`
}

type ReserveRequest struct {
	TicketID string `json:"ticket_id"`
	Amount	int `json:"amount"`
}

// ２．ハンドラー関数の定義（リクエストを受け取って返す処理）
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func getTicketsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	rows, err := db.Query("SELECT id, title, price, available FROM tickets")
	if err != nil {
		log.Printf("DBクエリエラー: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tickets []Ticket

	for rows.Next() {
		var t Ticket

		if err := rows.Scan(&t.ID, &t.Title, &t.Price, &t.Available); err != nil {
			log.Printf("データ読み込みエラー: %v", err)
			http.Error(w, "Data processing error", http.StatusInternalServerError)
			return
		}
		tickets = append(tickets, t)
	}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(tickets); err != nil {
		http.Error(w, "Failed to encode tickets", http.StatusInternalServerError)
		return
	}
}

// ３．ミドルウェア（SREの要：アクセスログ出力）
func loggingMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		next.ServeHTTP(w, r)

		log.Printf("[%s] %s (took %v)", r.Method, r.URL.Path, time.Since(start))
	}
}

func reserveTicketHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ReserveRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	
	if req.TicketID == "" {
		http.Error(w, "ticket_id is required", http.StatusBadRequest)
		return
	}

	result, err := db.Exec("UPDATE tickets SET available = available - 1 WHERE id = ? AND available > 0", req.TicketID)
	if err != nil {
		log.Printf("DB更新エラー: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("行数取得エラー: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if rowsAffected == 0 {
		http.Error(w, "Ticket not found or sold out", http.StatusConflict)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Reservation successful!"})
	return
}

// ４．メイン関数（サーバーの起動）
func main() {
	http.HandleFunc("/health", loggingMiddleware(healthCheckHandler))
	http.HandleFunc("/tickets", loggingMiddleware(getTicketsHandler))
	http.HandleFunc("/reserve", loggingMiddleware(reserveTicketHandler))

	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	dbHost := os.Getenv("DB_HOST")
	dbName := os.Getenv("DB_NAME")

	dsn := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s", dbUser, dbPass, dbHost, dbName)

	var err error
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("DB接続設定エラー: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("DB疎通エラー（ping失敗）: %v", err)
	}
	log.Println("データベースへの接続に成功しました！")

	port := os.Getenv("PORT")

	if port == "" {
		port = "8080"
	}

	log.Printf("Server is starting on port %s...", port)

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
