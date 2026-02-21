import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  ActivityIndicator,
  Animated,
} from 'react-native';
import { useApp } from '../context/AppContext';
import { chatWithPet } from '../api/gemini';

const MOOD_EMOJIS = {
  happy: '🐣',
  curious: '🐥',
  sleepy: '😴',
  excited: '✨',
};

const MOOD_LABELS = {
  happy: 'Happy',
  curious: 'Curious',
  sleepy: 'Sleepy',
  excited: 'Excited',
};

export default function HomeScreen() {
  const { apiKey, dayCount, greeting, mood, updateMood } = useApp();
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const flatListRef = useRef(null);
  const bounceAnim = useRef(new Animated.Value(0)).current;
  const chatCount = useRef(0);

  // Bounce animation for pet
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(bounceAnim, {
          toValue: -8,
          duration: 800,
          useNativeDriver: true,
        }),
        Animated.timing(bounceAnim, {
          toValue: 0,
          duration: 800,
          useNativeDriver: true,
        }),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, [bounceAnim]);

  // Show greeting as first message
  useEffect(() => {
    if (greeting) {
      setMessages([{ id: 'greeting', role: 'pet', text: greeting }]);
    }
  }, [greeting]);

  const sendMessage = async () => {
    const text = input.trim();
    if (!text || loading) return;

    setInput('');
    const userMsg = { id: Date.now().toString(), role: 'user', text };
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);

    try {
      const response = await chatWithPet(text, apiKey);
      chatCount.current += 1;
      updateMood(chatCount.current);

      const petMsg = {
        id: (Date.now() + 1).toString(),
        role: 'pet',
        text: response,
      };
      setMessages((prev) => [...prev, petMsg]);
    } catch (err) {
      const errorMsg = {
        id: (Date.now() + 1).toString(),
        role: 'error',
        text: err.message || 'Something went wrong...',
      };
      setMessages((prev) => [...prev, errorMsg]);
    }

    setLoading(false);
  };

  const renderMessage = ({ item }) => {
    const isUser = item.role === 'user';
    const isError = item.role === 'error';

    return (
      <View
        style={[
          styles.messageBubble,
          isUser ? styles.userBubble : isError ? styles.errorBubble : styles.petBubble,
        ]}
      >
        {!isUser && !isError && (
          <Text style={styles.bubbleName}>Pixel</Text>
        )}
        <Text style={[styles.messageText, isUser && styles.userText]}>
          {item.text}
        </Text>
      </View>
    );
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={90}
    >
      {/* Pet display area */}
      <View style={styles.petArea}>
        <Text style={styles.dayCounter}>
          Day {dayCount} of your life together
        </Text>

        <Animated.Text
          style={[styles.petEmoji, { transform: [{ translateY: bounceAnim }] }]}
        >
          {MOOD_EMOJIS[mood]}
        </Animated.Text>

        <View style={styles.moodBadge}>
          <Text style={styles.moodText}>{MOOD_LABELS[mood]}</Text>
        </View>

        <Text style={styles.petName}>Pixel</Text>
      </View>

      {/* Chat area */}
      <View style={styles.chatArea}>
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.messagesList}
          onContentSizeChange={() =>
            flatListRef.current?.scrollToEnd({ animated: true })
          }
          ListEmptyComponent={
            <Text style={styles.emptyText}>Say something to Pixel!</Text>
          }
        />

        {loading && (
          <View style={styles.typingIndicator}>
            <ActivityIndicator size="small" color="#7C4DFF" />
            <Text style={styles.typingText}>Pixel is thinking...</Text>
          </View>
        )}
      </View>

      {/* Input area */}
      <View style={styles.inputArea}>
        <TextInput
          style={styles.input}
          value={input}
          onChangeText={setInput}
          placeholder="Talk to Pixel..."
          placeholderTextColor="#999"
          returnKeyType="send"
          onSubmitEditing={sendMessage}
          editable={!loading}
        />
        <TouchableOpacity
          style={[styles.sendButton, (!input.trim() || loading) && styles.sendButtonDisabled]}
          onPress={sendMessage}
          disabled={!input.trim() || loading}
        >
          <Text style={styles.sendButtonText}>▶</Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FAF3E0',
  },
  petArea: {
    alignItems: 'center',
    paddingTop: 12,
    paddingBottom: 8,
    backgroundColor: '#FFF8E7',
    borderBottomWidth: 1,
    borderBottomColor: '#E8DCC8',
  },
  dayCounter: {
    fontSize: 12,
    color: '#A0896C',
    fontWeight: '600',
    letterSpacing: 0.5,
  },
  petEmoji: {
    fontSize: 56,
    marginVertical: 4,
  },
  moodBadge: {
    backgroundColor: '#7C4DFF22',
    paddingHorizontal: 12,
    paddingVertical: 3,
    borderRadius: 12,
    marginTop: 2,
  },
  moodText: {
    fontSize: 11,
    color: '#7C4DFF',
    fontWeight: '700',
  },
  petName: {
    fontSize: 16,
    fontWeight: '700',
    color: '#5D4037',
    marginTop: 4,
  },
  chatArea: {
    flex: 1,
  },
  messagesList: {
    padding: 16,
    paddingBottom: 8,
  },
  messageBubble: {
    maxWidth: '80%',
    padding: 12,
    borderRadius: 16,
    marginBottom: 8,
  },
  userBubble: {
    alignSelf: 'flex-end',
    backgroundColor: '#7C4DFF',
    borderBottomRightRadius: 4,
  },
  petBubble: {
    alignSelf: 'flex-start',
    backgroundColor: '#FFFFFF',
    borderBottomLeftRadius: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
  },
  errorBubble: {
    alignSelf: 'flex-start',
    backgroundColor: '#FFEBEE',
    borderBottomLeftRadius: 4,
    borderWidth: 1,
    borderColor: '#FFCDD2',
  },
  bubbleName: {
    fontSize: 11,
    fontWeight: '700',
    color: '#7C4DFF',
    marginBottom: 4,
  },
  messageText: {
    fontSize: 15,
    color: '#333',
    lineHeight: 21,
  },
  userText: {
    color: '#FFF',
  },
  emptyText: {
    textAlign: 'center',
    color: '#BBA88C',
    fontSize: 14,
    marginTop: 40,
  },
  typingIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingBottom: 8,
  },
  typingText: {
    fontSize: 13,
    color: '#7C4DFF',
    marginLeft: 8,
    fontStyle: 'italic',
  },
  inputArea: {
    flexDirection: 'row',
    padding: 12,
    paddingBottom: Platform.OS === 'ios' ? 28 : 12,
    backgroundColor: '#FFF',
    borderTopWidth: 1,
    borderTopColor: '#E8DCC8',
    alignItems: 'center',
  },
  input: {
    flex: 1,
    height: 44,
    backgroundColor: '#F5F0E6',
    borderRadius: 22,
    paddingHorizontal: 16,
    fontSize: 15,
    color: '#333',
  },
  sendButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#7C4DFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 8,
  },
  sendButtonDisabled: {
    backgroundColor: '#D1C4E9',
  },
  sendButtonText: {
    color: '#FFF',
    fontSize: 18,
  },
});
