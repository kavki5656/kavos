USE ticket_db;

-- 1. テーブルの作成
CREATE TABLE IF NOT EXISTS tickets (
	id VARCHAR(10) PRIMARY KEY,
	title VARCHAR(100) NOT NULL,
	price INT NOT NULL,
	available INT NOT NULL
);

-- 2. 初期データの投入
INSERT IGNORE INTO tickets (id, title, price, available) VALUES
	('T001', 'Cirque du Soleil Tokyo', 15000, 42),
	('T002', 'Lion King', 12000, 5);
