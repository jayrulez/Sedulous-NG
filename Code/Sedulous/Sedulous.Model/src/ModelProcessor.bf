using System.Collections;
using System;
namespace Sedulous.Model;

abstract class ModelProcessor
{
	public abstract void GetExtensions(List<StringView> extensions);

	public abstract bool SupportsFormat(StringView @extension);

	public abstract Model Read(StringView path);
	public abstract bool Write(StringView path, Model model);
}