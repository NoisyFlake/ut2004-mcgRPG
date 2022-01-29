//RPGWeapons are wrappers for normal weapons which pass all functions to the weapon it controls,
//possibly modifying things first. This allows for weapon modifiers in a way that's
//compatible with almost any weapon, as long as no part of that weapon tries to cast Pawn.Weapon (which will always fail)
class RPGWeapon extends Weapon
	DependsOn(RPGStatsInv)
    config(mcgRPG1991)
	CacheExempt;

var() actor lastbase;
var() Weapon ModifiedWeapon;
var() Shader ModifierOverlay;
var() config int MinModifier, MaxModifier; // +1, +2,  etc
var() int Modifier;
var() string RPGWeaponInfo;
var() float AIRatingBonus;
var() localized string Prefix, Postfix;
var() bool bCanHaveZeroModifier;
var() int References; //number of MCGRPG actors referencing this actor
var() RPGStatsInv HolderStatsInv;
var() MutMCGRPG RPGMut;
var() int LastAmmoCharge[NUM_FIRE_MODES]; //used to sync up AmmoCharge between multiple RPGWeapons modifying the same class of weapon
var() hudcdeathmatch.DigitSet DigitsBigPulse;          //link icon drawing hack
var() HudCTeamDeathMatch.NumericWidget totalLinks;
var() HudCTeamDeathMatch.SpriteWidget  LinkIcon;
var() bool bPickupMessageSent;

//see GiveTo() for the miracle that goes with this
struct ChaosAmmoTypeStructClone
{
	var class<Ammunition> AmmoClass;
	var class<WeaponAttachment> Attachment;
	var class<Pickup> Pickup;
	var bool bSuperAmmoLimit;
};
var() array<ChaosAmmoTypeStructClone> ChaosAmmoTypes;

var() weapon twingun; //akimbo hack

var() bool bcheck;  //hack to prevent server crash
var() bool bDone,bAdded,bNoGiveAmmo;

var() config int sanitymax; //cheat - max modifier can this weapon has - prevent server from overcharge
var() inventory previtem;

var() byte maxinv;

var() WeaponPickup PendingPickup[2];

replication
{
	reliable if (bNetOwner && bNetDirty && Role == ROLE_Authority)
		ModifiedWeapon, Modifier;
    reliable if ( Role == ROLE_Authority )
        twingun;
    reliable if ( Role == ROLE_Authority )
        clientsetmodifier,clientweaponhack;
	reliable if (Role < ROLE_Authority)
		ChangeAmmo, ChaosWeaponOption, ReloadMeNow, FinishReloading, ServerForceUpdate, weaponhack, serverthrow;
}

//RPG functions
simulated function lostchild(actor other)
{
    if(weaponpickup(other) != none )
    {
        removereference();
    }
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	return true;
}

static function float AdjustBotDesire(bot b)
{
    return 0;
}

static function string magicname()
{
    local array<string> s;
    local int i;
    if(default.Postfix!="")
    {
        i=split(default.Postfix," ",s);
        return s[i-1];
    }
    else return left(default.Prefix,len(default.Prefix)-1 );
}

function Generate(RPGWeapon ForcedWeapon)
{
	local int Count;

	if (ForcedWeapon != None)
		Modifier = ForcedWeapon.Modifier;
	else if (MaxModifier != 0 || MinModifier != 0)
	{
		do
		{
			Modifier = Rand(MaxModifier+1-MinModifier) + MinModifier;
			Count++;
		} until (Modifier != 0 || bCanHaveZeroModifier || Count > 1000)
	}
}

simulated function SetHolderStatsInv()
{
	local Inventory Inv;
	if(instigator==none)
	    return;
    if(instigator.Controller!=none)
	    for (Inv = Instigator.Controller.Inventory; Inv != None; Inv = Inv.Inventory)
	    {
		    HolderStatsInv = RPGStatsInv(Inv);
		    if (HolderStatsInv != None)
		    {
		        if(RPGMut == none)
		            RPGMut = holderstatsinv.RPGMut;
			    return;
		    }
	    }

	//fallback
	HolderStatsInv = RPGStatsInv(Instigator.FindInventoryType(class'RPGStatsInv'));
	if (HolderStatsInv != None && RPGMut == none)
        RPGMut = holderstatsinv.RPGMut;
}

function SetModifiedWeapon(Weapon w, bool bIdentify)
{
	if (w == None)
	{
		Destroy();
		return;
	}
	ModifiedWeapon = w;
	SetWeaponInfo();
	if (bIdentify)
	{
		Instigator = None; //don't want to send an identify message to anyone here
		Identify();
	}
}

simulated function SetWeaponInfo()
{
	local int x;

	ModifiedWeapon.Instigator = Instigator;
	ModifiedWeapon.SetOwner(Owner);
	constructitemname();
	AIRating = ModifiedWeapon.AIRating;
	InventoryGroup = ModifiedWeapon.InventoryGroup;
    GroupOffset = modifiedweapon.GroupOffset;
	IconMaterial = ModifiedWeapon.IconMaterial;
	IconCoords = ModifiedWeapon.IconCoords;
	Priority = ModifiedWeapon.Priority;
	PlayerViewOffset = ModifiedWeapon.PlayerViewOffset;
	DisplayFOV = ModifiedWeapon.DisplayFOV;
	EffectOffset = ModifiedWeapon.EffectOffset;
	bSniping = ModifiedWeapon.bSniping;
	bMeleeWeapon = ModifiedWeapon.bMeleeWeapon;
	bMatchWeapons = ModifiedWeapon.bMatchWeapons;
	bShowChargingBar = ModifiedWeapon.bShowChargingBar;
	bCanThrow = ModifiedWeapon.bCanThrow;
	bNoAmmoInstances = ModifiedWeapon.bNoAmmoInstances;
	HudColor = ModifiedWeapon.HudColor;
	CustomCrossHairColor = ModifiedWeapon.CustomCrossHairColor;
	CustomCrossHairScale = ModifiedWeapon.CustomCrossHairScale;
	CustomCrossHairTextureName = ModifiedWeapon.CustomCrossHairTextureName;
	PickupClass = ModifiedWeapon.PickupClass;
	for (x = 0; x < NUM_FIRE_MODES; x++)
	{
		FireMode[x] = ModifiedWeapon.FireMode[x];
		FireModeclass[x] = ModifiedWeapon.FireModeclass[x];
		Ammo[x] = ModifiedWeapon.Ammo[x];
		AmmoClass[x] = ModifiedWeapon.AmmoClass[x];
	}

    if(twingun!=none)
    {
	    twingun.Instigator = Instigator;
	    twingun.SetOwner(Owner);
	}
}

function Identify()
{
    local PlayerController p;
	if (Modifier == 0 && !bCanHaveZeroModifier)
		return;

	ConstructItemName();
    if(Instigator != None )
    {
        if(Instigator.Controller != None)
            p = PlayerController(Instigator.Controller);
        else if(Instigator.DrivenVehicle != none && Instigator.DrivenVehicle.Controller != none)
            p = PlayerController(Instigator.DrivenVehicle.Controller);
    }
	if (p != None)
		p.ReceiveLocalizedMessage(class'identifymessage', 0,,, self);
	if (ModifiedWeapon.OverlayMaterial == None && ModifierOverlay != none)
		SetOverlayMaterial(ModifierOverlay, 1000000.0, true);
}

simulated function ConstructItemName()
{
	if (Modifier > 0)
		ItemName = Prefix$ModifiedWeapon.ItemName$Postfix@"+"$Modifier;
	else
		ItemName = Prefix$ModifiedWeapon.ItemName$Postfix;
}

//return true to allow player to have w
function bool AllowRPGWeapon(RPGWeapon w)
{
    local PlayerController p;
	if (Class == w.Class && ModifiedWeapon.Class == w.ModifiedWeapon.Class )
	{
	    if(Modifier < w.Modifier )
	    {
	        if(Instigator != None )
	        {
                if(Instigator.Controller != None)
                    p = PlayerController(Instigator.Controller);
                else if(Instigator.DrivenVehicle != none && Instigator.DrivenVehicle.Controller != none)
                    p = PlayerController(Instigator.DrivenVehicle.Controller);
            }
	        modifier=w.Modifier;
	        constructitemname();
	        clientsetmodifier(modifier);
	        if (p != None)
		        p.ReceiveLocalizedMessage(class'identifymessage', 0,,, self);
        }
		return false;
	}
	return true;
}

simulated function clientsetmodifier(int newmodifier)
{
    if(role == role_authority)
        return;
    modifier = newmodifier;
    if(modifiedweapon != none)
        constructitemname();
}
//adjust damage to the enemies of the wielder of this weapon
function AdjustTargetDamage(out int Damage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType);

//FIXME compatibility hack
function NewAdjustTargetDamage(out int Damage, int OriginalDamage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	AdjustTargetDamage(Damage, Victim, HitLocation, Momentum, DamageType);
}

//This is used to prevent the RPGWeapon from getting destroyed until nothing needs it
function RemoveReference()
{
	References--;
	if (References <= 0)
		Destroy();
}

//I'm sure I don't need to explain the magnitude of this awful hack
exec function ChangeAmmo()
{
	if (ModifiedWeapon!=none && instigator!=none && PlayerController(Instigator.Controller) != None)
	{
		Instigator.Weapon = ModifiedWeapon;
		PlayerController(Instigator.Controller).ConsoleCommand("ChangeAmmo");
		Instigator.Weapon = self;
		FireMode[0] = ModifiedWeapon.FireMode[0];
		FireMode[1] = ModifiedWeapon.FireMode[1];
		Ammo[0] = ModifiedWeapon.Ammo[0];
		Ammo[1] = ModifiedWeapon.Ammo[1];
		AmmoClass[0] = ModifiedWeapon.AmmoClass[0];
		AmmoClass[1] = ModifiedWeapon.AmmoClass[1];
		ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
	}
}

//Yet more ugly hacking... but at least it's for a good cause
exec function ChaosWeaponOption()
{
	if (ModifiedWeapon!=none  && instigator!=none && PlayerController(Instigator.Controller) != None)
	{
		Instigator.Weapon = ModifiedWeapon;
		PlayerController(Instigator.Controller).ConsoleCommand("ChaosWeaponOption");
		Instigator.Weapon = self;
	}
}

//the next two are for Remote Strike
//why someone would want to play a realism mod with magic weapons is beyond me
exec function ReloadMeNow()
{
	if (instigator!=none && PlayerController(Instigator.Controller) != None)
	{
		Instigator.Weapon = ModifiedWeapon;
		PlayerController(Instigator.Controller).ConsoleCommand("ReloadMeNow");
		Instigator.Weapon = self;
	}
}

exec function FinishReloading()
{
	if (instigator!=none && PlayerController(Instigator.Controller) != None)
	{
		Instigator.Weapon = ModifiedWeapon;
		PlayerController(Instigator.Controller).ConsoleCommand("FinishReloading");
		Instigator.Weapon = self;
	}
}

function ServerForceUpdate()
{
	NetUpdateTime = Level.TimeSeconds - 1;
}

