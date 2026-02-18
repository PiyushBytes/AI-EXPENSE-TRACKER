import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [message, setMessage] = useState('')

  useEffect(() => {
    fetch('http://localhost:8000/')
      .then(response => response.json())
      .then(data => setMessage(data.message))
      .catch(error => console.error('Error fetching data:', error))
  }, [])

  return (
    <div className="App">
      <h1>React + FastAPI</h1>
      <div className="card">
        <p>
          Backend says: {message || 'Loading...'}
        </p>
      </div>
    </div>
  )
}

export default App
