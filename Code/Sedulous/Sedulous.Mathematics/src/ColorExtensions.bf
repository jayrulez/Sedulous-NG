// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net) and Silicon Studio Corp. (https://www.siliconstudio.co.jp)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.

using System.Globalization;
using System;

namespace Sedulous.Mathematics;

/// <summary>
/// A class containing extension methods for processing colors.
/// </summary>
public static class ColorExtensions
{
    /// <summary>
    /// Indicates if the given string can be converted to an <see cref="uint32"/> RGBA value using <see cref="StringToRgba"/>.
    /// </summary>
    /// <param name="stringColor">The string to convert.</param>
    /// <returns>True if the string can be converted, false otherwise.</returns>
    public static bool CanConvertStringToRgba(String stringColor)
    {
        return stringColor?.StartsWith('#') ?? false;
    }

    /// <summary>
    /// Converts the given string to an <see cref="uint32"/> RGBA value.
    /// </summary>
    /// <param name="stringColor">The string to convert.</param>
    /// <returns>The converted RGBA value.</returns>
    public static uint32 StringToRgba(String stringColor)
    {
        uint32 intValue = 0xFF000000;
        if (stringColor?.StartsWith('#') == true)
        {
            if (stringColor.Length == "#000".Length && uint32.Parse(stringColor.Substring(1, 3), NumberStyles.HexNumber, null) case .Ok(intValue))
            {
                intValue = ((intValue & 0x00F) << 16)
                           | ((intValue & 0x00F) << 20)
                           | ((intValue & 0x0F0) << 4)
                           | ((intValue & 0x0F0) << 8)
                           | ((intValue & 0xF00) >> 4)
                           | ((intValue & 0xF00) >> 8)
                           | 0xFF000000;
            }
            if (stringColor.Length == "#000000".Length && uint32.Parse(stringColor.Substring(1, 6), NumberStyles.HexNumber, null) case .Ok(intValue))
            {
                intValue = ((intValue & 0x000000FF) << 16)
                           | (intValue & 0x0000FF00)
                           | ((intValue & 0x00FF0000) >> 16)
                           | 0xFF000000;
            }
            if (stringColor.Length == "#00000000".Length && uint32.Parse(stringColor.Substring(1, 8), NumberStyles.HexNumber, null) case .Ok(intValue))
            {
                intValue = ((intValue & 0x000000FF) << 16)
                           | (intValue & 0x0000FF00)
                           | ((intValue & 0x00FF0000) >> 16)
                           | (intValue & 0xFF000000);
            }
        }
        return intValue;
    }

    /// <summary>
    /// Converts the given RGB value to a string.
    /// </summary>
    /// <param name="value">The RGB value to convert.</param>
    /// <returns>The converted string.</returns>
    public static void RgbToString(int32 value, String str)
    {
        var r = (value & 0x000000FF);
        var g = (value & 0x0000FF00) >> 8;
        var b = (value & 0x00FF0000) >> 16;
        str.Append(scope $"#{r:X2}{g:X2}{b:X2}");
    }

    /// <summary>
    /// Converts the given RGBA value to a string.
    /// </summary>
    /// <param name="value">The RGBA value to convert.</param>
    /// <returns>The converted string.</returns>
    public static void RgbaToString(int32 value, String str)
    {
        var r = (value & 0x000000FF);
        var g = (value & 0x0000FF00) >> 8;
        var b = (value & 0x00FF0000) >> 16;
        var a = (value & 0xFF000000) >> 24;
        str.Append(scope $"#{a:X2}{r:X2}{g:X2}{b:X2}");
    }
}
