class GUINumericEditFixed extends GUINumericEdit;


function CalcMaxLen()
{
	local int digitcount;
	local float x;

	digitcount=1;
	x=10;
	while (x <= float(MaxValue) )
	{
		digitcount++;
		x*=10;
	}

	MyEditBox.MaxWidth = DigitCount;
}

defaultproperties
{
}
