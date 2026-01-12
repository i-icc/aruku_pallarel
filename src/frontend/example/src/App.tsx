import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import Onboarding from './components/Onboarding';
import Login from './components/Login';
import Home from './components/Home';
import WalkingMap from './components/WalkingMap';
import Chat from './components/Chat';
import History from './components/History';
import Settings from './components/Settings';

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isFirstTime, setIsFirstTime] = useState(true);

  useEffect(() => {
    // Check if user has visited before
    const hasVisited = localStorage.getItem('hasVisited');
    const authToken = localStorage.getItem('authToken');
    
    if (hasVisited) {
      setIsFirstTime(false);
    }
    
    if (authToken) {
      setIsAuthenticated(true);
    }
  }, []);

  const handleLogin = () => {
    setIsAuthenticated(true);
    localStorage.setItem('authToken', 'mock-token');
  };

  const handleSignup = () => {
    setIsAuthenticated(true);
    setIsFirstTime(false);
    localStorage.setItem('authToken', 'mock-token');
    localStorage.setItem('hasVisited', 'true');
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    localStorage.removeItem('authToken');
  };

  return (
    <Router>
      <div className="min-h-screen bg-gray-50">
        <Routes>
          <Route 
            path="/onboarding" 
            element={
              !isAuthenticated && isFirstTime ? (
                <Onboarding onComplete={handleSignup} />
              ) : (
                <Navigate to="/home" replace />
              )
            } 
          />
          <Route 
            path="/login" 
            element={
              !isAuthenticated ? (
                <Login onLogin={handleLogin} />
              ) : (
                <Navigate to="/home" replace />
              )
            } 
          />
          <Route 
            path="/home" 
            element={
              isAuthenticated ? (
                <Home />
              ) : (
                <Navigate to={isFirstTime ? "/onboarding" : "/login"} replace />
              )
            } 
          />
          <Route 
            path="/walk" 
            element={
              isAuthenticated ? (
                <WalkingMap />
              ) : (
                <Navigate to="/login" replace />
              )
            } 
          />
          <Route 
            path="/chat/:walkId" 
            element={
              isAuthenticated ? (
                <Chat />
              ) : (
                <Navigate to="/login" replace />
              )
            } 
          />
          <Route 
            path="/history" 
            element={
              isAuthenticated ? (
                <History />
              ) : (
                <Navigate to="/login" replace />
              )
            } 
          />
          <Route 
            path="/settings" 
            element={
              isAuthenticated ? (
                <Settings onLogout={handleLogout} />
              ) : (
                <Navigate to="/login" replace />
              )
            } 
          />
          <Route 
            path="*" 
            element={
              <Navigate to={
                isAuthenticated 
                  ? "/home" 
                  : isFirstTime 
                    ? "/onboarding" 
                    : "/login"
              } replace />
            } 
          />
        </Routes>
      </div>
    </Router>
  );
}
