namespace Sedulous.Foundation.Tests;

using System;
using Sedulous.Foundation.Utilities;

class GUIDTests
{
    // Test GUID for consistent testing
    private static GUID GetTestGUID()
    {
        return GUID(0x550e8400, 0xe29b, 0x41d4, 0xa7, 0x16, 0x44, 0x66, 0x55, 0x44, 0x00, 0x00);
    }

    [Test]
    public static void Constructor()
    {
        var guid = GUID(0x12345678, 0x1234, 0x5678, 0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0);
        
        // Test that we can access the values (indirectly through ToString)
        String str = scope String();
        guid.ToString(str, 'N');
        Test.Assert(str == "1234567812345678123456789abcdef0");
    }

    [Test]
    public static void EmptyGUID()
    {
        var empty = GUID.Empty;
        String str = scope String();
        empty.ToString(str, 'D');
        Test.Assert(str == "00000000-0000-0000-0000-000000000000");
    }

    [Test]
    public static void Equality()
    {
        var guid1 = GetTestGUID();
        var guid2 = GetTestGUID();
        var guid3 = GUID(0x12345678, 0x1234, 0x5678, 0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0);

        Test.Assert(guid1 == guid2);
        Test.Assert(!(guid1 == guid3));
        Test.Assert(!(guid2 == guid3));
    }

    [Test]
    public static void HashCode()
    {
        var guid1 = GetTestGUID();
        var guid2 = GetTestGUID();
        var guid3 = GUID(0x12345678, 0x1234, 0x5678, 0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0);

        // Same GUIDs should have same hash code
        Test.Assert(guid1.GetHashCode() == guid2.GetHashCode());
        
        // Different GUIDs should likely have different hash codes (not guaranteed, but very likely)
        Test.Assert(guid1.GetHashCode() != guid3.GetHashCode());
    }

    [Test]
    public static void ToString_NFormat()
    {
        var guid = GetTestGUID();
        String str = scope String();
        
        guid.ToString(str, 'N');
        Test.Assert(str == "550e8400e29b41d4a716446655440000");
        
        str.Clear();
        guid.ToString(str, 'n');
        Test.Assert(str == "550e8400e29b41d4a716446655440000");
    }

    [Test]
    public static void ToString_DFormat()
    {
        var guid = GetTestGUID();
        String str = scope String();
        
        guid.ToString(str, 'D');
        Test.Assert(str == "550e8400-e29b-41d4-a716-446655440000");
        
        str.Clear();
        guid.ToString(str, 'd');
        Test.Assert(str == "550e8400-e29b-41d4-a716-446655440000");
        
        // Test default format
        str.Clear();
        guid.ToString(str);
        Test.Assert(str == "550e8400-e29b-41d4-a716-446655440000");
    }

    [Test]
    public static void ToString_BFormat()
    {
        var guid = GetTestGUID();
        String str = scope String();
        
        guid.ToString(str, 'B');
        Test.Assert(str == "{550e8400-e29b-41d4-a716-446655440000}");
        
        str.Clear();
        guid.ToString(str, 'b');
        Test.Assert(str == "{550e8400-e29b-41d4-a716-446655440000}");
    }

    [Test]
    public static void ToString_PFormat()
    {
        var guid = GetTestGUID();
        String str = scope String();
        
        guid.ToString(str, 'P');
        Test.Assert(str == "(550e8400-e29b-41d4-a716-446655440000)");
        
        str.Clear();
        guid.ToString(str, 'p');
        Test.Assert(str == "(550e8400-e29b-41d4-a716-446655440000)");
    }

    [Test]
    public static void ToString_XFormat()
    {
        var guid = GetTestGUID();
        String str = scope String();
        
        guid.ToString(str, 'X');
        Test.Assert(str == "{0x550e8400,0xe29b,0x41d4,{0xa7,0x16,0x44,0x66,0x55,0x44,0x00,0x00}}");
        
        str.Clear();
        guid.ToString(str, 'x');
        Test.Assert(str == "{0x550e8400,0xe29b,0x41d4,{0xa7,0x16,0x44,0x66,0x55,0x44,0x00,0x00}}");
    }

    [Test]
    public static void ToString_InvalidFormat()
    {
        var guid = GetTestGUID();
        String str = scope String();
        
        // Invalid format should default to 'D' format
        guid.ToString(str, 'Z');
        Test.Assert(str == "550e8400-e29b-41d4-a716-446655440000");
    }

    [Test]
    public static void Parse_DFormat()
    {
        String testStr = "550e8400-e29b-41d4-a716-446655440000";
        
        if (GUID.Parse(testStr) case .Ok(let parsed))
        {
            var expected = GetTestGUID();
            Test.Assert(parsed == expected);
        }
        else
        {
            Test.Assert(false); // Parse should have succeeded
        }
    }

    [Test]
    public static void Parse_NFormat()
    {
        String testStr = "550e8400e29b41d4a716446655440000";
        
        if (GUID.Parse(testStr) case .Ok(let parsed))
        {
            var expected = GetTestGUID();
            Test.Assert(parsed == expected);
        }
        else
        {
            Test.Assert(false); // Parse should have succeeded
        }
    }

    [Test]
    public static void Parse_BFormat()
    {
        String testStr = "{550e8400-e29b-41d4-a716-446655440000}";
        
        if (GUID.Parse(testStr) case .Ok(let parsed))
        {
            var expected = GetTestGUID();
            Test.Assert(parsed == expected);
        }
        else
        {
            Test.Assert(false); // Parse should have succeeded
        }
    }

