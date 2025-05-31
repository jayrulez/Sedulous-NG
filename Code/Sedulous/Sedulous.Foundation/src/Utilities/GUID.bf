using System;
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
		// Combine all 16 bytes of GUID data
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

	public static Result<GUID> Parse(StringView val)
	{
		return .Err;
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

	public override void ToString(String strBuffer)
	{
		strBuffer.AppendF("{}-{}-{}-{}-{}-{}-{}-{}-{}-{}-{}", mA, mB, mC, mD, mE, mF, mG, mH, mI, mJ, mK);
	}
}