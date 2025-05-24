using System;
namespace Sedulous.Messaging;

interface IMessage
{
    DateTime Timestamp { get; }
}