from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import pyodbc, os

app = FastAPI(title="SecureApp To-Do API", version="1.0")

DB_SERVER = os.getenv("DB_SERVER", "${db_server}")
DB_NAME = os.getenv("DB_NAME", "${db_name}")
DB_USER = os.getenv("DB_USER", "${db_user}")
DB_PASS = os.getenv("DB_PASS", "${db_pass}")

def get_db():
    return pyodbc.connect(
        f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={DB_SERVER};DATABASE={DB_NAME};UID={DB_USER};PWD={DB_PASS};Encrypt=yes;TrustServerCertificate=no;"
    )

@app.on_event("startup")
def startup():
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='todos' AND xtype='U') CREATE TABLE todos (id INT IDENTITY(1,1) PRIMARY KEY, title NVARCHAR(200) NOT NULL, description NVARCHAR(500), completed BIT DEFAULT 0, created_at DATETIME DEFAULT GETDATE())")
        conn.commit()
        conn.close()
        print("Database connected and table ready!")
    except Exception as e:
        print(f"Database connection failed: {e}")

class TodoCreate(BaseModel):
    title: str
    description: Optional[str] = None

class TodoUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    completed: Optional[bool] = None

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/api/todos")
def get_todos():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id, title, description, completed, created_at FROM todos ORDER BY created_at DESC")
    rows = cursor.fetchall()
    conn.close()
    return [{"id": r[0], "title": r[1], "description": r[2], "completed": bool(r[3]), "created_at": str(r[4])} for r in rows]

@app.post("/api/todos")
def create_todo(todo: TodoCreate):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO todos (title, description) VALUES (?, ?)", todo.title, todo.description)
    conn.commit()
    cursor.execute("SELECT @@IDENTITY")
    new_id = int(cursor.fetchone()[0])
    conn.close()
    return {"id": new_id, "title": todo.title, "description": todo.description, "completed": False}

@app.put("/api/todos/{todo_id}")
def update_todo(todo_id: int, todo: TodoUpdate):
    conn = get_db()
    cursor = conn.cursor()
    updates, params = [], []
    if todo.title is not None: updates.append("title = ?"); params.append(todo.title)
    if todo.description is not None: updates.append("description = ?"); params.append(todo.description)
    if todo.completed is not None: updates.append("completed = ?"); params.append(1 if todo.completed else 0)
    if not updates: raise HTTPException(status_code=400, detail="Nothing to update")
    params.append(todo_id)
    cursor.execute(f"UPDATE todos SET {', '.join(updates)} WHERE id = ?", *params)
    if cursor.rowcount == 0: conn.close(); raise HTTPException(status_code=404, detail="Todo not found")
    conn.commit()
    conn.close()
    return {"message": "Updated successfully"}

@app.delete("/api/todos/{todo_id}")
def delete_todo(todo_id: int):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM todos WHERE id = ?", todo_id)
    if cursor.rowcount == 0: conn.close(); raise HTTPException(status_code=404, detail="Todo not found")
    conn.commit()
    conn.close()
    return {"message": "Deleted successfully"}