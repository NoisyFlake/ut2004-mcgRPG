class ArtifactMagicMaker extends RPGArtifact 
	config(mcgRPG1991);

var() Pawn RealInstigator;
var() RPGWeapon Weapon;
var() config class<RPGWeapon> lastselected;
var() config bool bOpen;


replication
{
    reliable if(role < role_authority)
        servermakemodifier,serversendsuperammoclassnames;
    reliable if(role == role_authority)
        clientreceivesuperammoclasses, clientmake, ClientSwitchWeapon;
}

static function bool ArtifactIsAllowed(GameInfo Game)
{
    local MutMCGRPG mut;
    mut = class'MutMCGRPG'.static.GetRPGMutator(game);
    return ( mut == none || mut.WeaponModifierChance > 0.0 );
}

simulated function string ExtraData()
{
    local weapon w;
    local vehicle v;
    local inventory i;

    if(bOpen)
        return "";
    V = Vehicle(Instigator);
    if (V != None && V.Driver != None)
        RealInstigator = V.Driver;
    else
        RealInstigator = Instigator;
    if(realinstigator == none || lastselected == none || instigator.controller == none || realinstigator.Weapon == none)
        return "";
    if(rpgweapon(realinstigator.Weapon) != none)
    {
        w = rpgweapon(realinstigator.Weapon).ModifiedWeapon;
        if( w == none || lastselected == rpgweapon(realinstigator.Weapon).Class ||
            !lastselected.static.allowedfor(w.Class,realinstigator) )
            return "";
        for(i = realinstigator.Inventory; i != none; i = i.Inventory)
            if( i.Class == lastselected && rpgweapon(i).ModifiedWeapon != none && rpgweapon(i).ModifiedWeapon.Class == w.Class)
                return "";
    }
    else
    {
        w = realinstigator.Weapon;
        for(i = realinstigator.Inventory; i != none; i = i.Inventory)
            if( i.Class == lastselected && rpgweapon(i).ModifiedWeapon != none && rpgweapon(i).ModifiedWeapon.Class == w.Class)
                return "";
        if( !lastselected.static.allowedfor(w.Class,realinstigator) )
            return "";
    }
    return lastselected.static.magicname();
}

simulated function clientmake()
{
    if(playercontroller(instigatorcontroller) != none)
    {
        if(bopen)
            playercontroller(instigatorcontroller).ClientOpenMenu("mcgRPG1_9_9_1.WeaponModifierMenu");
        else if( lastselected != none)
            servermakemodifier(lastselected);
    }
}

simulated function clientreceivesuperammoclasses(name s, int i)
{
    if(RPGMut != none)
    {
        RPGMut.SuperAmmoClassNames.Length = i + 1;
        RPGMut.SuperAmmoClassNames[i] = s;
        serversendsuperammoclassnames(i + 1);
    }
}

function serversendsuperammoclassnames(int i)
{
    if(i < RPGMut.SuperAmmoClassNames.Length)
        clientreceivesuperammoclasses(RPGMut.SuperAmmoClassNames[i], i);
}

function BotConsider()
{
	if (Instigator.Controller.Adrenaline < getcost() || bActive)
		return;

    if ( Instigator.Controller.Enemy != None && Instigator.Weapon != None && Instigator.Weapon.AIRating > 0.5 &&
        Instigator.Controller.Enemy.Health > 70 && Instigator.Controller.CanSee(Instigator.Controller.Enemy) && NoArtifactsActive() &&
        FRand() < 0.7 )
		Activate();
}


simulated function PostNetBeginPlay()
{
	super.PostNetBeginPlay();
	disable('Tick');
	if(role < role_authority)
	    serversendsuperammoclassnames(0);
}

function botselect()
{
    local bot b;
    local pawn p;
    local weapon w;
    local rpgweapon r;
    local int i;
    local array<class<rpgweapon> > rw;
    local class<rpgweapon> best;
    local float desire,f;
    b = bot(instigatorcontroller);
    if(b != none )
        p = b.Pawn;
    if(p != none)
        w = p.Weapon;
    if(rpgweapon(w) != none)
    {
        r = rpgweapon(w);
        w = r.ModifiedWeapon;
    }
    if(w == none)
        return;
    for(i = 0; i < RPGMut.WeaponModifiers.Length; i++)
        if( (r == none || RPGMut.WeaponModifiers[i].WeaponClass != r.Class ) &&
            RPGMut.WeaponModifiers[i].WeaponClass.static.AllowedFor(w.class, p) )
            rw[rw.Length] = RPGMut.WeaponModifiers[i].WeaponClass;
    for(i = 0; i < rw.Length; i++)
    {
        f = rw[i].static.AdjustBotDesire(b);
        if(best == none || desire < f )
        {
            best = rw[i];
            desire = f;
        }
    }
    if(best != none)
        servermakemodifier(best);
}

