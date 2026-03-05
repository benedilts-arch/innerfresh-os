#!/bin/bash
# finance.sh — Financial tracking for the agent
#
# Usage:
#   finance.sh init
#   finance.sh import <file.csv>
#   finance.sh query "<natural language question>"
#   finance.sh report [pl|balance|expenses|invoices] [--period this-month|last-month|ytd|last-year|YYYY-MM]
#   finance.sh redact "<text>"    — strip dollar amounts from outbound text

DB="${FINANCE_DB:-$HOME/.openclaw/workspace/data/finance.db}"
mkdir -p "$(dirname "$DB")"

sql() { sqlite3 "$DB" "$@"; }

case "$1" in
  init)
    sql "
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income','expense','transfer')),
        category TEXT,
        account TEXT,
        reference TEXT,
        imported_at INTEGER DEFAULT (strftime('%s','now'))
      );
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK(type IN ('asset','liability','equity','income','expense')),
        balance REAL DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT,
        client TEXT,
        amount REAL NOT NULL,
        issued_date TEXT,
        due_date TEXT,
        paid_date TEXT,
        status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','paid','overdue','cancelled'))
      );
      CREATE INDEX IF NOT EXISTS idx_date ON transactions(date);
      CREATE INDEX IF NOT EXISTS idx_type ON transactions(type);
      CREATE INDEX IF NOT EXISTS idx_category ON transactions(category);
    "
    echo "Finance DB initialized: $DB"
    ;;

  import)
    FILE="$2"
    [ -z "$FILE" ] || [ ! -f "$FILE" ] && echo "Error: provide a valid CSV file path" && exit 1

    # Auto-detect file type from headers
    HEADER=$(head -1 "$FILE")
    echo "Detected headers: $HEADER"

    python3 << PYEOF
import csv, sqlite3, os, sys
from datetime import datetime

db = sqlite3.connect("$DB")
file = "$FILE"
imported = 0
skipped = 0

