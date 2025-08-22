const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection configuration
const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'counterdb',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
});

// Initialize database table
async function initializeDatabase() {
    try {
        await pool.query(`
      CREATE TABLE IF NOT EXISTS counter (
        id SERIAL PRIMARY KEY,
        count INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

        // Check if we have a counter record, if not create one
        const result = await pool.query('SELECT * FROM counter WHERE id = 1');
        if (result.rows.length === 0) {
            await pool.query('INSERT INTO counter (id, count) VALUES (1, 0)');
            console.log('📊 Counter table initialized with starting value 0');
        }

        console.log('✅ Database initialized successfully');
    } catch (error) {
        console.error('❌ Error initializing database:', error.message);
        process.exit(1);
    }
}

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'counter-backend'
    });
});

app.post("/api/increment/:count", async (req, res) => {
    const { count } = req.params;
    await pool.query(`UPDATE counter SET count = count + ${count} WHERE id = 1`);
    res.json({ message: `Count incremented by ${count}` });
});

// Get current count
app.get('/api/count', async (req, res) => {
    try {
        const result = await pool.query('SELECT count FROM counter WHERE id = 1');
        const count = result.rows[0]?.count || 0;

        console.log(`📖 Current count retrieved: ${count}`);
        res.json({ count });
    } catch (error) {
        console.error('❌ Error fetching count:', error.message);
        res.status(500).json({
            error: 'Failed to fetch count',
            message: error.message
        });
    }
});

// Increment count
app.post('/api/increment', async (req, res) => {
    try {
        const result = await pool.query(`
      UPDATE counter 
      SET count = count + 1, updated_at = CURRENT_TIMESTAMP 
      WHERE id = 1 
      RETURNING count
    `);

        const newCount = result.rows[0].count;
        console.log(`🔢 Count incremented to: ${newCount}`);

        res.json({ count: newCount });
    } catch (error) {
        console.error('❌ Error incrementing count:', error.message);
        res.status(500).json({
            error: 'Failed to increment count',
            message: error.message
        });
    }
});

// Reset count (for testing purposes)
app.post('/api/reset', async (req, res) => {
    try {
        await pool.query(`
      UPDATE counter 
      SET count = 0, updated_at = CURRENT_TIMESTAMP 
      WHERE id = 1
    `);

        console.log('🔄 Count reset to 0');
        res.json({ count: 0, message: 'Counter reset successfully' });
    } catch (error) {
        console.error('❌ Error resetting count:', error.message);
        res.status(500).json({
            error: 'Failed to reset count',
            message: error.message
        });
    }
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Endpoint not found',
        path: req.originalUrl
    });
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('💥 Unhandled error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: error.message
    });
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('🛑 Shutting down gracefully...');
    await pool.end();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('🛑 Shutting down gracefully...');
    await pool.end();
    process.exit(0);
});

// Start server
async function startServer() {
    try {
        await initializeDatabase();

        app.listen(port, '0.0.0.0', () => {
            console.log(`🚀 Counter Backend API running on http://0.0.0.0:${port}`);
            console.log(`🐘 Connected to PostgreSQL database`);
            console.log(`📋 Available endpoints:`);
            console.log(`   GET  /health - Health check`);
            console.log(`   GET  /api/count - Get current count`);
            console.log(`   POST /api/increment - Increment count`);
            console.log(`   POST /api/reset - Reset count to 0`);
        });
    } catch (error) {
        console.error('❌ Failed to start server:', error.message);
        process.exit(1);
    }
}

startServer();
