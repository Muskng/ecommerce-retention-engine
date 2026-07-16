import os
from flask import Flask, jsonify, render_template
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

# Connection helper pointing to the correct Mumbai Pooler
def get_db_connection():
    conn = psycopg2.connect(
        host="aws-1-ap-south-1.pooler.supabase.com", 
        database="postgres",
        user="postgres.tfcvzfmkfhmblqcycfbm",        
        password="Shubhlabh0305",                    
        port="6543"                                  
    )
    return conn

# Route 1: The API endpoint that fetches cohort data
@app.route('/api/cohort-data')
def get_cohort_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("SELECT * FROM vw_cohort_retention;")
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# NEW Route 2: The Beautiful, Professional Landing Page
@app.route('/')
def home():
    return render_template('index.html')

# NEW Route 3: The Dedicated Analytics Dashboard Page
@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')

if __name__ == '__main__':
    app.run(debug=True)