function Activate()
{
    if(statsinv!=none)
        statsinv.activateplayer();
	if (Instigator != None && Instigator.Controller != None)
	{
		if(Instigator.Controller.Adrenaline < getCost())
		{
			Instigator.ReceiveLocalizedMessage(MessageClass, getCost(), None, None, Class);
			bActive = false;
			GotoState('');
			return;
		}

        if(playercontroller(instigator.controller) != none)
            clientmake();
        else
            botselect();

			bActive = false;
			GotoState('');
			return;
	}
	else
	{
		bActive = false;
		GotoState('');
		return;
	}
}

function servermakemodifier(class<rpgweapon> rw)
{
    local weapon w;
    local rpgweapon r;
    local vehicle v;
    local shader s;
    local inventory i;

    V = Vehicle(Instigator);
    if (V != None && V.Driver != None)
        RealInstigator = V.Driver;
    else
        RealInstigator = Instigator;
    if(realinstigator == none || rw == none || instigator.controller == none || realinstigator.Weapon == none)
        return;
    if(Instigator.Controller.Adrenaline < getCost())
    {
        Instigator.ReceiveLocalizedMessage(MessageClass, getCost(), None, None, Class);
        bActive = false;
        GotoState('');
        return;
    }
    if(rpgweapon(realinstigator.Weapon) != none)
    {
        w = rpgweapon(realinstigator.Weapon).ModifiedWeapon;
        if( w == none || rw == rpgweapon(realinstigator.Weapon).Class || !rw.static.allowedfor(w.Class,realinstigator) )
            return;
        for(i = realinstigator.Inventory; i != none; i = i.Inventory)
            if( i.Class == rw && rpgweapon(i).ModifiedWeapon != none && rpgweapon(i).ModifiedWeapon.Class == w.Class)
                return;
        if(rw_EnhancedInfinity(realinstigator.Weapon) != none)
            rw_EnhancedInfinity(realinstigator.Weapon).resetammo();
        rpgweapon(realinstigator.Weapon).ModifiedWeapon = none;
        s = rpgweapon(realinstigator.Weapon).ModifierOverlay;
        realinstigator.Weapon.Destroy();
    }
    else
    {
        w = realinstigator.Weapon;
        for(i = realinstigator.Inventory; i != none; i = i.Inventory)
            if( i.Class == rw && rpgweapon(i).ModifiedWeapon != none && rpgweapon(i).ModifiedWeapon.Class == w.Class)
                return;
        if( rw.static.allowedfor(w.Class,realinstigator) )
            realinstigator.DeleteInventory(w);
        else return;
    }
    r = realinstigator.Spawn(rw,realinstigator);
    r.Modifier = r.MinModifier;
    r.SetModifiedWeapon(w,false);
    r.GiveTo(realinstigator);
    Weapon = r;
    if(Weapon != None)
    {
        Instigator.Controller.Adrenaline -= getCost();
        bActive = false;
        if(s != none && r.ModifierOverlay == none)
            r.SetOverlayMaterial(none,1000000.0,true);
        if(Instigator == realinstigator)
            ClientSwitchWeapon(none, r);
        GotoState('');
    }
    else
    {
        Instigator.ReceiveLocalizedMessage(MessageClass, 2000, None, None, Class);
        bActive = false;
        GotoState('');
    }
}

simulated function ClientSwitchWeapon(weapon oldweapon, weapon newweapon)
{
    if( instigator == none || newweapon == none || instigator.weapon == newweapon)
    {
	    if(playercontroller(instigatorcontroller) != none && playercontroller(instigatorcontroller).Player != none &&
            GUIController(playercontroller(instigatorcontroller).Player.GUIController) != none &&
            WeaponModifierMenu(GUIController(playercontroller(instigatorcontroller).Player.GUIController).toppage() ) != none)
            WeaponModifierMenu(GUIController(playercontroller(instigatorcontroller).Player.GUIController).toppage() ).InitMenu();
        return;
    }
    instigator.PendingWeapon = newweapon;
    instigator.StopWeaponFiring();
	if ( instigator.Weapon == None )
		instigator.ChangedWeapon();
	else
		instigator.Weapon.PutDown();
	if(playercontroller(instigatorcontroller) != none && playercontroller(instigatorcontroller).Player != none &&
        GUIController(playercontroller(instigatorcontroller).Player.GUIController) != none &&
        WeaponModifierMenu(GUIController(playercontroller(instigatorcontroller).Player.GUIController).toppage() ) != none)
        WeaponModifierMenu(GUIController(playercontroller(instigatorcontroller).Player.GUIController).toppage() ).InitMenu();
}

exec function TossArtifact()
{
	//do nothing. This artifact cant be thrown
}

function DropFrom(vector StartLocation)
{
	if (bActive)
		GotoState('');
	bActive = false;

	Destroy();
	if(instigator != none && instigator.Health > 0)
	    Instigator.NextItem();
}

static function string GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
	if (Switch == 2000)
		return "Unable to modify magic weapon";
		return switch @ "Adrenaline is required to generate a magic weapon";
}

function calculatecost()
{
    minadrenalinecost = getcost();
}

function int getCost()
{
	return 150;
}

defaultproperties
{
     bOpen=True
     CostPerSec=1
     MinActivationTime=0.000001
     Index=4
     IconMaterial=Texture'XGameTextures.SuperPickups.Udamage'
     ItemName="Magic Weapon Maker"
}
