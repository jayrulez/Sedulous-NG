using System;
using System.Collections;
namespace Sedulous.Foundation.Utilities;

struct GUID : IHashable, IParseable<GUID>
{
	public static readonly GUID Empty = GUID();

	private uint32 mA;
	private uint16 mB;
	private uint16 mC;
	private uint8 mD;
	private uint8 mE;
	private uint8 mF;
	private uint8 mG;
	private uint8 mH;
	private uint8 mI;
	private uint8 mJ;
	private uint8 mK;

	public this()
	{
		this = default;
	}

	public this(uint32 a, uint16 b, uint16 c, uint8 d, uint8 e, uint8 f, uint8 g, uint8 h, uint8 i, uint8 j, uint8 k)
	{
		mA = a;
		mB = b;
		mC = c;
		mD = d;
		mE = e;
		mF = f;
		mG = g;
		mH = h;
		mI = i;
		mJ = j;
		mK = k;
	}

	public int GetHashCode()
	{
		int hash1 = (int)mA;
		int hash2 = ((int)mB << 16) | (int)mC;
		int hash3 = ((int)mD << 24) | ((int)mE << 16) | ((int)mF << 8) | (int)mG;
		int hash4 = ((int)mH << 24) | ((int)mI << 16) | ((int)mJ << 8) | (int)mK;

		return hash1 ^ hash2 ^ hash3 ^ hash4;
	}

	[Commutable]
	public static bool operator ==(GUID val1, GUID val2)
	{
		return
			(val1.mA == val2.mA) &&
			(val1.mB == val2.mB) &&
			(val1.mC == val2.mC) &&
			(val1.mD == val2.mD) &&
			(val1.mE == val2.mE) &&
			(val1.mF == val2.mF) &&
			(val1.mG == val2.mG) &&
			(val1.mH == val2.mH) &&
			(val1.mI == val2.mI) &&
			(val1.mJ == val2.mJ) &&
			(val1.mK == val2.mK);
	}

	public static GUID Create()
	{
		Guid guid = ?;
		Platform.BfpSystem_CreateGUID(&guid);
		return GUID(guid.[Friend]mA,
			guid.[Friend]mB,
			guid.[Friend]mC,
			guid.[Friend]mD,
			guid.[Friend]mE,
			guid.[Friend]mF,
			guid.[Friend]mG,
			guid.[Friend]mH,
			guid.[Friend]mI,
			guid.[Friend]mJ,
			guid.[Friend]mK);
	}

	public void ToString(String strBuffer, char8 format = 'D')
	{
	    switch(format)
	    {
	    case 'N', 'n':
	        // 32 digits: 00000000000000000000000000000000
	        strBuffer.AppendF("{0,8:x8}{1,4:x4}{2,4:x4}{3,2:x2}{4,2:x2}{5,2:x2}{6,2:x2}{7,2:x2}{8,2:x2}{9,2:x2}{10,2:x2}", 
	            mA, mB, mC, mD, mE, mF, mG, mH, mI, mJ, mK);
	        
	    case 'D', 'd':
	        // 32 digits separated by hyphens: 00000000-0000-0000-0000-000000000000
	        strBuffer.AppendF("{0,8:x8}-{1,4:x4}-{2,4:x4}-{3,2:x2}{4,2:x2}-{5,2:x2}{6,2:x2}{7,2:x2}{8,2:x2}{9,2:x2}{10,2:x2}", 
	            mA, mB, mC, mD, mE, mF, mG, mH, mI, mJ, mK);
	        
	    case 'B', 'b':
	        // 32 digits separated by hyphens, enclosed in braces: {00000000-0000-0000-0000-000000000000}
	        strBuffer.AppendF("{{{0,8:x8}-{1,4:x4}-{2,4:x4}-{3,2:x2}{4,2:x2}-{5,2:x2}{6,2:x2}{7,2:x2}{8,2:x2}{9,2:x2}{10,2:x2}}}", 
	            mA, mB, mC, mD, mE, mF, mG, mH, mI, mJ, mK);
	        
	    case 'P', 'p':
	        // 32 digits separated by hyphens, enclosed in parentheses: (00000000-0000-0000-0000-000000000000)
	        strBuffer.AppendF("({0,8:x8}-{1,4:x4}-{2,4:x4}-{3,2:x2}{4,2:x2}-{5,2:x2}{6,2:x2}{7,2:x2}{8,2:x2}{9,2:x2}{10,2:x2})", 
	            mA, mB, mC, mD, mE, mF, mG, mH, mI, mJ, mK);
	        
	    case 'X', 'x':
	        // Four hexadecimal values enclosed in braces: {0x00000000,0x0000,0x0000,{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}}
	        strBuffer.AppendF("{{0x{0,8:x8},0x{1,4:x4},0x{2,4:x4},{{0x{3,2:x2},0x{4,2:x2},0x{5,2:x2},0x{6,2:x2},0x{7,2:x2},0x{8,2:x2},0x{9,2:x2},0x{10,2:x2}}}}}", 
	            mA, mB, mC, mD, mE, mF, mG, mH, mI, mJ, mK);
	        
	    default:
	        // Default to 'D' format
	        strBuffer.AppendF("{0,8:x8}-{1,4:x4}-{2,4:x4}-{3,2:x2}{4,2:x2}-{5,2:x2}{6,2:x2}{7,2:x2}{8,2:x2}{9,2:x2}{10,2:x2}", 
	            mA, mB, mC, mD, mE, mF, mG, mH, mI, mJ, mK);
	    }
	}

