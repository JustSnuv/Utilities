const sqlite3 = require("sqlite3").verbose();
const path = require("path");
const fs = require('fs');

const dbPath = path.join(__dirname, "datastore.db");
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) console.error("DB open error:", err);
  else console.log("Database opened.");
});

// Single-table structure, nested objects stored as JSON
const defaultData = {};

const defaultGlobalData = {};

// ------------------ Helpers ------------------
function runAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
}

function getAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

async function syncUserData() {
  // Get all columns that exist in the DB right now
  const pragma = await new Promise((resolve, reject) => {
    db.all(`PRAGMA table_info(users)`, [], (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });

  const existingColumns = pragma.map(r => r.name.toUpperCase());

  // For each key in defaultData, ensure it exists
  for (const [key, value] of Object.entries(defaultData)) {
    if (!existingColumns.includes(key.toUpperCase())) {
      console.log(`[SYNC] Adding missing column: ${key}`);
      let columnType = "TEXT DEFAULT ''";

      if (typeof value === "number") columnType = `INTEGER DEFAULT ${value}`;
      else if (typeof value === "string") columnType = `TEXT DEFAULT '${value}'`;
      else if (typeof value === "boolean") columnType = `INTEGER DEFAULT ${value ? 1 : 0}`;
      else if (typeof value === "object") columnType = `TEXT DEFAULT '{}'`;

      await runAsync(`ALTER TABLE users ADD COLUMN ${key.toLowerCase()} ${columnType}`);
    }
  }

  console.log("[SYNC] User schema synced with defaultData.");
}

// ------------------ Schema ------------------
async function initDB() {
  const columns = ["id TEXT PRIMARY KEY"];
  for (const [key, value] of Object.entries(defaultData)) {
    if (typeof value === "object" && value !== null) {
      columns.push(`${key.toLowerCase()} TEXT DEFAULT '{}'`); // store nested objects as JSON
    } else if (typeof value === "number") {
      columns.push(`${key.toLowerCase()} INTEGER DEFAULT ${value}`);
    } else if (typeof value === "string") {
      columns.push(`${key.toLowerCase()} TEXT DEFAULT '${value}'`);
    } else if (typeof value === "boolean") {
      columns.push(`${key.toLowerCase()} INTEGER DEFAULT ${value ? 1 : 0}`);
    }
  }
  const schema = `CREATE TABLE IF NOT EXISTS users (${columns.join(", ")});`;
  await runAsync(schema);

  // 🔄 Sync schema with defaultData (adds new columns if missing)
  await syncUserData();
}

// ------------------ Create / Get / Set ------------------
async function createUser(userId) {
  await runAsync(`INSERT OR IGNORE INTO users (id) VALUES (?)`, [userId]);
}

async function GetAsync(userId, key) {
  await createUser(userId);
  const row = await getAsync(`SELECT * FROM users WHERE id = ?`, [userId]);
  if (!row) return defaultData[key];

  if (typeof defaultData[key] === "object") {
    return row[key.toLowerCase()] ? JSON.parse(row[key.toLowerCase()]) : defaultData[key];
  } else {
    return row[key.toLowerCase()] ?? defaultData[key];
  }
}

async function SetAsync(userId, newData) {
    await createUser(userId);

    const keys = Object.keys(newData);
    const vals = Object.values(newData).map(v => typeof v === "object" ? JSON.stringify(v) : v);
    const sets = keys.map(k => `${k.toLowerCase()} = ?`).join(", ");
    const sql = `UPDATE users SET ${sets} WHERE id = ?`;
    await runAsync(sql, [...vals, userId]);
}

async function AddToAsync(userId, updates) {
  await createUser(userId); // sicherstellen, dass der User existiert

  const sets = Object.keys(updates)
    .map(key => `${key.toLowerCase()} = ${key.toLowerCase()} + ?`)
    .join(', ');

  const values = [...Object.values(updates), userId];

  const sql = `UPDATE users SET ${sets} WHERE id = ?`;
  await runAsync(sql, values);
}

// ------------------ Extra Queries ------------------
async function GetTopAsync(column) {
  const rows = await new Promise((resolve, reject) => {
    db.all(
      `SELECT id, ${column.toLowerCase()} FROM users ORDER BY ${column.toLowerCase()} DESC LIMIT 10`,
      [],
      (err, rows) => (err ? reject(err) : resolve(rows))
    );
  });
  return rows.map((row) => ({ id: row.id, value: row[column.toLowerCase()] ?? 0 }));
}

async function GetTotalUserCount() {
  const row = await getAsync(`SELECT COUNT(*) as count FROM users`);
  return row.count;
}

async function GetTotalInCirculation(column) {
    const row = await getAsync(`SELECT SUM(${column.toLowerCase()}) as total FROM users`);
    return row?.total ?? 0;
}

// ------------------ Global Helpers ------------------

async function initGlobals() {
  // Create table with a single row (id = 'main') to store bot stats
  const columns = ["id TEXT PRIMARY KEY"];
  for (const [key, value] of Object.entries(defaultGlobalData)) {
    let type = typeof value === "number" ? "INTEGER" : "TEXT";
    columns.push(`${key.toLowerCase()} ${type} DEFAULT ${typeof value === 'number' ? value : "''"}`);
  }
  
  await runAsync(`CREATE TABLE IF NOT EXISTS globals (${columns.join(", ")});`);
  await runAsync(`INSERT OR IGNORE INTO globals (id) VALUES ('main')`);
}

/**
 * Get a global bot stat
 */
async function GetGlobalAsync(key) {
  const row = await getAsync(`SELECT ${key.toLowerCase()} FROM globals WHERE id = 'main'`);
  return row ? row[key.toLowerCase()] : defaultGlobalData[key];
}

/**
 * Increment a global bot stat (e.g., commands_used)
 */
async function AddToGlobalAsync(updates) {
  const sets = Object.keys(updates)
    .map(key => `${key.toLowerCase()} = ${key.toLowerCase()} + ?`)
    .join(', ');
  const values = [...Object.values(updates)];
  await runAsync(`UPDATE globals SET ${sets} WHERE id = 'main'`, values);
}

/**
 * Directly set a global value (e.g., setting a global event multiplier)
 */
async function SetGlobalAsync(newData) {
  for (const [key, value] of Object.entries(newData)) {
    await runAsync(`UPDATE globals SET ${key.toLowerCase()} = ? WHERE id = 'main'`, [value]);
  }
}

// ------------------ Remove User ------------------
async function removeUser(userId) {
    return new Promise((resolve, reject) => {
        db.run(`DELETE FROM users WHERE id = ?`, [userId], function(err) {
            if (err) return reject(err);
            resolve(`User ${userId} removed successfully.`);
        });
    });
}


// ------------------ Backup / Restore ------------------
async function CreateBackup(name) {
    if (!name) throw new Error("Backup name is required");
    const backupPath = path.join(__dirname, `${name}.db`);
    return new Promise((resolve, reject) => {
        fs.copyFile(dbPath, backupPath, (err) => {
            if (err) reject(err);
            else resolve(`Backup created: ${backupPath}`);
        });
    });
}

async function LoadBackup(name) {
    if (!name) throw new Error("Backup name is required");
    const backupPath = path.join(__dirname, `${name}.db`);
    return new Promise((resolve, reject) => {
        fs.access(backupPath, fs.constants.F_OK, (err) => {
            if (err) return reject(`Backup not found: ${backupPath}`);
            
            db.close((closeErr) => {
                if (closeErr) return reject(closeErr);
                
                // Overwrite current DB with backup
                fs.copyFile(backupPath, dbPath, (copyErr) => {
                    if (copyErr) return reject(copyErr);
                    
                    // Reopen database
                    db = new sqlite3.Database(dbPath, (openErr) => {
                        if (openErr) reject(openErr);
                        else resolve(`Backup loaded: ${backupPath}`);
                    });
                });
            });
        });
    });
}

module.exports = {
  // User Exports
  GetAsync,
  SetAsync,
  AddToAsync,
  GetTopAsync,
  GetTotalUserCount,
  GetTotalInCirculation,
  
  // Global Bot-Exclusive Exports
  GetGlobalAsync,
  SetGlobalAsync,
  AddToGlobalAsync,
  
  // Utility
  CreateBackup,
  LoadBackup,
  removeUser,

  // Startup
  initDB, initGlobals
};
