import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { AppProvider } from './src/context/AppContext';
import HomeScreen from './src/screens/HomeScreen';
import MemoryScreen from './src/screens/MemoryScreen';
import SettingsScreen from './src/screens/SettingsScreen';

const Tab = createBottomTabNavigator();

function getTabIcon(routeName, focused) {
  const icons = {
    Home: focused ? 'chatbubble-ellipses' : 'chatbubble-ellipses-outline',
    Memories: focused ? 'brain' : 'brain-outline',
    Settings: focused ? 'settings' : 'settings-outline',
  };
  return icons[routeName] || 'help-circle-outline';
}

export default function App() {
  return (
    <AppProvider>
      <NavigationContainer>
        <Tab.Navigator
          screenOptions={({ route }) => ({
            tabBarIcon: ({ focused, color, size }) => (
              <Ionicons
                name={getTabIcon(route.name, focused)}
                size={size}
                color={color}
              />
            ),
            tabBarActiveTintColor: '#7C4DFF',
            tabBarInactiveTintColor: '#A0896C',
            tabBarStyle: {
              backgroundColor: '#FFF8E7',
              borderTopColor: '#E8DCC8',
            },
            headerStyle: {
              backgroundColor: '#7C4DFF',
            },
            headerTintColor: '#FFF',
            headerTitleStyle: {
              fontWeight: '700',
            },
          })}
        >
          <Tab.Screen
            name="Home"
            component={HomeScreen}
            options={{
              title: 'AniMind',
              headerTitle: '🐣 AniMind',
            }}
          />
          <Tab.Screen
            name="Memories"
            component={MemoryScreen}
            options={{
              title: 'Memories',
              headerTitle: '🧠 Memories',
            }}
          />
          <Tab.Screen
            name="Settings"
            component={SettingsScreen}
            options={{
              title: 'Settings',
              headerTitle: '⚙️ Settings',
            }}
          />
        </Tab.Navigator>
      </NavigationContainer>
      <StatusBar style="light" />
    </AppProvider>
  );
}
