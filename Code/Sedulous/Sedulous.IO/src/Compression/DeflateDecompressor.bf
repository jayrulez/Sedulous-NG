using System;
using System.Collections;

using internal Sedulous.IO.Compression;
namespace Sedulous.IO.Compression;

// Deflate decompressor (the complex part needed for PNG)
internal class DeflateDecompressor
{
	[CRepr]
    private struct HuffmanTable
    {
        public uint16[16] CodeCounts;   // Number of codes of each length
        public uint16[288] Codes;       // The actual codes
        public uint8[288] CodeLengths;  // Length of each code
        public uint16[288] Symbols;     // Symbol for each code
        public int SymbolCount;
        
        public this()
        {
            CodeCounts = default;
            Codes = default;
            CodeLengths = default;
            Symbols = default;
            SymbolCount = 0;
        }
    }
    
    private BitReader mBitReader ~ delete _;
    private uint8[] mWindow;
    private int mWindowPos;
    private HuffmanTable mLiteralTable;
    private HuffmanTable mDistanceTable;
    
    public this()
    {
        mWindow = new uint8[Deflate.WINDOW_SIZE];
        mWindowPos = 0;
    }
    
    public ~this()
    {
        delete mWindow;
    }
    
    public Zlib.Result Decompress(Span<uint8> input, List<uint8> output)
    {
        mBitReader = new BitReader(input);
        
        bool isLastBlock = false;
        while (!isLastBlock)
        {
            // Read block header
            if (mBitReader.ReadBits(1) case .Ok(let lastFlag))
                isLastBlock = lastFlag == 1;
            else
                return .InvalidData;
            
            if (mBitReader.ReadBits(2) case .Ok(let blockType))
            {
                switch (blockType)
                {
                case 0: // No compression
                    if (DecompressUncompressedBlock(output) case .Err)
                        return .InvalidData;
                case 1: // Fixed Huffman
                    SetupFixedHuffmanTables();
                    if (DecompressHuffmanBlock(output) case .Err)
                        return .InvalidData;
                case 2: // Dynamic Huffman
                    if (SetupDynamicHuffmanTables() case .Err)
                        return .InvalidData;
                    if (DecompressHuffmanBlock(output) case .Err)
                        return .InvalidData;
                default:
                    return .InvalidData;
                }
            }
            else
            {
                return .InvalidData;
            }
        }
        
        return .Success;
    }
    
    private Result<void> DecompressUncompressedBlock(List<uint8> output)
    {
        // Skip to byte boundary
        mBitReader.AlignToByte();
        
        // Read length and complement
        if (mBitReader.ReadBytes(2) case .Ok(let lenBytes) &&
            mBitReader.ReadBytes(2) case .Ok(let nlenBytes))
        {
            uint16 len = (uint16)(lenBytes[0] | ((uint16)lenBytes[1] << 8));
            uint16 nlen = (uint16)(nlenBytes[0] | ((uint16)nlenBytes[1] << 8));
            
            if (len != (uint16)(~nlen))
                return .Err;
            
            // Copy literal data
            if (mBitReader.ReadBytes(len) case .Ok(let data))
            {
                for (var b in data)
                {
                    output.Add(b);
                    mWindow[mWindowPos] = b;
                    mWindowPos = (mWindowPos + 1) % Deflate.WINDOW_SIZE;
                }
                return .Ok;
            }
        }
        
        return .Err;
    }
    
    private void SetupFixedHuffmanTables()
    {
        // Fixed literal/length alphabet
        mLiteralTable = HuffmanTable();
        
        // Code lengths for fixed alphabet
        for (int i = 0; i <= 143; i++)
            mLiteralTable.CodeLengths[i] = 8;
        for (int i = 144; i <= 255; i++)
            mLiteralTable.CodeLengths[i] = 9;
        for (int i = 256; i <= 279; i++)
            mLiteralTable.CodeLengths[i] = 7;
        for (int i = 280; i <= 287; i++)
            mLiteralTable.CodeLengths[i] = 8;
        
        mLiteralTable.SymbolCount = 288;
        BuildHuffmanTable(ref mLiteralTable);
        
        // Fixed distance alphabet (all length 5)
        mDistanceTable = HuffmanTable();
        for (int i = 0; i < 32; i++)
            mDistanceTable.CodeLengths[i] = 5;
        
        mDistanceTable.SymbolCount = 32;
        BuildHuffmanTable(ref mDistanceTable);
    }
    
