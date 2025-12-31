using System;
using System.IO;
namespace Sedulous.Serialization;

interface ISerializable
{
    void Serialize(ISerializer serializer);
    void Deserialize(ISerializer serializer);
}