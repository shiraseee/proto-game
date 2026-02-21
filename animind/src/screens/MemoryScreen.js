import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { getAllMemories, deleteMemory, clearAllMemories } from '../db/database';

export default function MemoryScreen() {
  const [memories, setMemories] = useState([]);

  const loadMemories = useCallback(async () => {
    const mems = await getAllMemories();
    setMemories(mems);
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadMemories();
    }, [loadMemories])
  );

  const handleDelete = (id) => {
    Alert.alert('Delete Memory', 'Remove this memory?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          await deleteMemory(id);
          loadMemories();
        },
      },
    ]);
  };

  const handleClearAll = () => {
    Alert.alert(
      'Clear All Memories',
      'This will erase everything Pixel knows about you. Are you sure?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear All',
          style: 'destructive',
          onPress: async () => {
            await clearAllMemories();
            loadMemories();
          },
        },
      ]
    );
  };

  const formatDate = (timestamp) => {
    const d = new Date(timestamp);
    return d.toLocaleDateString() + ' ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const importanceBar = (score) => {
    const filled = Math.round(score * 5);
    return '●'.repeat(filled) + '○'.repeat(5 - filled);
  };

  const renderMemory = ({ item }) => (
    <TouchableOpacity
      style={styles.memoryCard}
      onLongPress={() => handleDelete(item.id)}
      activeOpacity={0.7}
    >
      <Text style={styles.memoryContent}>{item.content}</Text>
      <View style={styles.memoryMeta}>
        <Text style={styles.memoryDate}>{formatDate(item.timestamp)}</Text>
        <Text style={styles.importanceScore}>
          {importanceBar(item.importance_score)}
        </Text>
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>Pixel's Memories</Text>
          <Text style={styles.subtitle}>
            {memories.length} memor{memories.length === 1 ? 'y' : 'ies'} stored
          </Text>
        </View>
        {memories.length > 0 && (
          <TouchableOpacity style={styles.clearButton} onPress={handleClearAll}>
            <Text style={styles.clearButtonText}>Clear All</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Memory list */}
      <FlatList
        data={memories}
        renderItem={renderMemory}
        keyExtractor={(item) => item.id.toString()}
        contentContainerStyle={styles.list}
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Text style={styles.emptyEmoji}>🧠</Text>
            <Text style={styles.emptyTitle}>No memories yet</Text>
            <Text style={styles.emptyText}>
              Chat with Pixel to start building memories.{'\n'}
              Key facts will be extracted and stored here.
            </Text>
          </View>
        }
      />

      <Text style={styles.hint}>Long-press a memory to delete it</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FAF3E0',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    paddingTop: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E8DCC8',
    backgroundColor: '#FFF8E7',
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#5D4037',
  },
  subtitle: {
    fontSize: 13,
    color: '#A0896C',
    marginTop: 2,
  },
  clearButton: {
    backgroundColor: '#FF5252',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 8,
  },
  clearButtonText: {
    color: '#FFF',
    fontSize: 13,
    fontWeight: '700',
  },
  list: {
    padding: 16,
    paddingBottom: 40,
  },
  memoryCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  memoryContent: {
    fontSize: 15,
    color: '#333',
    lineHeight: 21,
  },
  memoryMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
  },
  memoryDate: {
    fontSize: 11,
    color: '#A0896C',
  },
  importanceScore: {
    fontSize: 10,
    color: '#7C4DFF',
    letterSpacing: 2,
  },
  emptyState: {
    alignItems: 'center',
    paddingTop: 60,
  },
  emptyEmoji: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#5D4037',
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 14,
    color: '#A0896C',
    textAlign: 'center',
    lineHeight: 20,
  },
  hint: {
    textAlign: 'center',
    fontSize: 11,
    color: '#C0A888',
    paddingBottom: 16,
  },
});