    private Result<void> SetupDynamicHuffmanTables()
    {
        // Read table sizes
        if (mBitReader.ReadBits(5) case .Ok(let hlit) &&
            mBitReader.ReadBits(5) case .Ok(let hdist) &&
            mBitReader.ReadBits(4) case .Ok(let hclen))
        {
            int numLiteralCodes = (int)hlit + 257;
            int numDistanceCodes = (int)hdist + 1;
            int numCodeLengthCodes = (int)hclen + 4;
            
            // Code length alphabet order
            uint8[19] clOrder = .(16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);
            
            // Read code length code lengths
            var codeLengthTable = HuffmanTable();
            for (int i = 0; i < numCodeLengthCodes; i++)
            {
                if (mBitReader.ReadBits(3) case .Ok(let len))
                    codeLengthTable.CodeLengths[clOrder[i]] = (uint8)len;
                else
                    return .Err;
            }
            
            codeLengthTable.SymbolCount = 19;
            BuildHuffmanTable(ref codeLengthTable);
            
            // Read literal and distance code lengths
            var allCodeLengths = scope uint8[numLiteralCodes + numDistanceCodes];
            int pos = 0;
            
            while (pos < allCodeLengths.Count)
            {
                if (DecodeSymbol(codeLengthTable) case .Ok(let symbol))
                {
                    if (symbol < 16)
                    {
                        allCodeLengths[pos++] = (uint8)symbol;
                    }
                    else if (symbol == 16)
                    {
                        if (mBitReader.ReadBits(2) case .Ok(let extraBits))
                        {
                            int count = (int)extraBits + 3;
                            uint8 lastLength = pos > 0 ? allCodeLengths[pos - 1] : 0;
                            for (int i = 0; i < count && pos < allCodeLengths.Count; i++)
                                allCodeLengths[pos++] = lastLength;
                        }
                        else return .Err;
                    }
                    else if (symbol == 17)
                    {
                        if (mBitReader.ReadBits(3) case .Ok(let extraBits))
                        {
                            int count = (int)extraBits + 3;
                            for (int i = 0; i < count && pos < allCodeLengths.Count; i++)
                                allCodeLengths[pos++] = 0;
                        }
                        else return .Err;
                    }
                    else if (symbol == 18)
                    {
                        if (mBitReader.ReadBits(7) case .Ok(let extraBits))
                        {
                            int count = (int)extraBits + 11;
                            for (int i = 0; i < count && pos < allCodeLengths.Count; i++)
                                allCodeLengths[pos++] = 0;
                        }
                        else return .Err;
                    }
                }
                else return .Err;
            }
            
            // Build literal/length table
            mLiteralTable = HuffmanTable();
            for (int i = 0; i < numLiteralCodes; i++)
                mLiteralTable.CodeLengths[i] = allCodeLengths[i];
            mLiteralTable.SymbolCount = numLiteralCodes;
            BuildHuffmanTable(ref mLiteralTable);
            
            // Build distance table
            mDistanceTable = HuffmanTable();
            for (int i = 0; i < numDistanceCodes; i++)
                mDistanceTable.CodeLengths[i] = allCodeLengths[numLiteralCodes + i];
            mDistanceTable.SymbolCount = numDistanceCodes;
            BuildHuffmanTable(ref mDistanceTable);
            
            return .Ok;
        }
        
        return .Err;
    }
    
