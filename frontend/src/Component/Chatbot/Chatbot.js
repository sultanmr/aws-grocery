import React, { useState, useEffect } from 'react';
import AWS from 'aws-sdk';
import './Chatbot.css';

const Chatbot = () => {
    const [messages, setMessages] = useState([]);
    const [inputText, setInputText] = useState('');
    const [lexRuntime, setLexRuntime] = useState(null);
    const [sessionAttributes, setSessionAttributes] = useState({});

    useEffect(() => {
        // Configure AWS
        AWS.config.region = process.env.AWS_REGION;

        const lex = new AWS.LexRuntimeV2();
        setLexRuntime(lex);

        // Initial welcome message from the bot
        setMessages([{ sender: 'bot', text: 'Hello! How can I help you today?' }]);
    }, []);

    const handleSendMessage = async () => {
        if (!inputText.trim()) return;

        const userMessage = { sender: 'user', text: inputText };
        setMessages((prevMessages) => [...prevMessages, userMessage]);
        setInputText('');

        if (!lexRuntime) {
            setMessages((prevMessages) => [
                ...prevMessages,
                { sender: 'bot', text: 'Chatbot is not initialized. Please try again later.' },
            ]);
            return;
        }

        try {
            const params = {
                botId: process.env.REACT_APP_LEX_BOT_ID,
                botAliasId: process.env.REACT_APP_LEX_BOT_ALIAS_ID,
                localeId: 'en_US', // Or your bot's locale
                sessionId: 'user-session-123', // A unique session ID for the user
                text: inputText,
                sessionState: {
                    sessionAttributes: sessionAttributes,
                },
            };

            const data = await lexRuntime.recognizeText(params).promise();
            const botMessage = { sender: 'bot', text: data.messages[0].content };
            setMessages((prevMessages) => [...prevMessages, botMessage]);
            setSessionAttributes(data.sessionState.sessionAttributes || {});

        } catch (error) {
            console.error('Error communicating with Lex:', error);
            setMessages((prevMessages) => [
                ...prevMessages,
                { sender: 'bot', text: 'Sorry, I am having trouble connecting. Please try again.' },
            ]);
        }
    };

    return (
        <div className="chatbot-container">
            <div className="chatbot-messages">
                {messages.map((msg, index) => (
                    <div key={index} className={`message ${msg.sender}`}>
                        {msg.text}
                    </div>
                ))}
            </div>
            <div className="chatbot-input">
                <input
                    type="text"
                    value={inputText}
                    onChange={(e) => setInputText(e.target.value)}
                    onKeyPress={(e) => {
                        if (e.key === 'Enter') {
                            handleSendMessage();
                        }
                    }}
                    placeholder="Type your message..."
                />
                <button onClick={handleSendMessage}>Send</button>
            </div>
        </div>
    );
};

export default Chatbot;