    [Test]
    public static void Parse_PFormat()
    {
        String testStr = "(550e8400-e29b-41d4-a716-446655440000)";
        
        if (GUID.Parse(testStr) case .Ok(let parsed))
        {
            var expected = GetTestGUID();
            Test.Assert(parsed == expected);
        }
        else
        {
            Test.Assert(false); // Parse should have succeeded
        }
    }

    [Test]
    public static void Parse_XFormat()
    {
		//return GUID(0x550e8400, 0xe29b, 0x41d4, 0xa7, 0x16, 0x44, 0x66, 0x55, 0x44, 0x00, 0x00);
        String testStr = "{0x550e8400,0xe29b,0x41d4,{0xa7,0x16,0x44,0x66,0x55,0x44,0x00,0x00}}";
        
        if (GUID.Parse(testStr) case .Ok(let parsed))
        {
            var expected = GetTestGUID();
            Test.Assert(parsed == expected);
        }
        else
        {
            Test.Assert(false); // Parse should have succeeded
        }
    }

    [Test]
    public static void Parse_EmptyString()
    {
        if (GUID.Parse("") case .Ok(let parsed))
        {
            Test.Assert(false); // Should have failed
        }
        else
        {
            // Expected to fail
            Test.Assert(true);
        }
    }

    [Test]
    public static void Parse_InvalidFormat()
    {
        String[] invalidStrings = scope .(
            "invalid",
            "123",
            "550e8400-e29b-41d4-a716", // Too short
            "550e8400-e29b-41d4-a716-446655440000-extra", // Too long
            "{550e8400-e29b-41d4-a716-446655440000", // Missing closing brace
            "550e8400-e29b-41d4-a716-446655440000}", // Missing opening brace
            "(550e8400-e29b-41d4-a716-446655440000", // Missing closing paren
            "550e8400-e29b-41d4-a716-446655440000)", // Missing opening paren
            "gggggggg-gggg-gggg-gggg-gggggggggggg", // Invalid hex characters
            "550e8400e29b41d4a716446655440000extra", // N format too long
            "550e8400e29b41d4a71644665544000", // N format too short
        );

        for (var invalidStr in invalidStrings)
        {
            if (GUID.Parse(invalidStr) case .Ok(let parsed))
            {
                Test.Assert(false); // Should have failed
            }
        }
    }

    [Test]
    public static void Parse_WithWhitespace()
    {
        String testStr = "  550e8400-e29b-41d4-a716-446655440000  ";
        
        if (GUID.Parse(testStr) case .Ok(let parsed))
        {
            var expected = GetTestGUID();
            Test.Assert(parsed == expected);
        }
        else
        {
            Test.Assert(false); // Parse should have succeeded
        }
    }

    [Test]
    public static void RoundTripTest_AllFormats()
    {
        var original = GetTestGUID();
        String str = scope String();
        
        // Test each format can round-trip
        char8[] formats = scope .('N', 'D', 'B', 'P', 'X');
        
        for (var format in formats)
        {
            str.Clear();
            original.ToString(str, format);
            
            if (GUID.Parse(str) case .Ok(let parsed))
            {
                Test.Assert(parsed == original);
            }
            else
            {
                Test.Assert(false); // Round-trip should work
            }
        }
    }

    [Test]
    public static void RoundTripTest_RandomGUIDs()
    {
        // Test with multiple different GUIDs
        GUID[] testGuids = scope .(
            GUID.Empty,
            GetTestGUID(),
            GUID(0xFFFFFFFF, 0xFFFF, 0xFFFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF),
            GUID(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01),
            GUID(0x12345678, 0x9ABC, 0xDEF0, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0)
        );

        String str = scope String();
        
        for (var guid in testGuids)
        {
            str.Clear();
            guid.ToString(str, 'D');
            
            if (GUID.Parse(str) case .Ok(let parsed))
            {
                Test.Assert(parsed == guid);
            }
            else
            {
                Test.Assert(false);
            }
        }
    }

    [Test]
    public static void Create_GeneratesUniqueGUIDs()
    {
        // Generate several GUIDs and ensure they're different
        GUID[] guids = scope GUID[10];
        
        for (int i = 0; i < 10; i++)
        {
            guids[i] = GUID.Create();
        }
        
        // Check that all GUIDs are different from each other
        for (int i = 0; i < 10; i++)
        {
            for (int j = i + 1; j < 10; j++)
            {
                Test.Assert(!(guids[i] == guids[j]));
            }
        }
        
        // Check that none are empty
        for (int i = 0; i < 10; i++)
        {
            Test.Assert(!(guids[i] == GUID.Empty));
        }
    }

    [Test]
    public static void Parse_CaseInsensitive()
    {
        // Test that parsing is case insensitive for hex digits
        String lowerCase = "550e8400-e29b-41d4-a716-446655440000";
        String upperCase = "550E8400-E29B-41D4-A716-446655440000";
        String mixedCase = "550e8400-E29B-41d4-A716-446655440000";
        
        var expected = GetTestGUID();
        
        if (GUID.Parse(lowerCase) case .Ok(let parsed1))
        {
            Test.Assert(parsed1 == expected);
        }
        else
        {
            Test.Assert(false);
        }
        
        if (GUID.Parse(upperCase) case .Ok(let parsed2))
        {
            Test.Assert(parsed2 == expected);
        }
        else
        {
            Test.Assert(false);
        }
        
        if (GUID.Parse(mixedCase) case .Ok(let parsed3))
        {
            Test.Assert(parsed3 == expected);
        }
        else
        {
            Test.Assert(false);
        }
    }

    [Test]
    public static void ToString_ConsistentOutput()
    {
        var guid = GetTestGUID();
        String str1 = scope String();
        String str2 = scope String();
        
        // Multiple calls should produce identical output
        guid.ToString(str1, 'D');
        guid.ToString(str2, 'D');
        
        Test.Assert(str1 == str2);
    }
}