    private void BuildHuffmanTable(ref HuffmanTable table)
    {
        // Count codes by length
        Internal.MemSet(&table.CodeCounts, 0, sizeof(uint16) * 16);
        for (int i = 0; i < table.SymbolCount; i++)
        {
            if (table.CodeLengths[i] > 0)
                table.CodeCounts[table.CodeLengths[i]]++;
        }
        
        // Generate codes
        uint16[16] code = default;
        for (int i = 1; i < 16; i++)
        {
            code[i] = (uint16)((code[i - 1] + table.CodeCounts[i - 1]) << 1);
        }
        
        // Assign codes to symbols
        for (int i = 0; i < table.SymbolCount; i++)
        {
			Console.WriteLine(i);
            int len = (uint16)table.CodeLengths[i];
            if (len > 0)
            {
                table.Codes[i] = code[len];
                table.Symbols[code[len]] = (uint16)i;
                code[len]++;
            }
        }
    }
    
    private Result<uint16> DecodeSymbol(HuffmanTable table)
    {
        uint32 code = 0;
        
        for (int len = 1; len <= Deflate.MAX_BITS; len++)
        {
            if (mBitReader.ReadBits(1) case .Ok(let bit))
                code = (code << 1) | bit;
            else
                return .Err;
            
            // Check if we have a valid code of this length
            for (int i = 0; i < table.SymbolCount; i++)
            {
                if (table.CodeLengths[i] == len && table.Codes[i] == code)
                    return (uint16)i;
            }
        }
        
        return .Err;
    }
    
    private Result<void> DecompressHuffmanBlock(List<uint8> output)
    {
        while (true)
        {
            if (DecodeSymbol(mLiteralTable) case .Ok(let symbol))
            {
                if (symbol < 256)
                {
                    // Literal byte
                    output.Add((uint8)symbol);
                    mWindow[mWindowPos] = (uint8)symbol;
                    mWindowPos = (mWindowPos + 1) % Deflate.WINDOW_SIZE;
                }
                else if (symbol == 256)
                {
                    // End of block
                    break;
                }
                else
                {
                    // Length/distance pair
                    if (GetLength(symbol) case .Ok(let length) &&
                        DecodeSymbol(mDistanceTable) case .Ok(let distCode) &&
                        GetDistance(distCode) case .Ok(let distance))
                    {
                        // Copy from sliding window
                        int sourcePos = (mWindowPos - distance + Deflate.WINDOW_SIZE) % Deflate.WINDOW_SIZE;
                        for (int i = 0; i < length; i++)
                        {
                            uint8 b = mWindow[sourcePos];
                            output.Add(b);
                            mWindow[mWindowPos] = b;
                            
                            sourcePos = (sourcePos + 1) % Deflate.WINDOW_SIZE;
                            mWindowPos = (mWindowPos + 1) % Deflate.WINDOW_SIZE;
                        }
                    }
                    else return .Err;
                }
            }
            else return .Err;
        }
        
        return .Ok;
    }
    
    private Result<int> GetLength(uint16 symbol)
    {
        if (symbol >= 257 && symbol <= 264)
            return symbol - 254;
        else if (symbol >= 265 && symbol <= 284)
        {
            int extraBits = (symbol - 261) / 4;
            int baseLength = 11 + ((symbol - 265) % 4) * (1 << extraBits) + (1 << extraBits) * ((symbol - 265) / 4);
            
            if (mBitReader.ReadBits(extraBits) case .Ok(let extra))
                return baseLength + (int)extra;
        }
        else if (symbol == 285)
            return 258;
        
        return .Err;
    }
    
    private Result<int> GetDistance(uint16 symbol)
    {
        if (symbol <= 3)
            return symbol + 1;
        else if (symbol <= 29)
        {
            int extraBits = (symbol - 2) / 2;
            int baseDistance = 1 + (2 + (symbol % 2)) * (1 << extraBits);
            
            if (mBitReader.ReadBits(extraBits) case .Ok(let extra))
                return baseDistance + (int)extra;
        }
        
        return .Err;
    }
}