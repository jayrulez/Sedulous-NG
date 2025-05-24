using System;
namespace Sedulous.Messaging;

abstract class Message : IMessage
{
    public DateTime Timestamp { get; private set; }

    protected this()
    {
        Timestamp = DateTime.Now;
    }
}