	public override void ToString(String strBuffer)
	{
	    ToString(strBuffer, 'D');
	}

	public static Result<GUID> Parse(StringView val)
	{
		var val;
	    if (val.IsEmpty)
	        return .Err;

		String str = scope .(val);
		str.Trim();
	    
	    // Determine format based on string characteristics
	    if (str.StartsWith("{0x") && str.EndsWith("}}"))
	    {
	        // X format: {0x00000000,0x0000,0x0000,{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}}
	        return ParseXFormat(str);
	    }
	    else if (str.StartsWith("{") && str.EndsWith("}"))
	    {
	        // B format: {00000000-0000-0000-0000-000000000000}
	        return ParseDashFormat(str.Substring(1, str.Length - 2));
	    }
	    else if (str.StartsWith("(") && str.EndsWith(")"))
	    {
	        // P format: (00000000-0000-0000-0000-000000000000)
	        return ParseDashFormat(str.Substring(1, str.Length - 2));
	    }
	    else if (str.Contains('-'))
	    {
	        // D format: 00000000-0000-0000-0000-000000000000
	        return ParseDashFormat(str);
	    }
	    else if (str.Length == 32)
	    {
	        // N format: 00000000000000000000000000000000
	        return ParseNFormat(str);
	    }
	    
	    return .Err;
	}

	private static Result<GUID> ParseDashFormat(StringView val)
	{
	    // Expected format: 00000000-0000-0000-0000-000000000000
	    StringView[5] parts = ?;
	    int partCount = 0;
	    
	    for (var part in val.Split('-'))
	    {
	        if (partCount >= 5)
	            return .Err;
	        parts[partCount] = part;
	        partCount++;
	    }
	    
	    if (partCount != 5)
	        return .Err;
	    
	    if (parts[0].Length != 8 || parts[1].Length != 4 || parts[2].Length != 4 || 
	        parts[3].Length != 4 || parts[4].Length != 12)
	        return .Err;
	    
	    // Parse each part
	    if (uint32.Parse(parts[0], .HexNumber) case .Ok(let a) &&
	        uint16.Parse(parts[1], .HexNumber) case .Ok(let b) &&
	        uint16.Parse(parts[2], .HexNumber) case .Ok(let c))
	    {
	        // Parse the 8 bytes from parts[3] and parts[4]
	        String part3and4 = scope String()..Append(parts[3])..Append(parts[4]);
	        
	        if (part3and4.Length != 16)
	            return .Err;
	        
	        uint8[8] bytes = ?;
	        for (int i = 0; i < 8; i++)
	        {
	            StringView byteStr = part3and4.Substring(i * 2, 2);
	            if (uint8.Parse(byteStr, .HexNumber) case .Ok(let byteVal))
	                bytes[i] = byteVal;
	            else
	                return .Err;
	        }
	        
	        return .Ok(GUID(a, b, c, bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7]));
	    }
	    
