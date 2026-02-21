import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Linking,
  ScrollView,
} from 'react-native';
import { useApp } from '../context/AppContext';

export default function SettingsScreen() {
  const { apiKey, setApiKey, dayCount } = useApp();
  const [keyInput, setKeyInput] = useState(apiKey);
  const [saved, setSaved] = useState(false);

  const handleSave = async () => {
    await setApiKey(keyInput);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const handleClear = () => {
    Alert.alert('Clear API Key', 'Remove your stored API key?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Clear',
        style: 'destructive',
        onPress: async () => {
          setKeyInput('');
          await setApiKey('');
        },
      },
    ]);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* API Key Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Gemini API Key</Text>
        <Text style={styles.sectionDesc}>
          Required for Pixel to talk. Get a free key from Google AI Studio.
        </Text>

        <TextInput
          style={styles.apiInput}
          value={keyInput}
          onChangeText={setKeyInput}
          placeholder="Paste your API key here..."
          placeholderTextColor="#999"
          secureTextEntry
          autoCapitalize="none"
          autoCorrect={false}
        />

        <View style={styles.buttonRow}>
          <TouchableOpacity
            style={[styles.saveButton, saved && styles.savedButton]}
            onPress={handleSave}
          >
            <Text style={styles.saveButtonText}>
              {saved ? 'Saved!' : 'Save Key'}
            </Text>
          </TouchableOpacity>

          {apiKey ? (
            <TouchableOpacity style={styles.clearKeyButton} onPress={handleClear}>
              <Text style={styles.clearKeyText}>Clear</Text>
            </TouchableOpacity>
          ) : null}
        </View>

        <TouchableOpacity
          style={styles.linkButton}
          onPress={() =>
            Linking.openURL('https://aistudio.google.com/apikey')
          }
        >
          <Text style={styles.linkText}>Get a free API key →</Text>
        </TouchableOpacity>
      </View>

      {/* Status Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Status</Text>
        <View style={styles.statusRow}>
          <Text style={styles.statusLabel}>API Key</Text>
          <View style={[styles.statusDot, apiKey ? styles.statusGreen : styles.statusRed]} />
          <Text style={styles.statusValue}>
            {apiKey ? 'Configured' : 'Not set'}
          </Text>
        </View>
        <View style={styles.statusRow}>
          <Text style={styles.statusLabel}>Days together</Text>
          <Text style={styles.statusValue}>{dayCount}</Text>
        </View>
      </View>

      {/* About Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About AniMind</Text>
        <Text style={styles.aboutText}>
          AniMind is a virtual pet that remembers everything you tell it.
          Memories are stored locally on your device and never leave it.{'\n\n'}
          Conversations are powered by Google's Gemini Flash API. Your messages
          are sent to the API for processing but are not stored by Google.{'\n\n'}
          Built with Expo + React Native + SQLite.
        </Text>
      </View>

      <Text style={styles.version}>AniMind v1.0.0 — Prototype</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FAF3E0',
  },
  content: {
    padding: 16,
    paddingBottom: 40,
  },
  section: {
    backgroundColor: '#FFF',
    borderRadius: 14,
    padding: 18,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  sectionTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#5D4037',
    marginBottom: 6,
  },
  sectionDesc: {
    fontSize: 13,
    color: '#A0896C',
    marginBottom: 14,
    lineHeight: 18,
  },
  apiInput: {
    height: 48,
    backgroundColor: '#F5F0E6',
    borderRadius: 10,
    paddingHorizontal: 14,
    fontSize: 15,
    color: '#333',
    marginBottom: 12,
  },
  buttonRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  saveButton: {
    backgroundColor: '#7C4DFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 10,
  },
  savedButton: {
    backgroundColor: '#4CAF50',
  },
  saveButtonText: {
    color: '#FFF',
    fontWeight: '700',
    fontSize: 15,
  },
  clearKeyButton: {
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  clearKeyText: {
    color: '#FF5252',
    fontWeight: '600',
    fontSize: 14,
  },
  linkButton: {
    marginTop: 14,
  },
  linkText: {
    color: '#7C4DFF',
    fontSize: 14,
    fontWeight: '600',
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F5F0E6',
  },
  statusLabel: {
    flex: 1,
    fontSize: 14,
    color: '#5D4037',
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 8,
  },
  statusGreen: {
    backgroundColor: '#4CAF50',
  },
  statusRed: {
    backgroundColor: '#FF5252',
  },
  statusValue: {
    fontSize: 14,
    color: '#A0896C',
    fontWeight: '600',
  },
  aboutText: {
    fontSize: 13,
    color: '#666',
    lineHeight: 20,
  },
  version: {
    textAlign: 'center',
    fontSize: 12,
    color: '#C0A888',
    marginTop: 8,
  },
});
