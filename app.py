import os
from flask import Flask, jsonify, render_template
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

# Connection helper to talk to Supabase
def get_db_connection():
    conn = psycopg2.connect(
        host="db.tfcvzfmkfhmblqcycfbm.supabase.co",
        database="postgres",
        user="postgres",
        password="Shubhlabh0305",  # <-- Change this to your actual Supabase password!
        port="5432"
    )
    return conn

# Route 1: The API endpoint that fetches cohort data
@app.route('/api/cohort-data')
def get_cohort_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Pull data directly from our online PostgreSQL View!
        cursor.execute("SELECT * FROM vw_cohort_retention;")
        results = cursor.fetchall()
        
        cursor.close()
        conn.close()
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Route 2: Render our HTML dashboard file
@app.route('/')
def home():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)