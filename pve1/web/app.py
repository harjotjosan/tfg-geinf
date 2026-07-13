import os
from flask import Flask, render_template, request
import psycopg2
from psycopg2.extras import DictCursor

app = Flask(__name__)


def get_conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "carparts"),
        user=os.getenv("DB_USER", "carparts_user"),
        password=os.getenv("DB_PASSWORD", "carparts_pass"),
    )


@app.route("/")
def index():
    q = request.args.get("q", "").strip()
    category = request.args.get("category", "").strip()

    # Detect SQL Injection patterns
    q_lower = q.lower()
    if "union" in q_lower or "select" in q_lower or "--" in q_lower:
        print("[SECURITY] SQL Injection attempt detected", flush=True)

    sql_injection_vulnerable = os.getenv("SQL_INJECTION_VULNERABLE", "").lower() == "true"

    if sql_injection_vulnerable:
        escaped_q = q.replace("%", "%%")
        query = f"SELECT part_number, name, category, manufacturer, stock, unit_price, compatibility FROM car_parts WHERE ('{escaped_q}' = '' OR name ILIKE '%%{escaped_q}%%' OR part_number ILIKE '%%{escaped_q}%%') AND (%(category)s = '' OR category = %(category)s) ORDER BY name;"
        params = {"category": category}
    else:
        query = """
            SELECT part_number, name, category, manufacturer, stock, unit_price, compatibility
            FROM car_parts
            WHERE (%(q)s = '' OR name ILIKE %(like_q)s OR part_number ILIKE %(like_q)s)
              AND (%(category)s = '' OR category = %(category)s)
            ORDER BY name;
        """
        params = {"q": q, "like_q": f"%{q}%", "category": category}

    categories_query = "SELECT DISTINCT category FROM car_parts ORDER BY category;"

    try:
        with get_conn() as conn:
            with conn.cursor(cursor_factory=DictCursor) as cur:
                cur.execute(query, params)
                parts = cur.fetchall()
                cur.execute(categories_query)
                categories = [row[0] for row in cur.fetchall()]
        db_ok = True
        error = None
    except Exception as exc:  # pragma: no cover
        print(f"[ERROR] Database query execution failed: {exc}", flush=True)
        parts = []
        categories = []
        db_ok = False
        error = str(exc)

    return render_template(
        "index.html",
        parts=parts,
        categories=categories,
        selected_category=category,
        q=q,
        db_ok=db_ok,
        error=error,
    )


@app.get("/health")
def health():
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1;")
        return {"status": "ok"}, 200
    except Exception as exc:  # pragma: no cover
        return {"status": "error", "detail": str(exc)}, 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