with open(file, newline='', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    headers = [h.lower().strip() for h in reader.fieldnames or []]
    
    # Map common column names
    def find_col(candidates, headers, row):
        for c in candidates:
            if c in headers:
                val = row.get(next(h for h in (row.keys()) if h.lower().strip() == c), '')
                return str(val).strip()
        return ''

    for row in reader:
        try:
            rh = {k.lower().strip(): v for k, v in row.items()}
            date = find_col(['date','transaction date','trans date','posting date'], list(rh.keys()), rh) or ''
            desc = find_col(['description','memo','details','narration','particulars'], list(rh.keys()), rh) or ''
            
            # Amount: try debit/credit columns or single amount
            amount_raw = find_col(['amount','value','sum'], list(rh.keys()), rh)
            debit = find_col(['debit','dr','withdrawal'], list(rh.keys()), rh) or '0'
            credit = find_col(['credit','cr','deposit'], list(rh.keys()), rh) or '0'
            
            if amount_raw:
                amount = float(str(amount_raw).replace(',','').replace('$','').replace('-','').strip() or 0)
                txn_type = 'expense' if '-' in str(amount_raw) else 'income'
            else:
                debit_val = float(str(debit).replace(',','').replace('$','').strip() or 0)
                credit_val = float(str(credit).replace(',','').replace('$','').strip() or 0)
                if debit_val > 0:
                    amount, txn_type = debit_val, 'expense'
                else:
                    amount, txn_type = credit_val, 'income'

            category = find_col(['category','type','account name','account'], list(rh.keys()), rh) or 'uncategorized'
            account = find_col(['account','bank account','account number'], list(rh.keys()), rh) or ''
            reference = find_col(['reference','ref','cheque no','check no','transaction id'], list(rh.keys()), rh) or ''

            if not date or amount == 0:
                skipped += 1
                continue

            db.execute(
                "INSERT OR IGNORE INTO transactions(date,description,amount,type,category,account,reference) VALUES(?,?,?,?,?,?,?)",
                (date, desc, amount, txn_type, category, account, reference)
            )
            imported += 1
        except Exception as e:
            skipped += 1

db.commit()
db.close()
print(f"Imported: {imported} transactions. Skipped: {skipped} rows.")
PYEOF
    ;;

  report)
    REPORT="${2:-pl}"
    PERIOD="${4:-this-month}"

    # Period SQL
    case "$PERIOD" in
      this-month)  DATE_FILTER="date >= strftime('%Y-%m-01','now') AND date <= strftime('%Y-%m-%d','now')" ;;
      last-month)  DATE_FILTER="date >= strftime('%Y-%m-01','now','-1 month') AND date < strftime('%Y-%m-01','now')" ;;
      ytd)         DATE_FILTER="date >= strftime('%Y-01-01','now')" ;;
      last-year)   DATE_FILTER="date >= (strftime('%Y','now')-1)||'-01-01' AND date < strftime('%Y','now')||'-01-01'" ;;
      *)           DATE_FILTER="date >= '$PERIOD-01' AND date <= '$PERIOD-31'" ;;
    esac

    case "$REPORT" in
      pl|pandl)
        echo "=== P&L Report: $PERIOD ==="
        echo "--- Income ---"
        sql "SELECT category, COUNT(*), ROUND(SUM(amount),2) FROM transactions WHERE type='income' AND $DATE_FILTER GROUP BY category ORDER BY SUM(amount) DESC;"
        echo ""
        echo "--- Expenses ---"
        sql "SELECT category, COUNT(*), ROUND(SUM(amount),2) FROM transactions WHERE type='expense' AND $DATE_FILTER GROUP BY category ORDER BY SUM(amount) DESC;"
        echo ""
        INCOME=$(sql "SELECT ROUND(COALESCE(SUM(amount),0),2) FROM transactions WHERE type='income' AND $DATE_FILTER;")
        EXPENSES=$(sql "SELECT ROUND(COALESCE(SUM(amount),0),2) FROM transactions WHERE type='expense' AND $DATE_FILTER;")
        echo "Net: income=$INCOME, expenses=$EXPENSES"
        ;;
      expenses)
        echo "=== Top Expenses: $PERIOD ==="
        sql "SELECT date, description, ROUND(amount,2), category FROM transactions WHERE type='expense' AND $DATE_FILTER ORDER BY amount DESC LIMIT 20;" | column -t -s '|'
        ;;
      invoices)
        echo "=== Open Invoices ==="
        sql "SELECT number, client, ROUND(amount,2), due_date, status FROM invoices WHERE status IN ('open','overdue') ORDER BY due_date ASC;" | column -t -s '|'
        ;;
    esac
    ;;

  redact)
    # Strip dollar amounts from outbound text
    MSG="$2"
    echo "$MSG" | python3 -c "
import sys, re
text = sys.stdin.read()
# Redact dollar amounts
text = re.sub(r'\\\$[\d,]+(\.\d{1,2})?', '[AMOUNT REDACTED]', text)
text = re.sub(r'\b\d{1,3}(,\d{3})*(\.\d{2})?\s*(USD|EUR|AED|GBP)\b', '[AMOUNT REDACTED]', text)
print(text, end='')
"
    ;;

  query)
    QUESTION="$2"
    echo "Financial query: $QUESTION"
    echo "(Route to agent for NL → SQL translation. Raw query access below.)"
    echo ""
    # Quick pattern matching for common queries
    case "${QUESTION,,}" in
      *"revenue"*|*"income"*)
        sql "SELECT ROUND(SUM(amount),2) as total_income, COUNT(*) as txns FROM transactions WHERE type='income';"
        ;;
      *"expense"*)
        sql "SELECT category, ROUND(SUM(amount),2) FROM transactions WHERE type='expense' GROUP BY category ORDER BY SUM(amount) DESC LIMIT 10;" | column -t -s '|'
        ;;
      *"invoice"*)
        bash "$0" report invoices
        ;;
      *)
        echo "Use agent NL query for complex questions."
        ;;
    esac
    ;;

  *)
    echo "Usage: finance.sh {init|import <file>|report [pl|expenses|invoices] [--period <p>]|query <question>|redact <text>}"
    exit 1
    ;;
esac