function dropped(weaponpickup p)
{
    local int m, x;
    local Inventory Inv;
    local RPGWeapon W;
    local RPGStatsInv StatsInv;
    local RPGStatsInv.OldRPGWeaponInfo MyInfo;
    local bool bFoundAnother, bAlreadyDropped;
	local RPGWeapon OldRPGWeapon;

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m] != none && FireMode[m].bIsFiring)
        {
            clientstopfire(m);
            StopFire(m);
        }
    }
    References++;
    if (p.Instigator.Health > 0)
   	{
        //only toss 1 ammo if have another weapon of the same class
        for (Inv = p.Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
        {
            W = RPGWeapon(Inv);
            if (W != None && W != self && w.ModifiedWeapon!=none  && ModifiedWeapon!=none  && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
            {
				bFoundAnother = true;
				if (W != None && W.bNoAmmoInstances)
				{
				    if (W != None && w.ModifiedWeapon!=none  && AmmoClass[0] != None)
				        W.ModifiedWeapon.AmmoCharge[0] -= 1;
                    if (W != None && w.ModifiedWeapon!=none  && AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
				        W.ModifiedWeapon.AmmoCharge[1] -= 1;
				}
            }
        }
        if (bFoundAnother)
        {
            if (AmmoClass[0] != None)
            {
				p.AmmoAmount[0] = 1;
				if (!bNoAmmoInstances)
				    Ammo[0].AmmoAmount -= 1;
            }
            if (AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
            {
				p.AmmoAmount[1] = 1;
				if (!bNoAmmoInstances)
				    Ammo[1].AmmoAmount -= 1;
            }
            if (!bNoAmmoInstances)
            {
				Ammo[0] = None;
				Ammo[1] = None;
				if(ModifiedWeapon!=none  )
				{
                    ModifiedWeapon.Ammo[0] = None;
                    ModifiedWeapon.Ammo[1] = None;
                }
            }
        }
    }
    ClientWeaponThrown();
	twingun=none;
    SetTimer(0, false);
    if (Instigator != None)
    {
        StatsInv = RPGStatsInv(Instigator.FindInventoryType(class'RPGStatsInv') );
        Instigator.DeleteInventory(self);
    }
    else
    {
   	    StatsInv = RPGStatsInv(p.Instigator.FindInventoryType(class'RPGStatsInv') );
        p.Instigator.DeleteInventory(self);
    }
    if (StatsInv != None)
    {
        for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
            if (StatsInv.OldRPGWeapons[x].ModifiedClass == modifiedweapon.Class)
            {
				OldRPGWeapon = StatsInv.OldRPGWeapons[x].Weapon;
				if (OldRPGWeapon == None)
				{
				    StatsInv.OldRPGWeapons.Remove(x, 1);
				    x--;
				}
				else
				{
                    bAlreadyDropped = true;
				    if(Class != OldRPGWeapon.Class || modifier != oldRPGweapon.modifier)
				    {
				        StatsInv.OldRPGWeapons[x].Weapon = self;
    	                References++;
		                OldRPGWeapon.RemoveReference();
                    }
				    break;
				}
            }
        if(!bAlreadyDropped)
        {
            MyInfo.ModifiedClass = ModifiedWeapon.Class;
            MyInfo.Weapon = self;
    	    StatsInv.OldRPGWeapons[StatsInv.OldRPGWeapons.length] = MyInfo;
    	    References++;
   	    }
    }
	for (m = 0; m < NUM_FIRE_MODES; m++)
		FireMode[m] = None;

    disable('tick');
}

function NewAdjustPlayerDamage( out int Damage, int originaldamage, Pawn InstigatedBy, Vector HitLocation,
                             out Vector Momentum, class<DamageType> DamageType);

function serverthrow(bool bEnable)
{
    if(instigator != none && instigator.Weapon == self && ModifiedWeapon != none)
        ModifiedWeapon.bCanThrow = (bEnable && bCanThrow);
}

function weaponhack(bool re)
{
    if(instigator==none || role < role_authority )
        return;
    if(!re)
    {
        instigator.Weapon=modifiedweapon;
        bcheck=true;                                 //try to prevent server crash by packetloss
        settimer(0.01,false);
    }
    else if(re)
    {
        instigator.Weapon=self;
        bcheck=false;
        settimer(0.0,false);
    }
}

simulated function SyncUpAmmoCharges(int m)
{
	local Inventory Inv;
	local RPGWeapon W;
	local int x,y;
    if(ModifiedWeapon==none || m < 0)
        return;

    if(m < NUM_FIRE_MODES)
    {
	    LastAmmoCharge[m] = ModifiedWeapon.AmmoCharge[m];

        if(instigator == none)
            return;
	    for (Inv = Instigator.Inventory; Inv != None && x < 1000; Inv = Inv.Inventory)
	    {
	        x++;
		    W = RPGWeapon(Inv);
		    if(W != None && W != self && W.bNoAmmoInstances && W.ModifiedWeapon != None && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
		    {
			    W.ModifiedWeapon.AmmoCharge[m] = ModifiedWeapon.AmmoCharge[m];
			    W.LastAmmoCharge[m] = LastAmmoCharge[m];
			    W.ModifiedWeapon.NetUpdateTime = Level.TimeSeconds - 1;
		    }
	    }
	    return;
    }

    for(y = 0; y < NUM_FIRE_MODES; y++)
        LastAmmoCharge[y] = ModifiedWeapon.AmmoCharge[y];
    if(instigator == none)
        return;
	for (Inv = Instigator.Inventory; Inv != None && x < 1000; Inv = Inv.Inventory)
	{
	    x++;
		W = RPGWeapon(Inv);
		if(W != None && W != self && W.bNoAmmoInstances && W.ModifiedWeapon != None && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
		{
		    for(y = 0; y < NUM_FIRE_MODES; y++)
		    {
			    W.ModifiedWeapon.AmmoCharge[y] = ModifiedWeapon.AmmoCharge[y];
			    W.LastAmmoCharge[y] = LastAmmoCharge[y];
			}
			W.ModifiedWeapon.NetUpdateTime = Level.TimeSeconds - 1;
		}
	}
}

simulated function DestroyModifiedWeapon()
{
	local int i;

	//after ModifiedWeapon gets destroyed, the FireMode array will become bogus pointers since they're not actors
	//so have to manually set to None
	for (i = 0; i < NUM_FIRE_MODES; i++)
		FireMode[i] = None;

    disable('tick');
	if (ModifiedWeapon != None && !ModifiedWeapon.bPendingDelete)
		ModifiedWeapon.Destroy();
}

simulated function clientweaponhack(bool re,optional weapon w)
{
    if(instigator==none || role == role_authority )
        return;
    if(!re)
    {
        instigator.Weapon=modifiedweapon;
        bcheck=true;
        settimer(0.1,false);
    }
    else if(re)
    {
        if(w != none && w.ClientState != WS_BringUp)
            w.BringUp();
        instigator.Weapon=self;
        bcheck=false;
        if(ClientState != WS_BringUp && ClientState != WS_PutDown)
            settimer(0.0,false);
    }
}

static function string getinfo()
{
    local string s;
    s = default.RPGWeaponInfo $ " Maximum modifier: "$default.maxmodifier$", minimum modifier: "$default.minmodifier;
    return s;
}

//Weapon functions
simulated function float ChargeBar()
{
    if (ModifiedWeapon != None)
	    return ModifiedWeapon.ChargeBar();
}

simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
    if (ModifiedWeapon != None)
    {
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.GetAmmoCount(MaxAmmoPrimary, CurAmmoPrimary);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
    }
}

simulated function DrawWeaponInfo(Canvas C)
{
    if (ModifiedWeapon != None)
    {
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.DrawWeaponInfo(C);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
    }
}

simulated function NewDrawWeaponInfo(Canvas C, float YPos)
{
    if (ModifiedWeapon != None)
    {
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.NewDrawWeaponInfo(C, YPos);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
    }
	if(instigator==none)
	    return;
	if ( linkgun(modifiedweapon)!=none && linkgun(modifiedweapon).Links > 0 && level.NetMode!=nm_dedicatedserver &&
        playercontroller(instigator.Controller)!=none && hudbase(playercontroller(instigator.Controller).myHUD)!=none)
	{
		hudbase(playercontroller(instigator.Controller).myHUD).DrawSpriteWidget (C, LinkIcon);
	    hudbase(playercontroller(instigator.Controller).myHUD).DrawNumericWidget (C, totalLinks, DigitsBigPulse);
	    totalLinks.value = linkgun(modifiedweapon).Links;
    }

}

function OwnerEvent(name EventName)
{
    local weapon w;
	Super.OwnerEvent(EventName);
	if (EventName == 'ChangedWeapon' && instigator != none)
	{
	    w = instigator.Weapon;
	    if(w == none)
	        return;
        if( w == modifiedweapon || w == twingun)
        {
            instigator.Weapon.PutDown();
            if( holderstatsinv != none && !instigator.IsLocallyControlled() )
                holderstatsinv.ClientSwitchWeapon(modifiedweapon, self);
            instigator.ServerChangedWeapon(modifiedweapon, self);
        }
        if(Instigator.Weapon == self && ModifierOverlay != none)
            SetOverlayMaterial(ModifierOverlay, 1000000, false);
    }
}

function float RangedAttackTime()
{
	return ModifiedWeapon.RangedAttackTime();
}

function bool RecommendRangedAttack()
{
	return ModifiedWeapon.RecommendRangedAttack();
}

function bool RecommendLongRangedAttack()
{
	return ModifiedWeapon.RecommendLongRangedAttack();
}

function bool FocusOnLeader(bool bLeaderFiring)
{
	local Bot B;
	local Pawn LeaderPawn;
	local Actor Other;
	local vector HitLocation, HitNormal, StartTrace;
	local Vehicle V;
    if(linkgun(ModifiedWeapon) == none )
	    return ModifiedWeapon != none && ModifiedWeapon.FocusOnLeader(bLeaderFiring);

	B = Bot(Instigator.Controller);
	if ( B == None )
		return false;
	if ( PlayerController(B.Squad.SquadLeader) != None )
		LeaderPawn = B.Squad.SquadLeader.Pawn;
	else
	{
		V = B.Squad.GetLinkVehicle(B);
		if ( V != None )
		{
			LeaderPawn = V;
			bLeaderFiring = (v.Health < v.HealthMax) && (V.LinkHealMult > 0) && ((B.Enemy == None) || V.bKeyVehicle);
		}
	}
	if ( LeaderPawn == None )
	{
		LeaderPawn = B.Squad.SquadLeader.Pawn;
		if ( LeaderPawn == None )
			return false;
	}
	if ( !bLeaderFiring && (LeaderPawn.Weapon == None || !LeaderPawn.Weapon.IsFiring()) )
		return false;
	if ( (Vehicle(LeaderPawn) != None) || ( (LinkGun(LeaderPawn.Weapon) != None || (RPGWeapon(LeaderPawn.Weapon) != None &&
        LinkGun(RPGWeapon(LeaderPawn.Weapon).ModifiedWeapon) != None)) && ((vector(B.Squad.SquadLeader.Rotation) dot Normal(Instigator.Location - LeaderPawn.Location)) < 0.9) ) )
	{
		StartTrace = Instigator.Location + Instigator.EyePosition();
		if ( VSize(LeaderPawn.Location - StartTrace) < LinkFire(FireMode[1]).TraceRange )
		{
			Other = Trace(HitLocation, HitNormal, LeaderPawn.Location, StartTrace, true);
			if ( Other == LeaderPawn )
			{
				B.Focus = Other;
				return true;
			}
		}
	}
	return false;
}

function FireHack(byte Mode)
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.FireHack(Mode);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

function bool SplashDamage()
{
	return ModifiedWeapon.SplashDamage();
}

function bool RecommendSplashDamage()
{
	return ModifiedWeapon.RecommendSplashDamage();
}

function float GetDamageRadius()
{
	return ModifiedWeapon.GetDamageRadius();
}

function float RefireRate()
{
	return ModifiedWeapon.RefireRate();
}

function bool FireOnRelease()
{
	return ModifiedWeapon.FireOnRelease();
}

simulated function Loaded()
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
    ModifiedWeapon.Loaded();
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	local string T;
	local int i;
	Canvas.SetDrawColor(255,255,255);

	Canvas.DrawText(getitemname(string(class) ) );
	YPos += YL;
	Canvas.SetPos(4,YPos);
	if(ModifiedWeapon != none)
	{
		if ( ModifiedWeapon.Skins.length > 0 )
		{
			T = "skins: ";
			for ( i=0; i<ModifiedWeapon.Skins.length; i++ )
			{
				if ( ModifiedWeapon.skins[i] == None )
					break;
				else
					T =T$GetItemName(string(ModifiedWeapon.skins[i]))$", ";
			}
		}

		Canvas.DrawText(T, false);
	    YPos += YL;
	    Canvas.SetPos(4,YPos);

	    Canvas.DrawText("ModifiedWeapon: "$ModifiedWeapon);
	    YPos += YL;
	    Canvas.SetPos(4,YPos);
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.DisplayDebug(Canvas, YL, YPos);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
    }
}

simulated function bool AmmoMaxed(int mode)
{
	return ModifiedWeapon != none && ModifiedWeapon.AmmoMaxed(mode);
}

simulated function Weapon RecommendWeapon( out float rating )
{
    local Weapon Recommended;
    local bot b;
    local float oldRating;
    if ( Instigator == None || Instigator.Controller == None || IsInState('PendingClientWeaponSet') )
        rating = -2;
    else
    {
        b = bot(Instigator.Controller);
	    if ( b != none && b.bPreparingMove && ( (b.MoveTarget != none && b.bHasTranslocator && (b.skill >= 2) && b.TranslocationTarget == b.MoveTarget &&
            b.RealTranslocationTarget == b.MoveTarget && b.ImpactTarget == b.MoveTarget && b.Focus == b.MoveTarget) || (jumpspot(B.Focus) != none && B.CanUseTranslocator() &&
            B.ImpactTarget == B.Focus && B.RealTranslocationTarget == B.Focus && Instigator.Acceleration == vect(0,0,0) && (B.TranslocationTarget == B.Focus ||
            (jumpspot(B.Focus).TranslocTargetTag != '' && B.TranslocationTarget != none && B.TranslocationTarget.Tag == jumpspot(B.Focus).TranslocTargetTag) ) ) ) &&
            rpgweapon(Instigator.Weapon) != none && rpgweapon(Instigator.Weapon).ModifiedWeapon != none && rpgweapon(Instigator.Weapon).ModifiedWeapon.IsA('TransLauncher') )
        {
            rpgweapon(Instigator.Weapon).ModifiedWeapon.SetTimer(0.2,false);
            return none;
	    }
	    if ( !HasAmmo() )
            Rating = -2;
	    else
        {
            if(Instigator.Weapon == self)
                Instigator.Weapon = ModifiedWeapon;
            rating = RateSelf() + Instigator.Controller.WeaponPreference(ModifiedWeapon);
            if(Instigator.Weapon == ModifiedWeapon)
                Instigator.Weapon = self;
        }
    }
    oldrating = rating;
    if(maxinv > 0)
    {
        if(Rating > -2)
            return self;
        else
            return none;
    }
    if ( inventory != None )
    {
        Recommended = inventory.RecommendWeapon(oldRating);
        if ( (Recommended != None) && (oldRating > rating) )
        {
            rating = oldRating;
            return Recommended;
        }
    }
    if(Rating > -2)
        return self;
    else
        return none;
}

function SetAITarget(Actor T)
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.SetAITarget(T);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

function byte BestMode()
{
	return ModifiedWeapon.BestMode();
}

function bool BotFire(bool bFinished, optional name FiringMode)
{
	local bool bResult;
	local Bot B;

    if(Instigator != None )
	    B = Bot(Instigator.Controller);
	if ( B != None && linkgun(ModifiedWeapon) != none && FocusOnLeader(B.Focus == B.Squad.SquadLeader.Pawn) )
    {

		b.bFire = 0;
		b.bAltFire = 1;

	    if ( bFinished )
		    return true;

        if ( FireMode[BotMode].IsFiring() )
        {
    	    if (BotMode == 1)
    		    return true;
    	    else
			    StopFire(BotMode);
        }

        if ( !ReadyToFire(1) || ClientState != WS_ReadyToFire )
		    return false;

        BotMode = 1;
        StartFire(1);
        return true;
    }

    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	bResult = ModifiedWeapon.BotFire(bFinished, FiringMode);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
	BotMode = ModifiedWeapon.BotMode;
	return bResult;
}

simulated function vector GetFireStart(vector X, vector Y, vector Z)
{
	return ModifiedWeapon.GetFireStart(X, Y, Z);
}

simulated function float AmmoStatus(optional int Mode)
{
    if (ModifiedWeapon != None)
		return ModifiedWeapon.AmmoStatus(mode);
}

simulated function float RateSelf()
{
    if(Instigator == None  || Instigator.Controller == None || ModifiedWeapon == none)
        return 0.0;
    if( AIController(Instigator.Controller) == None)
        return ModifiedWeapon.RateSelf();
    if ( !HasAmmo() )
        return -2;
	return Instigator.Controller.RateWeapon(self);
}

function float GetAIRating()
{
	local Bot B;

    if(Instigator != None )
	    B = Bot(Instigator.Controller);
	if ( B == None || linkgun(ModifiedWeapon) == none || PlayerController(B.Squad.SquadLeader) == None || B.Squad.SquadLeader.Pawn == None ||
        ( LinkGun(B.Squad.SquadLeader.Pawn.Weapon) == None && (RPGWeapon(B.Squad.SquadLeader.Pawn.Weapon) == None ||
        LinkGun(RPGWeapon(B.Squad.SquadLeader.Pawn.Weapon).ModifiedWeapon) == None) ) )
		return ModifiedWeapon.GetAIRating() + AIRatingBonus * (1 + Modifier);
	return 1.2 + AIRatingBonus * (1 + Modifier);
}

function float SuggestAttackStyle()
{
	return ModifiedWeapon.SuggestAttackStyle();
}

function float SuggestDefenseStyle()
{
	return ModifiedWeapon.SuggestDefenseStyle();
}

function bool SplashJump()
{
	return ModifiedWeapon.SplashJump();
}

function bool CanAttack(Actor Other)
{
	return ModifiedWeapon.CanAttack(Other);
}

simulated function Destroyed()
{
    DestroyModifiedWeapon();
	Super.Destroyed();
}

simulated function Reselect()
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.Reselect();
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

simulated function bool WeaponCentered()
{
	return ModifiedWeapon.WeaponCentered();
}

simulated function RenderOverlays(Canvas Canvas)
{
    if (ModifiedWeapon != None)
    {
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.RenderOverlays(Canvas);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
        hand = ModifiedWeapon.Hand;
        SetLocation( ModifiedWeapon.Location );
        SetRotation( ModifiedWeapon.Rotation );
	    PlayerViewOffset = ModifiedWeapon.PlayerViewOffset;
	    DisplayFOV = ModifiedWeapon.DisplayFOV;
	    EffectOffset = ModifiedWeapon.EffectOffset;
	}
}

simulated function PreDrawFPWeapon()
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
    if (ModifiedWeapon != None)
	    ModifiedWeapon.PreDrawFPWeapon();
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

simulated function SetHand(float InHand)
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	Hand = InHand;
	ModifiedWeapon.SetHand(Hand);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

simulated function GetViewAxes(out vector xaxis, out vector yaxis, out vector zaxis)
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.GetViewAxes(xaxis, yaxis, zaxis);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

simulated function vector CenteredEffectStart()
{
	return ModifiedWeapon.CenteredEffectStart();
}

simulated function vector GetEffectStart()
{
	return ModifiedWeapon.GetEffectStart();
}

simulated function IncrementFlashCount(int Mode)
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.IncrementFlashCount(Mode);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

simulated function ZeroFlashCount(int Mode)
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.ZeroFlashCount(Mode);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
}

function HolderDied()
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.HolderDied();
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;

	// set the controller's last pawn weapon to modified weapon so stats work properly
	if (Instigator.Controller != None)
		Instigator.Controller.LastPawnWeapon = ModifiedWeapon.Class;
}

function bool CanThrow()
{
	return ModifiedWeapon.CanThrow();
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
    local int m;
    local weapon w;
    local rpgweapon rw;
    local bool bPossiblySwitch, bJustSpawned,bfoundakimbo,bwrong;
    local Inventory Inv,i;
    local controller c;

    c = other.Controller;
    if(c == none && other.DrivenVehicle != none)
        c = other.DrivenVehicle.Controller;
    if(c == none)
    {
        destroy();
        return;
    }
    bAdded = true;
    Instigator = Other;
    ModifiedWeapon.Instigator = Other;
    if( modifiedweapon.GetPropertyText("bDualGun")!="False")
    {
        if(previtem == none)
        {
            for (Inv = instigator.Inventory; inv!=none; Inv = Inv.Inventory)
            {
    	        if (Inv.Class == ModifiedWeapon.Class || (RPGWeapon(Inv) != None && !RPGWeapon(Inv).AllowRPGWeapon(Self)))
    	        {
		            W = Weapon(Inv);
		            break;
 	            }
    	        m++;
    	        if (m > 1000)
    		        break;
    	        if (Inv.Inventory == None) //hack to keep Inv at last item in Instigator's inventory
    		        break;
             }
        }
        else inv = previtem;
    }
    else     //hack for akimbo arena
    {
        for (Inv = Instigator.Inventory; inv!=none; Inv = Inv.Inventory)
        {
            if ( (Inv.Class == ModifiedWeapon.Class && inv.GetPropertyText("TwinGun")~="None" ) ||
                (RPGWeapon(Inv) != None && RPGWeapon(Inv).modifiedweapon.GetPropertyText("TwinGun")~="None"  ) )
   	        {
		        W = none;
		        rw=rpgweapon(inv);
		        bfoundakimbo=true;
		        break;
 	        }
    	    else if ( (Inv.Class == ModifiedWeapon.Class && !(inv.GetPropertyText("TwinGun")~="None") ) || (RPGWeapon(Inv) != None &&
                !RPGWeapon(Inv).AllowRPGWeapon(Self) && !(RPGWeapon(Inv).modifiedweapon.GetPropertyText("TwinGun")~="None")  ) )
	        {
		        W = Weapon(Inv);
		        break;
 	        }
    	    m++;
    	    if (m > 1000)
    		    break;
   	        if (Inv.Inventory == None) //hack to keep Inv at last item in Instigator's inventory
    		    break;
        }
        if(w == none && !bfoundakimbo && modifiedweapon.GetPropertyText("TwinGun")!="None" && twingun == none)
        {
            m = 0;
            foreach instigator.ChildActors(Class'weapon', w)
            {
                if( w.Class == modifiedweapon.Class && w.GetPropertyText("TwinGun")!="None" && w.GetPropertyText("bDualGun")~="True")
                {
                    for(i = Instigator.Inventory; i!=none && m == 0; I = I.Inventory)
                    {
                        if(rpgweapon(i) != none && rpgweapon(i).twingun == w)
                        {
                            bwrong = true;
                            m = 1;
                        }
                    }
                    if(!bwrong)
                    {
                        twingun = w;
                        break;
                    }
                }
            }
            w = none;
        }
        if(w==none && bfoundakimbo)
        {
            if(rw!=none)
            {
                if(other.Weapon==rw)
                {
                    other.Weapon=rw.ModifiedWeapon;
                    rw.clientweaponhack(false);
                }
                rw.ModifiedWeapon.inventory=rw.Inventory;
                rw.inventory=rw.ModifiedWeapon;
            }
            if(ModifiedWeapon.ThirdPersonActor != none)
                ModifiedWeapon.DetachFromPawn(other);
            modifiedweapon.GiveTo(other,pickup);
            if(rw!=none)
            {
                if(other.Weapon==rw.ModifiedWeapon)
                {
                    other.Weapon=rw;
                    rw.clientweaponhack(true,ModifiedWeapon);
                }
                rw.inventory = rw.ModifiedWeapon.inventory;
                rw.ModifiedWeapon.inventory = none;
                rw.twingun=modifiedweapon;
                if( (rw.ThirdPersonActor == none || rw.ThirdPersonActor.bPendingDelete) && rw.ModifiedWeapon.ThirdPersonActor != none &&
                    !rw.ModifiedWeapon.ThirdPersonActor.bPendingDelete)
                    rw.ThirdPersonActor = rw.ModifiedWeapon.ThirdPersonActor;
                if(rw.ModifierOverlay != none)
                    rw.SetOverlayMaterial(rw.ModifierOverlay,1000000,true);
                rw.bDone = false;
            }
            modifiedweapon=none;
            destroy();
            return;
        }
    }
    previtem = none;
    if ( W == None )
    {
        if(translauncher(modifiedweapon) != none && bot(instigator.Controller) != none)
            bot(instigator.Controller).bHasTranslocator = true;
	    else if (shieldgun(modifiedweapon) != none && Bot(instigator.Controller) != None )
		    Bot(Other.Controller).bHasImpactHammer = true;
	    //hack - manually add to Instigator's inventory because pawn won't usually allow duplicates
	    if(inv != none)
	        Inv.Inventory = self;
        else instigator.Inventory = self;
	    Inventory = None;
	    SetOwner(Instigator);
	    netupdatetime=level.TimeSeconds-1;
	    if (Instigator.Controller != None)
		    Instigator.Controller.NotifyAddInventory(self);

        bJustSpawned = true;
        ModifiedWeapon.SetOwner(Owner);
        modifiedweapon.netupdatetime=level.TimeSeconds-1;
        bPossiblySwitch = true;
        W = self;
    }
    else if ( !W.HasAmmo() )
	    bPossiblySwitch = true;

    if ( Pickup == None )
        bPossiblySwitch = true;

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if(twingun!=none && !twingun.bDeleteMe && twingun.FireMode[m]!=none )
            twingun.FireMode[m].Instigator=instigator;
        if ( FireMode[m] != None )
        {
            FireMode[m].Instigator = Instigator;
            W.GiveAmmo(m,WeaponPickup(Pickup),bJustSpawned);
        }
    }

	if ( (Instigator.Weapon != None) && Instigator.Weapon.IsFiring() )
		bPossiblySwitch = false;

    if ( bJustSpawned )
    {
        if(ModifierOverlay != none)
            SetOverlayMaterial(ModifierOverlay,1000000.0,true);
        else
            SetOverlayMaterial(none,0.0,true);
    }
	if ( (rpgweapon(w) == none || !rpgweapon(w).bcheck ) && Instigator.Weapon != W )
	{
		if (Other.Controller == none && playercontroller(c) != none && rpgweapon(w) != none && rpgweapon(w).ModifiedWeapon != none )
		    rpgweapon(w).modifiedweapon.ClientWeaponSet(false);
		W.ClientWeaponSet(bPossiblySwitch);
	}


    if ( !bJustSpawned )
    {
        for (m = 0; m < NUM_FIRE_MODES; m++)
        {
            Ammo[m] = None;
            ModifiedWeapon.Ammo[m] = None;
        }
	    Destroy();
	    return;
    }
    else
    {
        setholderstatsinv();
    	//Hack for ChaosUT: spawn ChaosWeapon's ammo and make sure it sets up its firemode for the type of chaos ammo owner has
        if (ModifiedWeapon.IsA('ChaosWeapon'))
    	{
    		ModifiedWeapon.SetPropertyText("OldCount", "-1");
    		ModifiedWeapon.Tick(0.f);
    		if (!ModifiedWeapon.bNoAmmoInstances)
    		{
    			//add initial ammo, if we haven't already via the GiveAmmo() call above
    			if (ModifiedWeapon.FireMode[0].default.AmmoClass == None)
    			{
	    			if (ModifiedWeapon.Ammo[0] == None)
	    			{
	    				ModifiedWeapon.Ammo[0] = spawn(ModifiedWeapon.AmmoClass[0]);
	    				ModifiedWeapon.Ammo[0].GiveTo(Other);
	    			}
	    			if (WeaponPickup(Pickup) != None && WeaponPickup(Pickup).AmmoAmount[0] > 0)
					    ModifiedWeapon.Ammo[0].AddAmmo(WeaponPickup(Pickup).AmmoAmount[0]);
			    	else
					    ModifiedWeapon.Ammo[0].AddAmmo(ModifiedWeapon.Ammo[0].InitialAmount);
				}
			}

            //Spawn empty ammo for the other types, if necessary
            if (!Level.Game.IsA('ChaosDuel') || int(Level.Game.GetPropertyText("WeaponOption")) != 3)
            {
                //fill our clone ammo array with a copy of the contents from the weapon's array
                //can you believe this actually works?!
                //I've written a lot of hacks... it's part of being a mod author
				//But this... wow. Just wow.
  		        SetPropertyText("ChaosAmmoTypes", ModifiedWeapon.GetPropertyText("AmmoType"));

                for (m = 0; m < ChaosAmmoTypes.length; m++)
                {
                    Inv = Instigator.FindInventoryType(ChaosAmmoTypes[m].AmmoClass);
                    if (Inv == None)
                    {
                        Inv = spawn(ChaosAmmoTypes[m].AmmoClass);
                        Inv.GiveTo(Instigator);
                    }
                }
            }
		}
 	}

	for (m = 0; m < NUM_FIRE_MODES; m++)
		Ammo[m] = ModifiedWeapon.Ammo[m];
}

