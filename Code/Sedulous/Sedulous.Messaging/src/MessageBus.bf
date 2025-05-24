using System.Collections;
using System;
namespace Sedulous.Messaging;

class MessageBus
{
    private Dictionary<Type, List<IMessageListener>> mListeners = new .() ~ delete _;
    private Queue<IMessage> mMessageQueue = new .() ~ delete _;
    private bool mProcessingMessages = false;

    public void Subscribe<T>(delegate void(T message) handler) where T : IMessage
    {
        var messageType = typeof(T);
        if (!mListeners.ContainsKey(messageType))
        {
            mListeners[messageType] = new List<IMessageListener>();
        }

        mListeners[messageType].Add(new MessageListener<T>(handler));
    }

    public void Unsubscribe<T>(delegate void(T message) handler) where T : IMessage
    {
        var messageType = typeof(T);
        if (mListeners.TryGetValue(messageType, var listeners))
        {
            // Find and remove matching listener
            for (int i = listeners.Count - 1; i >= 0; i--)
            {
                if (let typedListener = listeners[i] as MessageListener<T> && typedListener.Handler == handler)
                {
                    listeners.RemoveAt(i);
                    delete typedListener;
                    break;
                }
            }
        }
    }

    public void Publish<T>(T message) where T : IMessage
    {
        if (mProcessingMessages)
        {
            // Queue message if we're currently processing
            mMessageQueue.Add(message);
            return;
        }

        PublishImmediate(message);
    }

    public void ProcessQueuedMessages()
    {
        mProcessingMessages = true;

        while (mMessageQueue.Count > 0)
        {
            var message = mMessageQueue.PopFront();
            PublishImmediate(message);
        }

        mProcessingMessages = false;
    }

    private void PublishImmediate<T>(T message) where T : IMessage
    {
        var messageType = typeof(T);
        
        if (mListeners.TryGetValue(messageType, var listeners))
        {
            for (var listener in listeners)
            {
                listener.Handle(message);
            }
        }

        // Also check for listeners of base types
        var baseType = messageType.BaseType;
        while (baseType != null && baseType != typeof(Object))
        {
            if (mListeners.TryGetValue(baseType, var baseListeners))
            {
                for (var listener in baseListeners)
                {
                    listener.Handle(message);
                }
            }
            baseType = baseType.BaseType;
        }
    }

    public void Clear()
    {
        for (var listenerList in mListeners.Values)
        {
            for (var listener in listenerList)
            {
                delete listener;
            }
            delete listenerList;
        }
        mListeners.Clear();
        mMessageQueue.Clear();
    }
}