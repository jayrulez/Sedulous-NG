namespace Sedulous.Messaging;

interface IMessageListener
{
    void Handle(IMessage message);
}