function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
	local Inventory Inv;
	local RPGWeapon W;
	if(Instigator == none)
	    return;
    if(ModifiedWeapon!=none )
    {
        if(!bNoGiveAmmo)
	        ModifiedWeapon.GiveAmmo(m, WP, bJustSpawned);
		Ammo[m] = ModifiedWeapon.Ammo[m];
	}
	if (bNoAmmoInstances && FireMode[m].AmmoClass != None && (m == 0 || FireMode[m].AmmoClass != FireMode[0].AmmoClass))
	{
		if (bJustSpawned)
		{
			for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				W = RPGWeapon(Inv);
				if (W != None && W != self && W.bNoAmmoInstances && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
				{
					W.AddAmmo(ModifiedWeapon.AmmoCharge[m], m);
					break;
				}
			}
		}
		else
			SyncUpAmmoCharges(NUM_FIRE_MODES);
	}
}

simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    if ( maxinv == 0 && HasAmmo() )
    {
        if ( (CurrentChoice == None) )
        {
            if ( CurrentWeapon != self )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
        {
            if ( (GroupOffset < CurrentWeapon.GroupOffset)
                && ((CurrentChoice.InventoryGroup != InventoryGroup) || (GroupOffset > CurrentChoice.GroupOffset)) )
                CurrentChoice = self;
		}
        else if ( InventoryGroup == CurrentChoice.InventoryGroup )
        {
            if ( GroupOffset > CurrentChoice.GroupOffset )
                CurrentChoice = self;
        }
        else if ( InventoryGroup > CurrentChoice.InventoryGroup )
        {
			if ( (InventoryGroup < CurrentWeapon.InventoryGroup)
                || (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup) )
                CurrentChoice = self;
        }
        else if ( (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup)
                && (InventoryGroup < CurrentWeapon.InventoryGroup) )
            CurrentChoice = self;
    }
    if(maxinv == 0)
    {
        if ( Inventory == None )
            return CurrentChoice;
        else
            return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
    }
    if ( instigator != none && HasAmmo() )
    {
        if(instigator.Weapon != self && instigator.PendingWeapon != self)
        {
            if(currentchoice == none || ( currentchoice.InventoryGroup == CurrentWeapon.InventoryGroup && currentchoice.GroupOffset == currentweapon.GroupOffset ) )
                return self;
            else
            {
                if(inventorygroup == CurrentWeapon.InventoryGroup)
                {
                    if(groupoffset < CurrentWeapon.GroupOffset)
                    {
                        if( currentchoice.InventoryGroup != inventorygroup || currentchoice.GroupOffset > currentweapon.GroupOffset ||
                            currentchoice.GroupOffset < groupoffset)
                        currentchoice = self;
                    }
                    else if(groupoffset > CurrentWeapon.GroupOffset)
                    {
                        if( currentchoice.InventoryGroup == inventorygroup && currentchoice.GroupOffset < groupoffset &&
                            currentchoice.GroupOffset > CurrentWeapon.GroupOffset)
                            currentchoice = self;
                    }
                }
                else if(inventorygroup < CurrentWeapon.InventoryGroup)
                {
                        if( currentchoice.InventoryGroup > CurrentWeapon.InventoryGroup || ( currentchoice.InventoryGroup == CurrentWeapon.InventoryGroup
                            && currentchoice.GroupOffset > currentweapon.GroupOffset ) || currentchoice.InventoryGroup < InventoryGroup ||
                            (currentchoice.InventoryGroup == InventoryGroup && currentchoice.GroupOffset < groupoffset) )
                            currentchoice = self;
                }
                else
                {
                        if( ( currentchoice.InventoryGroup > CurrentWeapon.InventoryGroup && ( (currentchoice.InventoryGroup == InventoryGroup &&
                            currentchoice.GroupOffset < groupoffset) || currentchoice.InventoryGroup < InventoryGroup) ) ||
                            ( currentchoice.InventoryGroup == CurrentWeapon.InventoryGroup && currentchoice.GroupOffset > currentweapon.GroupOffset ) )
                            currentchoice = self;
                }
            }
        }
    }
    return CurrentChoice;
}

simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    if ( maxinv == 0 && HasAmmo() )
    {
        if ( (CurrentChoice == None) )
        {
            if ( CurrentWeapon != self )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
        {
            if ( (GroupOffset > CurrentWeapon.GroupOffset)
                && ((CurrentChoice.InventoryGroup != InventoryGroup) || (GroupOffset < CurrentChoice.GroupOffset)) )
                CurrentChoice = self;
        }
        else if ( InventoryGroup == CurrentChoice.InventoryGroup )
        {
			if ( GroupOffset < CurrentChoice.GroupOffset )
                CurrentChoice = self;
        }

        else if ( InventoryGroup < CurrentChoice.InventoryGroup )
        {
            if ( (InventoryGroup > CurrentWeapon.InventoryGroup)
                || (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup) )
                CurrentChoice = self;
        }
        else if ( (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup)
                && (InventoryGroup > CurrentWeapon.InventoryGroup) )
            CurrentChoice = self;
    }
    if(maxinv == 0)
    {
        if ( Inventory == None )
            return CurrentChoice;
        else
            return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
    }
    if ( instigator != none && HasAmmo() )
    {
        if(instigator.Weapon != self && instigator.PendingWeapon != self)
        {
            if(currentchoice == none || ( currentchoice.InventoryGroup == CurrentWeapon.InventoryGroup &&
                currentchoice.GroupOffset == currentweapon.GroupOffset ) )
                return self;
            else
            {
                if(inventorygroup == CurrentWeapon.InventoryGroup)
                {
                    if(groupoffset > CurrentWeapon.GroupOffset)
                    {
                        if( currentchoice.InventoryGroup != inventorygroup || currentchoice.GroupOffset < currentweapon.GroupOffset ||
                            currentchoice.GroupOffset > groupoffset)
                        currentchoice = self;
                    }
                    else if(groupoffset < CurrentWeapon.GroupOffset)
                    {
                        if( currentchoice.InventoryGroup == inventorygroup && currentchoice.GroupOffset > groupoffset &&
                            currentchoice.GroupOffset < CurrentWeapon.GroupOffset)
                            currentchoice = self;
                    }
                }
                else if(inventorygroup > CurrentWeapon.InventoryGroup)
                {
                        if( currentchoice.InventoryGroup < CurrentWeapon.InventoryGroup || ( currentchoice.InventoryGroup == CurrentWeapon.InventoryGroup
                            && currentchoice.GroupOffset < currentweapon.GroupOffset ) || currentchoice.InventoryGroup > InventoryGroup ||
                            (currentchoice.InventoryGroup == InventoryGroup && currentchoice.GroupOffset > groupoffset) )
                            currentchoice = self;
                }
                else
                {
                        if( ( currentchoice.InventoryGroup < CurrentWeapon.InventoryGroup && ( (currentchoice.InventoryGroup == InventoryGroup &&
                            currentchoice.GroupOffset > groupoffset) || currentchoice.InventoryGroup > InventoryGroup) ) ||
                            ( currentchoice.InventoryGroup == CurrentWeapon.InventoryGroup && currentchoice.GroupOffset < currentweapon.GroupOffset ) )
                            currentchoice = self;
                }
            }
        }
    }
    return CurrentChoice;
}