	    return .Err;
	}

	private static Result<GUID> ParseNFormat(StringView val)
	{
	    // Expected format: 00000000000000000000000000000000 (32 hex chars)
	    if (val.Length != 32)
	        return .Err;
	    
	    // Parse as: aaaaaaaa bbbb cccc ddee ffgghhiijjkk
	    if (uint32.Parse(val.Substring(0, 8), .HexNumber) case .Ok(let a) &&
	        uint16.Parse(val.Substring(8, 4), .HexNumber) case .Ok(let b) &&
	        uint16.Parse(val.Substring(12, 4), .HexNumber) case .Ok(let c))
	    {
	        uint8[8] bytes = ?;
	        for (int i = 0; i < 8; i++)
	        {
	            StringView byteStr = val.Substring(16 + i * 2, 2);
	            if (uint8.Parse(byteStr, .HexNumber) case .Ok(let byteVal))
	                bytes[i] = byteVal;
	            else
	                return .Err;
	        }
	        
	        return .Ok(GUID(a, b, c, bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7]));
	    }
	    
	    return .Err;
	}

	private static Result<GUID> ParseXFormat(StringView val)
	{
	    // Expected format: {0x00000000,0x0000,0x0000,{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}}
	    StringView inner = val.Substring(1, val.Length - 2); // Remove outer braces
	    
	    if (!inner.StartsWith("0x"))
	        return .Err;
	    
	    // Find the inner brace section
	    int innerBraceStart = inner.IndexOf('{');
	    if (innerBraceStart == -1)
	        return .Err;
	    
	    int innerBraceEnd = inner.LastIndexOf('}');
	    if (innerBraceEnd == -1 || innerBraceEnd <= innerBraceStart)
	        return .Err;
	    
	    // Parse the first three parts before the inner braces
	    StringView firstPart = inner.Substring(0, innerBraceStart - 1); // Remove trailing comma
	    StringView[3] mainParts = ?;
	    int mainPartCount = 0;
	    
	    for (var part in firstPart.Split(','))
	    {
	        if (mainPartCount >= 3)
	            return .Err;
	        mainParts[mainPartCount] = part;
	        mainPartCount++;
	    }
	    
	    if (mainPartCount != 3)
	        return .Err;
	    
	    // Parse main parts (remove 0x prefix)
	    if (uint32.Parse(mainParts[0].Substring(2), .HexNumber) case .Ok(let a) &&
	        uint16.Parse(mainParts[1].Substring(2), .HexNumber) case .Ok(let b) &&
	        uint16.Parse(mainParts[2].Substring(2), .HexNumber) case .Ok(let c))
	    {
	        // Parse the 8 bytes in the inner braces
	        StringView innerBytes = inner.Substring(innerBraceStart + 1, innerBraceEnd - innerBraceStart - 1);
	        StringView[8] byteParts = ?;
	        int bytePartCount = 0;
	        
	        for (var part in innerBytes.Split(','))
	        {
	            if (bytePartCount >= 8)
	                return .Err;
	            byteParts[bytePartCount] = scope :: String(part)..Trim();
	            bytePartCount++;
	        }
	        
	        if (bytePartCount != 8)
	            return .Err;
	        
	        uint8[8] bytes = ?;
	        for (int i = 0; i < 8; i++)
	        {
	            StringView bytePart = byteParts[i];
	            if (!bytePart.StartsWith("0x"))
	                return .Err;
	                
	            if (uint8.Parse(bytePart.Substring(2), .HexNumber) case .Ok(let byteVal))
	                bytes[i] = byteVal;
	            else
	                return .Err;
	        }
	        
	        return .Ok(GUID(a, b, c, bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7]));
	    }
	    
	    return .Err;
	}
}