import React, { createContext, useContext, useState, useEffect } from 'react';
import * as SecureStore from 'expo-secure-store';
import { getDatabase, getDayCount, updateLastSession } from '../db/database';
import { getGreeting } from '../api/gemini';

const AppContext = createContext(null);

const API_KEY_STORAGE_KEY = 'gemini_api_key';

export function AppProvider({ children }) {
  const [apiKey, setApiKeyState] = useState('');
  const [dayCount, setDayCount] = useState(1);
  const [greeting, setGreeting] = useState('');
  const [dbReady, setDbReady] = useState(false);
  const [mood, setMood] = useState('happy'); // happy, curious, sleepy, excited

  // Initialize everything on mount
  useEffect(() => {
    (async () => {
      try {
        await getDatabase();
        setDbReady(true);

        const days = await getDayCount();
        setDayCount(days);

        const storedKey = await SecureStore.getItemAsync(API_KEY_STORAGE_KEY);
        if (storedKey) {
          setApiKeyState(storedKey);
        }

        await updateLastSession();
      } catch (e) {
        console.error('Init error:', e);
        setDbReady(true); // Continue anyway
      }
    })();
  }, []);

  // Fetch greeting when API key is available and DB is ready
  useEffect(() => {
    if (!dbReady) return;
    (async () => {
      const g = await getGreeting(apiKey);
      setGreeting(g);
    })();
  }, [apiKey, dbReady]);

  const setApiKey = async (key) => {
    const trimmed = key.trim();
    setApiKeyState(trimmed);
    if (trimmed) {
      await SecureStore.setItemAsync(API_KEY_STORAGE_KEY, trimmed);
    } else {
      await SecureStore.deleteItemAsync(API_KEY_STORAGE_KEY);
    }
  };

  // Mood changes based on interaction
  const updateMood = (chatCount) => {
    if (chatCount === 0) setMood('sleepy');
    else if (chatCount < 3) setMood('happy');
    else if (chatCount < 7) setMood('excited');
    else setMood('curious');
  };

  return (
    <AppContext.Provider
      value={{
        apiKey,
        setApiKey,
        dayCount,
        greeting,
        dbReady,
        mood,
        setMood,
        updateMood,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