simulated function ClientWeaponSet(bool bPossiblySwitch)
{
    local int Mode;
    local controller c;
    local saveinv s;

    if(bpendingdelete)
        return;
    Instigator = Pawn(Owner);
    bPendingSwitch = bPossiblySwitch;
    if( Instigator == None || ModifiedWeapon == None || ( instigator.Controller == none && ( instigator.DrivenVehicle == none ||
        instigator.DrivenVehicle.Controller == none ) ) )
    {
        disable('tick');
        GotoState('PendingClientWeaponSet');
        return;
    }
    if(instigator.Controller != none)
        c = instigator.Controller;
    else
        c = instigator.DrivenVehicle.Controller;
    if( Level.NetMode != NM_DedicatedServer && !bPickupMessageSent && playercontroller(c) != None )
    {
        bPickupMessageSent = true;
        playercontroller(c).ReceiveLocalizedMessage(class'identifymessage', 1,,, self);
    }
    for( Mode = 0; Mode < NUM_FIRE_MODES; Mode++ )
    {
        if( ModifiedWeapon.FireModeClass[Mode] != None )
        {
            if (ModifiedWeapon.FireMode[Mode] == None )
            {
                GotoState('PendingClientWeaponSet');
                return;
            }
            if( ModifiedWeapon.FireMode[Mode].AmmoClass != None && !bNoAmmoInstances && ModifiedWeapon.Ammo[Mode] == None &&
                ModifiedWeapon.FireMode[Mode].AmmoPerFire > 0)
            {
                ModifiedWeapon.Ammo[Mode] = Ammunition(Instigator.FindInventoryType(ModifiedWeapon.FireMode[Mode].AmmoClass) );
                if(ModifiedWeapon.Ammo[Mode] == None)
                {
                    GotoState('PendingClientWeaponSet');
                    return;
                }
            }
        }
        if(twingun!=none && !twingun.bDeleteMe && twingun.FireMode[mode]!=none )
            twingun.FireMode[mode].Instigator=instigator;
        ModifiedWeapon.FireMode[Mode].Instigator = Instigator;
        ModifiedWeapon.FireMode[Mode].Level = Level;
    }
    enable('tick');
    bPickupMessageSent = false;
    SetHolderStatsInv();
    SetWeaponInfo();
    s = saveinv(instigator.FindInventoryType(class'saveinv') );
    if(s != none)
        maxinv = s.maxinv;
    ClientState = WS_Hidden;
    ModifiedWeapon.ClientState = ClientState;
    GotoState('Hidden');

    if( Level.NetMode == NM_DedicatedServer || playercontroller(Instigator.Controller) == None )
        return;

    if( Instigator.Weapon == self || Instigator.PendingWeapon == self )
    {
        if (Instigator.PendingWeapon != None)
            Instigator.ChangedWeapon();
        else
            BringUp();
        return;
    }

    if( Instigator.PendingWeapon != None && Instigator.PendingWeapon.bForceSwitch )
        return;

    if( Instigator.Weapon == None || instigator.Weapon == modifiedweapon)
    {
        Instigator.PendingWeapon = self;
        Instigator.ChangedWeapon();
    }
    else if ( bPossiblySwitch )
    {
		if ( PlayerController(Instigator.Controller) == None || PlayerController(Instigator.Controller).bNeverSwitchOnPickup )
			return;
        if ( Instigator.PendingWeapon != None )
        {
            if ( RateSelf() > Instigator.PendingWeapon.RateSelf() )
            {
                Instigator.PendingWeapon = self;
                Instigator.Weapon.PutDown();
            }
        }
        else if ( RateSelf() > Instigator.Weapon.RateSelf() )
        {
            Instigator.PendingWeapon = self;
            Instigator.Weapon.PutDown();
        }
    }
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    if(ModifiedWeapon!=none  )
    {
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.BringUp(PrevWeapon);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
	    if (ModifiedWeapon.TimerRate > 0)
	    {
		    SetTimer(ModifiedWeapon.TimerRate, false);
            ModifiedWeapon.SetTimer(0, false);
	        ClientState = ModifiedWeapon.ClientState;
	    }
	    if(rpgweapon(prevweapon) != none && rpgweapon(prevweapon).ModifiedWeapon != none)
	        rpgweapon(prevweapon).ModifiedWeapon.bCanThrow = false;
    }
}

simulated function bool PutDown()
{
	local bool bResult;
    if(instigator != none && instigator.IsLocallyControlled() && (instigator.PendingWeapon == none ||
        (rpgweapon(instigator.PendingWeapon) == none && !instigator.PendingWeapon.bNoInstagibReplace) ) )
    {
        instigator.PendingWeapon = none;
        return false;
    }
    if(ModifiedWeapon!=none  )
    {
        serverthrow(false);
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    bResult = ModifiedWeapon.PutDown();
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
	    if ( ModifiedWeapon.TimerRate > 0)
	    {
		    SetTimer(ModifiedWeapon.TimerRate, false);
		    ModifiedWeapon.SetTimer(0, false);
	        ClientState = ModifiedWeapon.ClientState;
	    }
        ModifiedWeapon.bCanThrow = false;
	}
	return bResult;
}

state PendingClientWeaponSet
{
    simulated function Timer()
    {
        if ( Pawn(Owner) != None )
            ClientWeaponSet(bPendingSwitch);
        if ( IsInState('PendingClientWeaponSet') )
			SetTimer(0.05, false);
    }

    simulated function BeginState()
    {
        SetTimer(0.05, false);
    }
}

simulated function Fire(float F)
{
    if(ModifiedWeapon!=none  )
    {
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.Fire(F);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
    }
}

simulated function AltFire(float F)
{
    if(ModifiedWeapon!=none  )
    {
        if(instigator != none && instigator.Weapon == self)
            instigator.Weapon = ModifiedWeapon;
	    ModifiedWeapon.AltFire(F);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
            instigator.Weapon = self;
    }
}

simulated function WeaponTick(float dt)
{
	local int x,y;
	local transbeacon t;
	local vector Dist, Dir, HitLocation, HitNormal;
	local float ZDiff, Dist2D;
	local actor HitActor;

    if(modifiedweapon==none)
        return;
    if(ModifiedWeapon.ClientState == WS_Hidden)
    {
        BringUp();
        return;
    }
	//Failsafe to prevent losing sync with ModifiedWeapon
	if (AmmoClass[0] != ModifiedWeapon.AmmoClass[0])
	{
		for (x = 0; x < NUM_FIRE_MODES; x++)
		{
			FireMode[x] = ModifiedWeapon.FireMode[x];
			Ammo[x] = ModifiedWeapon.Ammo[x];
			AmmoClass[x] = ModifiedWeapon.AmmoClass[x];
		}
		ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
	}

	if(level.NetMode != nm_dedicatedserver && default.ExchangeFireModes != modifiedweapon.default.ExchangeFireModes )
	    default.ExchangeFireModes = modifiedweapon.default.ExchangeFireModes;

	//sync up ammocharge with other RPGWeapons player has that are modifying the same class of weapon
	if (Role == ROLE_Authority && bNoAmmoInstances && ( LastAmmoCharge[0] != ModifiedWeapon.AmmoCharge[0] || (AmmoClass[1] != none &&
        AmmoClass[0] != AmmoClass[1] && LastAmmoCharge[1] != ModifiedWeapon.AmmoCharge[1]) ) )
	{
	    y = -1;
	    if( LastAmmoCharge[0] != ModifiedWeapon.AmmoCharge[0] )
	        y = 0;
		if(AmmoClass[1] != none && AmmoClass[0] != AmmoClass[1] && LastAmmoCharge[1] != ModifiedWeapon.AmmoCharge[1])
		    y += NUM_FIRE_MODES;
		SyncUpAmmoCharges(y);
		//isn't it ironic that my code in Weapon.uc for the latest patch that prevents erroneous switching to
		//best weapon screwed my own mod?
		//so now I need this hack to work around it
		if (!HasAmmo() )
		{
			if (instigator!=none && Instigator.IsLocallyControlled() )
				OutOfAmmo();
			else  //force net update because client checks ammo in PostNetReceive()
				bClientTrigger = !bClientTrigger;
		}
	}

	//Rocket launcher homing hack
	if (instigator!=none && ( ModifiedWeapon.IsA('RocketLauncher') || ModifiedWeapon.IsA('omfg') ) )
	{
		Instigator.Weapon = ModifiedWeapon;
		ModifiedWeapon.Tick(dt);
	    if (twingun!=none && ( twingun.IsA('RocketLauncher') || twingun.IsA('omfg') ) )
		    twingun.Tick(dt);
		Instigator.Weapon = self;
	}

	ModifiedWeapon.WeaponTick(dt);

	if(role < role_authority)
	    return;

    if( modifieroverlay != none )
    {
        if(modifiedweapon.OverlayMaterial == none || modifiedweapon.OverlayTimer <= 0.0 )
            modifiedweapon.SetOverlayMaterial(modifieroverlay, 1000000.0, true);
        if(modifiedweapon.ThirdPersonActor != none && (modifiedweapon.ThirdPersonActor.OverlayMaterial == none || modifiedweapon.ThirdPersonActor.OverlayTimer <= 0.0) )
            modifiedweapon.ThirdPersonActor.SetOverlayMaterial(modifieroverlay, 1000000.0, true);
    }



    if(translauncher(modifiedweapon) != none && translauncher(modifiedweapon).TransBeacon != none && !(left(translauncher(modifiedweapon).TransBeacon.name,3) ~= "RPG") &&
        translauncher(modifiedweapon).TransBeacon.IsInState('MonitoringThrow') && bot(instigator.Controller) != none)
	{

		t = translauncher(modifiedweapon).TransBeacon;

		if ( (t.TranslocationTarget == None) || !Bot(Instigator.Controller).Squad.AllowTranslocationBy(Bot(Instigator.Controller) )
			|| ((GameObject(Instigator.Controller.MoveTarget) != None) && (Instigator.Controller.MoveTarget != t.TranslocationTarget))
			|| ( (t.TranslocationTarget != Instigator.Controller.MoveTarget)
				&& (t.TranslocationTarget != Instigator.Controller.RouteGoal)
				&& (t.TranslocationTarget != Instigator.Controller.RouteCache[0])
				&& (t.TranslocationTarget != Instigator.Controller.RouteCache[1])
				&& (t.TranslocationTarget != Instigator.Controller.RouteCache[2])
				&& (t.TranslocationTarget != Instigator.Controller.RouteCache[3])) )
		{
			t.EndMonitoring();
			return;
		}

		Dist = t.Location - t.TranslocationTarget.Location;
		ZDiff = Dist.Z;
		Dist.Z = 0;
		Dir = t.TranslocationTarget.Location - Instigator.Location;
		Dir.Z = 0;
		Dist2D = VSize(Dist);
		if ( Dist2D < t.TranslocationTarget.CollisionRadius )
		{
			if ( ZDiff > -0.9 * t.TranslocationTarget.CollisionHeight )
			{
				Instigator.Controller.MoveTarget = t.TranslocationTarget;
				instigator.Weapon = modifiedweapon;
				t.BotTranslocate();
				instigator.Weapon = self;
			}
			return;
		}
		Dir = t.TranslocationTarget.Location - Instigator.Location;
		Dir.Z = 0;
		if ( (Dist Dot Dir) > 0 )
		{
			if ( Bot(Instigator.Controller).bPreparingMove )
			{
					Bot(Instigator.Controller).MoveTimer = -1;
					if ( (JumpSpot(t.TranslocationTarget) != None) && (Instigator.Controller.MoveTarget == t.TranslocationTarget) )
					    JumpSpot(t.TranslocationTarget).FearCost += 400;
			}
			else if ( (GameObject(t.TranslocationTarget) != None) && (ZDiff > 0) &&
                (Dist2D < FMin(400, VSize(Instigator.Location - t.TranslocationTarget.Location) - 250)) )
			{
				HitActor = Trace(HitLocation, HitNormal, t.Location - vect(0,0,100), t.Location, false);
				if ( (HitActor != None) && (HitNormal.Z > 0.7) )
				{
					Instigator.Controller.MoveTarget = t.TranslocationTarget;
				    instigator.Weapon = modifiedweapon;
				    t.BotTranslocate();
				    instigator.Weapon = self;
					return;
				}
			}
			t.EndMonitoring();
			return;
		}
	}
}

