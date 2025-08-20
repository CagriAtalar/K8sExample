import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

function App() {
    const [count, setCount] = useState(0);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    // Fetch current count on component mount
    useEffect(() => {
        fetchCount();
    }, []);

    const fetchCount = async () => {
        try {
            setLoading(true);
            const response = await axios.get(`${API_URL}/api/count`);
            setCount(response.data.count);
            setError('');
        } catch (err) {
            console.error('Error fetching count:', err);
            setError('Failed to fetch count from server');
        } finally {
            setLoading(false);
        }
    };

    const incrementCount = async () => {
        try {
            setLoading(true);
            const response = await axios.post(`${API_URL}/api/increment`);
            setCount(response.data.count);
            setError('');
        } catch (err) {
            console.error('Error incrementing count:', err);
            setError('Failed to increment count');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="App">
            <div className="container">
                <h1>🔢 Counter App</h1>
                <p className="subtitle">Click the button to increment the counter in PostgreSQL!</p>

                <div className="counter-section">
                    <div className="count-display">
                        <span className="count-label">Current Count:</span>
                        <span className="count-value">{count}</span>
                    </div>

                    <button
                        className="increment-btn"
                        onClick={incrementCount}
                        disabled={loading}
                    >
                        {loading ? '⏳ Processing...' : '➕ Increment Count'}
                    </button>

                    <button
                        className="refresh-btn"
                        onClick={fetchCount}
                        disabled={loading}
                    >
                        🔄 Refresh
                    </button>
                </div>

                {error && (
                    <div className="error-message">
                        ❌ {error}
                    </div>
                )}

                <div className="info">
                    <p>🐘 Backend connected to PostgreSQL</p>
                    <p>☸️ Running on Kubernetes</p>
                </div>
            </div>
        </div>
    );
}

export default App;
