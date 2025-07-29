using System;
using System.IO;
namespace Sedulous.Serialization;

interface ISerializable
{
	Result<void> Serialize(Stream stream);
	Result<void> Deserialize(Stream stream);
}