simulated function Tick(float dt)
{
    local inventory i;
    local weapon w;
    local int x;
    local bool b;
    if( modifiedweapon == none || modifiedweapon.bPendingDelete )
    {
        for(x = 0; x < NUM_FIRE_MODES; x++)
            if(firemode[x] != none)
                firemode[x] = none;
        disable('tick');
        if( role == role_authority && !bpendingdelete)
        {
            if( references <= 0)
                destroy();
            else if(instigator != none)
                instigator.DeleteInventory(self);
        }
        return;
    }
    if( role < role_authority )
        return;
    if(bAdded )
    {
        if(!bDone)
        {
            if(twingun != none)
                instigator.DeleteInventory(twingun);
            instigator.DeleteInventory(modifiedweapon);
            if(twingun != none)
                twingun.SetOwner(instigator);
            modifiedweapon.SetOwner(instigator);
            b = bCanThrow;
            SetModifiedWeapon(modifiedweapon,false);
            bCanThrow = b;
            bDone = true;
        }
        return;
    }
    if( instigator == none && pawn(owner) == none && modifiedweapon.Instigator == none && pawn(modifiedweapon.Owner) == none)
        return;
    if(instigator == none )
    {
        if(pawn(owner) != none)
            instigator = pawn(owner);
        else if(modifiedweapon.Instigator != none)
            instigator = modifiedweapon.Instigator;
        else instigator = pawn(modifiedweapon.Owner);
    }
    if(pawn(owner) == none )
    {
        if(instigator != none)
            setowner(instigator);
        else if(modifiedweapon.instigator != none)
            setowner(modifiedweapon.instigator);
        else setowner(modifiedweapon.Owner);
    }
    for(i = owner.Inventory; i != none; i = i.Inventory)
        if(i == modifiedweapon)
        {
            w = instigator.Weapon;
            instigator.DeleteInventory(i);
            i.SetOwner(owner);
            bDone = true;
            SetModifiedWeapon(modifiedweapon,false);
            bNoGiveAmmo = true;
            giveto(instigator);
            if(bpendingdelete || modifiedweapon == none || modifiedweapon.bPendingDelete)
            {
                disable('tick');
                if(!bpendingdelete)
                    destroy();
                return;
            }
            bNoGiveAmmo = false;
            identify();
            if(instigator.Weapon == none )
            {
                if( holderstatsinv != none && !instigator.IsLocallyControlled() )
                    holderstatsinv.ClientSwitchWeapon(w, self);
                else instigator.ServerChangedWeapon(w, self);
            }
            break;
        }
}

function SetDefaultDisplayProperties()
{
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
    if(modifiedweapon != none)
        modifiedweapon.SetDefaultDisplayProperties();
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
    super.SetDefaultDisplayProperties();
}

simulated function OutOfAmmo()
{
	local int i;
    if(ModifiedWeapon!=none  )
    {
	    ModifiedWeapon.OutOfAmmo();

	    //weapons with many ammo types, like ChaosUT weapons, might have switched firemodes/ammotypes here
	    for (i = 0; i < NUM_FIRE_MODES; i++)
	    {
		    FireMode[i] = ModifiedWeapon.FireMode[i];
		    Ammo[i] = ModifiedWeapon.Ammo[i];
		    AmmoClass[i] = ModifiedWeapon.AmmoClass[i];
	    }
	    ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
	}
}

simulated function ClientStartFire(int Mode)
{
	if(modifiedweapon==none || instigator==none || instigator.weapon!=self || modifiedweapon.ClientState==ws_putdown || ClientState==ws_putdown )
	    return;
	if(linkgun(modifiedweapon) != none)
	{
        super.ClientStartFire(mode);
        return;
    }
    if(role < role_authority)
	    weaponhack(false);
	instigator.weapon = modifiedweapon;
    modifiedweapon.ClientStartFire(mode);
	instigator.weapon = self;
    if(role < role_authority)
	    weaponhack(true);
}

simulated function bool StartFire(int Mode)
{
	local SquadAI S;
	local Bot B;
	local vector AimDir;
	local bool r;
	if ( LinkGun(ModifiedWeapon) != none && Role == ROLE_Authority && Instigator != None && Instigator.PlayerReplicationInfo != None &&
        PlayerController(Instigator.Controller) != None && UnrealTeamInfo(Instigator.PlayerReplicationInfo.Team) != None)
	{
		S = UnrealTeamInfo(Instigator.PlayerReplicationInfo.Team).AI.GetSquadLedBy(Instigator.Controller);
		if ( S != None )
		{
			AimDir = vector(Instigator.Controller.Rotation);
			for ( B=S.SquadMembers; B!=None; B=B.NextSquadMember )
				if ( (HoldSpot(B.GoalScript) == None) && (B.Pawn != None) && (LinkGun(B.Pawn.Weapon) != None || (RPGWeapon(B.Pawn.Weapon) != None &&
                    LinkGun(RPGWeapon(B.Pawn.Weapon).ModifiedWeapon) != None) ) && B.Pawn.Weapon.FocusOnLeader(true) &&
                    ( (AimDir dot Normal(B.Pawn.Location - Instigator.Location) ) < 0.9) )
				{
					B.Focus = Instigator;
					B.FireWeaponAt(Instigator);
				}
		}
	}
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
    if(ModifiedWeapon != none  )
	    r = ModifiedWeapon.StartFire(Mode);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;
    return r;
}

simulated function ClientStopFire(int Mode)
{
    if(ModifiedWeapon!=none  )
    {
	    weaponhack(false);
	    if(instigator != none && instigator.Weapon == self)
	        instigator.weapon = modifiedweapon;
	    ModifiedWeapon.ClientStopFire(Mode);
        if(instigator != none && instigator.Weapon == ModifiedWeapon)
	        instigator.weapon = self;
	    weaponhack(true);
    }
}

simulated function StopFire(int Mode)
{
    if(instigator != none && instigator.Weapon == self)
        instigator.weapon = modifiedweapon;
    ModifiedWeapon.StopFire(Mode);
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.weapon = self;
}

simulated function bool ReadyToFire(int Mode)
{
    if(ModifiedWeapon!=none  )
	    return ModifiedWeapon.ReadyToFire(Mode);
}

simulated function Timer()
{
	if (ModifiedWeapon == None)
		return;
    if(bcheck )
    {
        if(instigator!=none && instigator.Weapon==modifiedweapon)
            instigator.Weapon=self;
        bcheck=false;
        if(ClientState == WS_BringUp)
            SetTimer(ModifiedWeapon.BringUpTime, false);
        else if(ClientState == WS_PutDown)
            SetTimer(ModifiedWeapon.PutDownTime, false);
        return;
    }
    if(instigator != none && instigator.Weapon == self)
        instigator.Weapon = ModifiedWeapon;
	ModifiedWeapon.Timer();
    if(instigator != none && instigator.Weapon == ModifiedWeapon)
        instigator.Weapon = self;

	ClientState = ModifiedWeapon.ClientState;
	if (ModifiedWeapon.TimerRate > 0)
	{
		SetTimer(ModifiedWeapon.TimerRate, false);
		ModifiedWeapon.SetTimer(0, false);
	}
	if(clientstate == ws_putdown || ClientState == WS_Hidden)
	    serverthrow(false);
	else if(clientstate == ws_readytofire )
        serverthrow(true);
}

simulated function bool IsFiring()
{
    return (ModifiedWeapon!=none && ModifiedWeapon.IsFiring() );
}

function bool IsRapidFire()
{
    if(ModifiedWeapon!=none  )
	    return ModifiedWeapon.IsRapidFire();
}

function bool ConsumeAmmo(int Mode, float load, optional bool bAmountNeededIsMax)
{
    local bool b;
	local Controller C;
	local int AmountNeeded;

	if(linkgun(ModifiedWeapon) == none)
	{
        b = ModifiedWeapon!=none && ModifiedWeapon.ConsumeAmmo(Mode, load, bAmountNeededIsMax);
        return b;
	}

    if (linkgun(ModifiedWeapon).Linking && LinkFire(FireMode[Mode]) != none && LinkFire(FireMode[Mode]).LockedPawn != None &&
        Vehicle(LinkFire(FireMode[Mode]).LockedPawn) == None )
		return true;

	if ( LinkAltFire(FireMode[mode]) != none )
		bAmountNeededIsMax = true;

	if (Instigator != None && Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None)
	{
		for (C = Level.ControllerList; C != None; C = C.NextController)
			if (C.Pawn != None && C.Pawn.Weapon != None)
			{
				if (LinkGun(C.Pawn.Weapon) != None && LinkedTo(LinkGun(C.Pawn.Weapon) ) )
					LinkGun(C.Pawn.Weapon).LinkedConsumeAmmo(Mode, load, bAmountNeededIsMax);
				else if ( RPGWeapon(C.Pawn.Weapon) != None && LinkGun(RPGWeapon(C.Pawn.Weapon).ModifiedWeapon) != None &&
                    LinkedTo(LinkGun(RPGWeapon(C.Pawn.Weapon).ModifiedWeapon)) )
					LinkGun(RPGWeapon(C.Pawn.Weapon).ModifiedWeapon).LinkedConsumeAmmo(Mode, load, bAmountNeededIsMax);
			}
	}

	if ( bNoAmmoInstances )
	{
		if ( AmmoClass[0] == AmmoClass[mode] )
			mode = 0;
		AmountNeeded = int(load);
		if (bAmountNeededIsMax && ModifiedWeapon.AmmoCharge[mode] < AmountNeeded)
			AmountNeeded = ModifiedWeapon.AmmoCharge[mode];

		if (ModifiedWeapon.AmmoCharge[mode] < AmountNeeded)
		{
			CheckOutOfAmmo();
			return false;   // Can't do it
		}

		ModifiedWeapon.AmmoCharge[mode] -= AmountNeeded;
		ModifiedWeapon.NetUpdateTime = Level.TimeSeconds - 1;

		if (Level.NetMode == NM_StandAlone || Level.NetMode == NM_ListenServer)
			CheckOutOfAmmo();

		return true;
	}
    if (Ammo[Mode] != None)
        return Ammo[Mode].UseAmmo(int(load), bAmountNeededIsMax);

    return true;
}

function bool LinkedTo(LinkGun L)
{
	local Pawn Other;
	local LinkGun OtherWeapon, Head;
	local int sanity;

	Head = L;
	while (Head != None && Head.Linking && sanity < 32)
	{
	    if(LinkFire(Head.FireMode[1]) != none)
            Other = LinkFire(Head.FireMode[1]).LockedPawn;
        if ( Other == None)
            break;
        OtherWeapon = LinkGun(Other.Weapon);
        if (OtherWeapon == None && RPGWeapon(Other.Weapon) != None)
   	        OtherWeapon = LinkGun(RPGWeapon(Other.Weapon).ModifiedWeapon);
        if (OtherWeapon == None)
            break;
        Head = OtherWeapon;
        if (Head == ModifiedWeapon)
       	    return true;
        sanity++;
    }
	Head = L;
	while (Head != None && Head.Linking && sanity < 32)
	{
        if (LinkFire(Head.FireMode[0]) != none)
            Other = LinkFire(Head.FireMode[0]).LockedPawn;
        if (Other == None)
            return false;
        OtherWeapon = LinkGun(Other.Weapon);
        if (OtherWeapon == None && RPGWeapon(Other.Weapon) != None)
   	        OtherWeapon = LinkGun(RPGWeapon(Other.Weapon).ModifiedWeapon);
        if (OtherWeapon == None)
            return false;
        Head = OtherWeapon;
        if (Head == ModifiedWeapon)
       	    return true;
        sanity++;
    }
    return false;
}

