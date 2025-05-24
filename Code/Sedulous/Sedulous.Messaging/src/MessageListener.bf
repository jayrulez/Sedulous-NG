namespace Sedulous.Messaging;

class MessageListener<T> : IMessageListener where T : IMessage
{
	public delegate void(T message) Handler { get; private set; }

	public this(delegate void(T message) handler)
	{
		Handler = handler;
	}

	public void Handle(IMessage message)
	{
		/*if (message is T typedMessage)
		{
			Handler(typedMessage);
		}*/

		if (message is T)
		{
			Handler((T)message);
		}
	}
}