simulated function bool HasAmmo()
{
	if (ModifiedWeapon != None)
		return ModifiedWeapon.HasAmmo();

	return false;
}

function AdjustPlayerDamage( out int Damage, Pawn InstigatedBy, Vector HitLocation,
                             out Vector Momentum, class<DamageType> DamageType)
{
    modifiedweapon.AdjustPlayerDamage(damage,instigatedby,hitlocation,momentum,damagetype);
}

simulated function StartBerserk()
{
    modifiedweapon.StartBerserk();
	bberserk=true;
}

simulated function StopBerserk()
{
    modifiedweapon.StopBerserk();
	bberserk=false;
}

simulated function AnimEnd(int channel)
{
    if(ModifiedWeapon!=none  )
	    ModifiedWeapon.AnimEnd(channel);
}

simulated function PlayIdle()
{
    if(ModifiedWeapon!=none  )
	    ModifiedWeapon.PlayIdle();
}

function bool CheckReflect(Vector HitLocation, out Vector RefNormal, int AmmoDrain)
{
	return ModifiedWeapon!=none && ModifiedWeapon.CheckReflect(HitLocation, RefNormal, AmmoDrain);
}

function DoReflectEffect(int Drain)
{
    if(ModifiedWeapon!=none  )
	    ModifiedWeapon.DoReflectEffect(Drain);
}

function bool HandlePickupQuery(pickup Item)
{
    local bool result;
    local int i;
    local class<Inventory> it;
    if(modifiedweapon != none)
    {
        it = item.inventorytype;
        modifiedweapon.Inventory = inventory;
        result = modifiedweapon.HandlePickupQuery(item);
        modifiedweapon.Inventory = none;
        if(maxinv == 0)
            return result;
		for ( i=0; i<NUM_FIRE_MODES; i++ )
		{
			if ( it == modifiedweapon.AmmoClass[i] && modifiedweapon.AmmoClass[i] != None && bNoAmmoInstances)
			{
			    SyncUpAmmoCharges(NUM_FIRE_MODES);
				break;
			}
		}
        return result;
    }
	else return ( inventory != none && Inventory.HandlePickupQuery(Item) );
}

function AttachToPawn(Pawn P)
{
    if(ModifiedWeapon!=none  )
    {
	    ModifiedWeapon.AttachToPawn(P);
	    ThirdPersonActor = ModifiedWeapon.ThirdPersonActor;
	}
}

function DetachFromPawn(Pawn P)
{
    if(ModifiedWeapon!=none  )
	    ModifiedWeapon.DetachFromPawn(P);
}

simulated function SetOverlayMaterial(Material mat, float time, bool bOverride)
{
    local int x,y,z;
	if(ModifiedWeapon!=none && (ModifierOverlay == None || time != 1000000 || mat != ModifierOverlay ) )
	{
	    if(ModifiedWeapon.OverlayMaterial == ModifierOverlay)
	        bOverride = true;
		ModifiedWeapon.SetOverlayMaterial(mat, time, bOverride);
		if (WeaponAttachment(ThirdPersonActor) != None)
			ThirdPersonActor.SetOverlayMaterial(mat, time, bOverride);
		if(ModifierOverlay == None && time == 1000000 && mat == none && RPGMut != none && role == role_authority)
        {
	        if(ModifiedWeapon.ThirdPersonActor != none && ( (ModifiedWeapon.ThirdPersonActor.DrawType == dt_staticmesh || ModifiedWeapon.ThirdPersonActor.DrawType == dt_mesh) &&
                ModifiedWeapon.ThirdPersonActor.Skins.length > 0 ) )
	        {
                for(y = 0; y < RPGMut.ACTORNUM; y++)
                {
                    if(RPGMut.getlist(y) == none)
                    {
                        RPGMut.assignlist(ModifiedWeapon.ThirdPersonActor,y);
                        if(level.NetMode != nm_dedicatedserver)
                            RPGMut.setweaponskins(ModifiedWeapon.ThirdPersonActor,y);
                        z = y + 1;
                        break;
                    }
                    z++;
                }
            }
            if(z == RPGMut.ACTORNUM)
            {
                RPGMut.deletelist();
                RPGMut.assignlist(ModifiedWeapon.ThirdPersonActor,0);
                if(level.NetMode != nm_dedicatedserver)
                    RPGMut.setweaponskins(ModifiedWeapon.ThirdPersonActor,0);
                z = 1;
            }
            x = z;
            if( (ModifiedWeapon.DrawType == dt_staticmesh || ModifiedWeapon.DrawType == dt_mesh) && ModifiedWeapon.Skins.length > 0 )
            {
                for(y = x; y < RPGMut.ACTORNUM; y++)
                {
                    if(RPGMut.getlist(y) == none)
                    {
                        RPGMut.assignlist(ModifiedWeapon,y);
                        if(level.NetMode != nm_dedicatedserver)
                            RPGMut.setweaponskins(ModifiedWeapon,y);
                        x = y + 1;
                        break;
                    }
                    x++;
                }
            }
            if(x == RPGMut.ACTORNUM)
            {
                x = 0;
                RPGMut.deletelist();
                if(z > 0)
                {
                    RPGMut.assignlist(ModifiedWeapon.ThirdPersonActor,0);
                    if(level.NetMode != nm_dedicatedserver)
                        RPGMut.setweaponskins(ModifiedWeapon.ThirdPersonActor,0);
                    x++;
                }
                RPGMut.assignlist(ModifiedWeapon,x);
                if(level.NetMode != nm_dedicatedserver)
                    RPGMut.setweaponskins(ModifiedWeapon,x);
            }
        }
	}
	else if(mat == ModifierOverlay && ModifierOverlay != none && ModifiedWeapon!=none && time == 1000000 && role == role_authority)
	{
	    ModifiedWeapon.SetOverlayMaterial(mat, time, bOverride);
        if(ModifiedWeapon.ThirdPersonActor != none)
	        ModifiedWeapon.ThirdPersonActor.SetOverlayMaterial(mat, time, bOverride);
        if(RPGMut != none)
        {
	        if(ModifiedWeapon.ThirdPersonActor != none && (ModifiedWeapon.ThirdPersonActor.DrawType == dt_staticmesh || ( ModifiedWeapon.ThirdPersonActor.DrawType == dt_mesh &&
                ModifiedWeapon.ThirdPersonActor.Skins.length > 0) ) )
	        {
                for(y = 0; y < RPGMut.ACTORNUM; y++)
                {
                    if(RPGMut.getlist(y) == none)
                    {
                        RPGMut.assignlist(ModifiedWeapon.ThirdPersonActor,y);
                        if(level.NetMode != nm_dedicatedserver)
                            RPGMut.setweaponskins(ModifiedWeapon.ThirdPersonActor,y);
                        z = y + 1;
                        break;
                    }
                    z++;
                }
            }
            if(z == RPGMut.ACTORNUM)
            {
                RPGMut.deletelist();
                RPGMut.assignlist(ModifiedWeapon.ThirdPersonActor,0);
                if(level.NetMode != nm_dedicatedserver)
                    RPGMut.setweaponskins(ModifiedWeapon.ThirdPersonActor,0);
                z = 1;
            }
            x = z;
            if(ModifiedWeapon.DrawType == dt_staticmesh || ( ModifiedWeapon.DrawType == dt_mesh && ModifiedWeapon.Skins.length > 0) )
            {
                for(y = x; y < RPGMut.ACTORNUM; y++)
                {
                    if(RPGMut.getlist(y) == none)
                    {
                        RPGMut.assignlist(ModifiedWeapon,y);
                        if(level.NetMode != nm_dedicatedserver)
                            RPGMut.setweaponskins(ModifiedWeapon,y);
                        x = y + 1;
                        break;
                    }
                    x++;
                }
            }
            if(x == RPGMut.ACTORNUM)
            {
                x = 0;
                RPGMut.deletelist();
                if(z > 0)
                {
                    RPGMut.assignlist(ModifiedWeapon.ThirdPersonActor,0);
                    if(level.NetMode != nm_dedicatedserver)
                        RPGMut.setweaponskins(ModifiedWeapon.ThirdPersonActor,0);
                    x++;
                }
                RPGMut.assignlist(ModifiedWeapon,x);
                if(level.NetMode != nm_dedicatedserver)
                    RPGMut.setweaponskins(ModifiedWeapon,x);
            }
        }
	}
}

simulated function PostNetReceive()
{
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    if(RPGMut == none)
        RPGMut = class'MutMCGRPG'.static.GetRPGMutator(self);
}

simulated function ClientTrigger()
{
    SyncUpAmmoCharges(NUM_FIRE_MODES);
    CheckOutOfAmmo();
}

function DropFrom(vector StartLocation)
{
    local int m, x;
    local Inventory Inv;
    local RPGWeapon W;
    local RPGStatsInv StatsInv;
    local RPGStatsInv.OldRPGWeaponInfo MyInfo;
    local bool bFoundAnother, bAlreadyDropped;
	local RPGWeapon OldRPGWeapon;

    if (!ModifiedWeapon.bCanThrow )
    {
    	// hack for default weapons so Controller.GetLastWeapon() will return the modified weapon's class
    	if (instigator!=none && Instigator.Health <= 0)
    		Destroy();
        return;
    }
    if (!HasAmmo())
    	return;

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m] != none && FireMode[m].bIsFiring)
            StopFire(m);
    }
    if(twingun!=none)
        StartLocation.Y+=75;       //copied from akimbo arena
	PendingPickup[0] = Spawn(class<weaponpickup>(PickupClass),,, StartLocation);
	if ( PendingPickup[0] != None )
	{
		PendingPickup[0].Velocity = Velocity;
		PendingPickup[0].InitDroppedPickupFor(ModifiedWeapon);
        if(!bnoammoinstances)
        {
            if( ammoclass[0] == ammoclass[1] )  //clear 3 years old epic bug
                PendingPickup[0].AmmoAmount[1] = 0;
        }
 	    if (instigator!=none && Instigator.Health > 0)
     	{
			PendingPickup[0].bThrown = true;

			//only toss 1 ammo if have another weapon of the same class
			for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				W = RPGWeapon(Inv);
				if (W != None && W != self && w.ModifiedWeapon!=none  && ModifiedWeapon!=none  && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
				{
					bFoundAnother = true;
					if (W != None && W.bNoAmmoInstances)
					{
						if (W != None && w.ModifiedWeapon!=none  && AmmoClass[0] != None)
							W.ModifiedWeapon.AmmoCharge[0] -= 1;
						if (W != None && w.ModifiedWeapon!=none  && AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
							W.ModifiedWeapon.AmmoCharge[1] -= 1;
					}
				}
			}
			if (bFoundAnother)
			{
				if (AmmoClass[0] != None)
				{
					PendingPickup[0].AmmoAmount[0] = 1;
					if (!bNoAmmoInstances)
						Ammo[0].AmmoAmount -= 1;
				}
				if (AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
				{
					PendingPickup[0].AmmoAmount[1] = 1;
					if (!bNoAmmoInstances)
						Ammo[1].AmmoAmount -= 1;
				}
			}
		}
	}
	if(twingun!=none)
    {
        StartLocation.Y-=150;
	    PendingPickup[1] = Spawn(class<weaponpickup>(PickupClass),,, StartLocation);
	    if ( PendingPickup[1] != None )
	    {
		    PendingPickup[1].InitDroppedPickupFor(ModifiedWeapon);
            if(!bnoammoinstances)
            {
                if( ammoclass[0] == ammoclass[1] )  //clear 3 years old epic bug
                    PendingPickup[1].AmmoAmount[1] = 0;
            }
		    PendingPickup[1].Velocity = Velocity;
        	if (instigator!=none && Instigator.Health > 0)
        	{
			    PendingPickup[1].bThrown = true;

			    //only toss 1 ammo if have another weapon of the same class
			    for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
			    {
				    W = RPGWeapon(Inv);
				    if (W != None && W != self && w.ModifiedWeapon!=none  && ModifiedWeapon!=none  && W.ModifiedWeapon.Class == ModifiedWeapon.Class)
				    {
					    if (W != None && W.bNoAmmoInstances)
					    {
						    if (W != None && w.ModifiedWeapon!=none  && AmmoClass[0] != None)
							    W.ModifiedWeapon.AmmoCharge[0] -= 1;
						    if (W != None && w.ModifiedWeapon!=none  && AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
							    W.ModifiedWeapon.AmmoCharge[1] -= 1;
				        }
			        }
		        }
			    if (bFoundAnother)
			    {
				    if (AmmoClass[0] != None)
				    {
					    PendingPickup[1].AmmoAmount[0] = 1;
					    if (!bNoAmmoInstances)
						    Ammo[0].AmmoAmount -= 1;
			        }
				    if (AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
				    {
					    PendingPickup[1].AmmoAmount[1] = 1;
					    if (!bNoAmmoInstances)
						    Ammo[1].AmmoAmount -= 1;
			        }
                }
	        }
        }
	}
	if (bFoundAnother)
	{
	    if (!bNoAmmoInstances)
	    {
	        Ammo[0] = None;
	        Ammo[1] = None;
	        if(ModifiedWeapon!=none  )
	        {
	            ModifiedWeapon.Ammo[0] = None;
	            ModifiedWeapon.Ammo[1] = None;
            }
	        if(twingun!=none  )
	        {
	            twingun.Ammo[0] = None;
	            twingun.Ammo[1] = None;
            }
	    }
	}
    ClientWeaponThrown();
	twingun=none;

    SetTimer(0, false);
    if (Instigator != None)
    {
	    if (ModifiedWeapon != None)
        	StatsInv = RPGStatsInv(Instigator.FindInventoryType(class'RPGStatsInv'));
       	DetachFromPawn(Instigator);
        Instigator.DeleteInventory(self);
    }
    if (StatsInv != None)
    {
        for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
            if (StatsInv.OldRPGWeapons[x].ModifiedClass == modifiedweapon.Class)
            {
				OldRPGWeapon = StatsInv.OldRPGWeapons[x].Weapon;
				if (OldRPGWeapon == None)
				{
				    StatsInv.OldRPGWeapons.Remove(x, 1);
				    x--;
				}
				else
				{
                    bAlreadyDropped = true;
				    if(Class != OldRPGWeapon.Class || modifier != oldRPGweapon.modifier)
				    {
				        StatsInv.OldRPGWeapons[x].Weapon = self;
    	                References++;
		                OldRPGWeapon.RemoveReference();
                    }
				    break;
				}
            }
        if(!bAlreadyDropped)
        {
            MyInfo.ModifiedClass = ModifiedWeapon.Class;
            MyInfo.Weapon = self;
    	    StatsInv.OldRPGWeapons[StatsInv.OldRPGWeapons.length] = MyInfo;
    	    References++;
   	    }
    }
    else if (PendingPickup[0] == None)
    {
    	Destroy();
    	return;
   	}
   	PendingPickup[0] = None;
   	PendingPickup[1] = None;
    DestroyModifiedWeapon();
}

simulated function ClientWeaponThrown()
{
    local int m;
    local Inventory Inv;
    local RPGWeapon W;
    local bool bFoundAnother;

    AmbientSound = None;
    if(Instigator != none)
    {
        Instigator.AmbientSound = None;
        if(Instigator.PendingWeapon == self)
            Instigator.PendingWeapon = none;
    }

    if( Level.NetMode != NM_Client )
    {
        if(ModifiedWeapon != none && Instigator != none)
        {
            if(ModifiedWeapon.Instigator == none)
                ModifiedWeapon.Instigator = Instigator;
            if(instigator != none && instigator.Weapon == self)
                instigator.Weapon = ModifiedWeapon;
            modifiedweapon.ClientWeaponThrown();
            if(instigator != none && instigator.Weapon == ModifiedWeapon)
                instigator.Weapon = self;
        }
        return;
    }

    if(Instigator != none)
    {
        for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
        {
            W = RPGWeapon(Inv);
            if (W != None && W != self && w.ModifiedWeapon!=none  && ModifiedWeapon!=none  &&
                W.ModifiedWeapon.Class == ModifiedWeapon.Class)
            {
				bFoundAnother = true;
				break;
            }
        }
        if (bFoundAnother)
        {
            if (!bNoAmmoInstances)
            {
				Ammo[0] = None;
				Ammo[1] = None;
				if(ModifiedWeapon!=none  )
				{
                    ModifiedWeapon.Ammo[0] = None;
                    ModifiedWeapon.Ammo[1] = None;
                }
            }
        }
        Instigator.DeleteInventory(self);
        for (m = 0; m < NUM_FIRE_MODES; m++)
        {
            if (Ammo[m] != None)
                Instigator.DeleteInventory(Ammo[m]);
        }
        if(ModifiedWeapon != none)
        {
            if(ModifiedWeapon.Instigator == none)
                ModifiedWeapon.Instigator = Instigator;
            if(instigator != none && instigator.Weapon == self)
                instigator.Weapon = ModifiedWeapon;
            modifiedweapon.ClientWeaponThrown();
            if(instigator != none && instigator.Weapon == ModifiedWeapon)
                instigator.Weapon = self;
        }
    }
	DestroyModifiedWeapon();
}

function bool AddAmmo(int AmmoToAdd, int Mode)
{
    local bool added;
    added = (modifiedweapon != none && modifiedweapon.AddAmmo(ammotoadd,mode) );
    if(bNoAmmoInstances)
        SyncUpAmmoCharges(NUM_FIRE_MODES);
    return added;
}

simulated function MaxOutAmmo()
{
    local float m;
    local bool bLoaded;
	if (ModifiedWeapon!=none  && bNoAmmoInstances)
	{
	    if(holderstatsinv==none)
	        setholderstatsinv();
	    if(holderstatsinv!=none)
	        m=1.0+float(holderstatsinv.Data.ammomax)/100.0;
        else m=1.0;
		if (AmmoClass[0] != None)
		{
		    if( AmmoClass[0].default.Charge==0)
		        AmmoClass[0].default.Charge=AmmoClass[0].default.MaxAmmo;
		    AmmoClass[0].default.MaxAmmo=AmmoClass[0].default.Charge*m;
            if(!ammomaxed(0) )
            {
			    ModifiedWeapon.AmmoCharge[0] = MaxAmmo(0);
			    bLoaded = true;
			}
		    if( AmmoClass[0].default.Charge>0)
		        AmmoClass[0].default.MaxAmmo=AmmoClass[0].default.Charge;
		}
		if (AmmoClass[1] != None && AmmoClass[0] != AmmoClass[1])
		{

		    if( AmmoClass[1].default.Charge==0)
		        AmmoClass[1].default.Charge=AmmoClass[1].default.MaxAmmo;
		    AmmoClass[1].default.MaxAmmo=AmmoClass[1].default.Charge*m;
            if(!ammomaxed(1) )
            {
			    ModifiedWeapon.AmmoCharge[1] = MaxAmmo(1);
			    bLoaded = true;
			}
		    if( AmmoClass[1].default.Charge>0)
		        AmmoClass[1].default.MaxAmmo=AmmoClass[1].default.Charge;
		}
		if(bLoaded)
		    SyncUpAmmoCharges(NUM_FIRE_MODES);
		return;
	}
	if (Ammo[0] != None)
		Ammo[0].AmmoAmount = Ammo[0].MaxAmmo;
	if (Ammo[1] != None)
		Ammo[1].AmmoAmount = Ammo[1].MaxAmmo;
}

simulated function SuperMaxOutAmmo()
{
    if(ModifiedWeapon!=none  )
	    ModifiedWeapon.SuperMaxOutAmmo();
	if(redeemer(ModifiedWeapon)!=none)
	{
	if ( ModifiedWeapon.bNoAmmoInstances )
	{
		if ( ModifiedWeapon.AmmoClass[0] != None )
			ModifiedWeapon.AmmoCharge[0] = 999;
		if ( (ModifiedWeapon.AmmoClass[1] != None) && (ModifiedWeapon.AmmoClass[0] != ModifiedWeapon.AmmoClass[1]) )
			ModifiedWeapon.AmmoCharge[1] = 999;
		return;
	}
	if ( ModifiedWeapon.Ammo[0] != None )
		ModifiedWeapon.Ammo[0].AmmoAmount = 999;
	if ( ModifiedWeapon.Ammo[1] != None )
		ModifiedWeapon.Ammo[1].AmmoAmount = 999;
    }

}

simulated function int MaxAmmo(int mode)
{
	return ModifiedWeapon.MaxAmmo(mode);
}

simulated function FillToInitialAmmo()
{
    if(modifiedweapon==none || (Invasion(level.Game) != none && Invasion(level.Game).WaveCountDown == 14  &&
        (modifiedweapon.IsA('Painter') || modifiedweapon.IsA('Redeemer') ) ) )
        return;
    ModifiedWeapon.FillToInitialAmmo();
    if (bNoAmmoInstances)
        SyncUpAmmoCharges(NUM_FIRE_MODES);
}

simulated function int AmmoAmount(int mode)
{
    if(ModifiedWeapon!=none  )
	    return ModifiedWeapon.AmmoAmount(mode);
    return 0;
}

simulated function bool NeedAmmo(int mode)
{
    return (ModifiedWeapon!=none && modifiedweapon.NeedAmmo(mode) );
}

simulated function CheckOutOfAmmo()
{
	if (Instigator != None && Instigator.Weapon == self && ModifiedWeapon != None)
	{
		if (bNoAmmoInstances)
		{
			if (ModifiedWeapon.AmmoCharge[0] <= 0 && ModifiedWeapon.AmmoCharge[1] <= 0)
				OutOfAmmo();
			return;
		}

		if (Ammo[0] != None)
			Ammo[0].CheckOutOfAmmo();
		if (Ammo[1] != None)
			Ammo[1].CheckOutOfAmmo();
	}
}

function class<DamageType> GetDamageType()
{
    if(ModifiedWeapon!=none  )
	    return ModifiedWeapon.GetDamageType();
}

simulated function bool WantsZoomFade()
{
	return ModifiedWeapon!=none && ModifiedWeapon.WantsZoomFade();
}

function bool CanHeal(Actor Other)
{
	return ModifiedWeapon!=none && ModifiedWeapon.CanHeal(Other);
}

function bool ShouldFireWithoutTarget()
{
	return ModifiedWeapon!=none && ModifiedWeapon.ShouldFireWithoutTarget();
}

simulated function PawnUnpossessed()
{
    if( ModifiedWeapon!=none  )
	    ModifiedWeapon.PawnUnpossessed();
}

defaultproperties
{
     DigitsBigPulse=(DigitTexture=FinalBlend'HUDContent.Generic.fbHUDAlertSlow',TextureCoords[0]=(X2=38,Y2=38),TextureCoords[1]=(X1=39,X2=77,Y2=38),TextureCoords[2]=(X1=78,X2=116,Y2=38),TextureCoords[3]=(X1=117,X2=155,Y2=38),TextureCoords[4]=(X1=156,X2=194,Y2=38),TextureCoords[5]=(X1=195,X2=233,Y2=38),TextureCoords[6]=(X1=234,X2=272,Y2=38),TextureCoords[7]=(X1=273,X2=311,Y2=38),TextureCoords[8]=(X1=312,X2=350,Y2=38),TextureCoords[9]=(X1=351,X2=389,Y2=38),TextureCoords[10]=(X1=390,X2=428,Y2=38))
     totalLinks=(RenderStyle=STY_Alpha,MinDigitCount=2,TextureScale=0.750000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=0.835000,OffsetX=-65,OffsetY=48,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     LinkIcon=(WidgetTexture=FinalBlend'HUDContent.Generic.fbLinks',RenderStyle=STY_Alpha,TextureCoords=(X2=127,Y2=63),TextureScale=0.800000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=5,OffsetY=-40,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     sanitymax=1000
     bNoInstagibReplace=True
     bGameRelevant=True
     bNetNotify=False
}
