class FlagInv extends inventory;       //ugly hack to give exp to ctf and br flag scorers because that gametypes does the scoring stuff very incompatible way. Also gives exp to all holders of a ganeobject_energycore, cause it's fair;) I'm tired by write hacks for the bad epic code so sorry to men, who died, when returned the flag;)


var() Controller FirstTouch;
var() array<Controller> Assists;
var() gameobject flag;
var() float score[2];
var() rpgrules rpgrulz;
var() unrealpawn holder;
var() vector flagloc,holderloc;
var() MutMCGRPG RPGMut;
var() vehicle holderbase;
var() bool bGameEnded;

state gameobjectcheck
{
    function BaseChange()
    {
        if(flag == none || flag.bPendingDelete)
        {
            disable('tick');
            destroy();
        }
    }
    function tick(float dt)
    {
        local int i;
        local bool found;
        if(flag==none)
            destroy();
        else
        {
            assists.Length=0;
            firsttouch=flag.FirstTouch;
            holder=flag.Holder;
            if(holder!=none)
            {
                holderloc=holder.Location;
                if( vehicle(holder.Base) != none && vehicle(holder.Base).Controller != none)
                {
                    holderbase = vehicle(holder.Base);
                    while(vehicle(holderbase.Base) != none && vehicle(holderbase.Base).Controller != none)
                        holderbase = vehicle(holderbase.Base);
                }
            }
            if(onsweaponpawn(holderbase) != none && onsweaponpawn(holderbase).VehicleBase != none)
                holderbase = onsweaponpawn(holderbase).VehicleBase;
            if(flag.assists.length>0)
            {
                for(i = 0;i < flag.assists.length;i++)
                {
                    assists[assists.length]=flag.assists[i];
                    if(!found && (holderbase == none || holderbase.Controller == flag.assists[i]) )
                        found = true;
                }
            }
            else found = true;
            if(!found)
            {
                assists[assists.length] = holderbase.Controller;
                flag.assists[flag.assists.length] = holderbase.Controller;
            }
            if(!bGameEnded && level.Game.bGameEnded)
                bGameEnded = true;
        }
    }

    function destroyed()
    {
        local proximityobjective go,o;                             //hack for energycore gameobject in assault
        local int i;
        if(!bGameEnded && level.Game.bGameEnded)
        {
            level.Game.bGameEnded = false;
            bGameEnded = true;
        }
        if(holder!=none && holder.playerreplicationinfo!=none && rpgrulz!=none)
        {       //try to catch the pawn which disabled objective with the flag
            foreach holder.RadiusActors(class'proximityobjective',go,max(holder.collisionradius, holder.CollisionHeight) )
            {
                if( go.bdisabled && go.disabledby==holder.playerreplicationinfo )
                {
                    for(i=0;i<assists.length;i++)
                        rpgrulz.awardexp(assists[i],5);
                    o=go;
                    break;
                }
            }
            if(o==none )
                foreach RadiusActors(class'proximityobjective',go,max(holder.collisionradius, holder.CollisionHeight),holderloc)
                {
                    if( go.bdisabled && go.disabledby==holder.playerreplicationinfo )
                    {
                        for(i=0;i<assists.length;i++)
                            rpgrulz.awardexp(assists[i],5);
                        o=go;
                        break;
                    }
                }
            if(bGameEnded)
                level.Game.bGameEnded = true;
        }
        super.Destroyed();
    }
}

function tick(float dt)
{
    local controller c,scorer;
    local int i;
    local pawn p;
    local float dist,oppdist;
    local bool found;

    if(bGameEnded)
    {
        disable('tick');
        destroy();
        return;
    }
    else if(flag==none)
        destroy();
    else
    {
        if(assists.Length>0 && flag.Assists.Length==0 && rpgrulz!=none)  //flag reseted at the previous frame
        {
            if( score[0]==level.GRI.Teams[0].Score && score[1]==level.GRI.Teams[1].Score)
            {      //try to find the player who returned the flag
                if(ctfflag(flag)!=none)
                    foreach radiusactors(class'pawn',p,max(flag.CollisionHeight, flag.CollisionRadius),flagloc)    //fuck
                    {
                        if(fasttrace(flagloc,p.location) && p.bCollideActors && p.Controller!=none && p.Controller.bIsPlayer &&
                            p.bCanPickupInventory && p.PlayerReplicationInfo!=none && p.PlayerReplicationInfo.team!=none &&
                            p.PlayerReplicationInfo.team == ctfflag(flag).Team )
                        {
                            scorer=p.Controller;
		                    Dist = vsize(FlagLoc - Flag.HomeBase.Location);
		                    oppDist = vsize(FlagLoc - Flag.HomeBase.Location);

                            if (Dist>1024)
		                    {
			                    // figure out who's closer
			                    if (Dist<=oppDist)	// In your team's zone
			                    {
				                    rpgrulz.awardexp(Scorer,5);
		                        }
			                    else
			                    {
				                    rpgrulz.awardexp(Scorer,10);
				                    if (oppDist<=1024)	// Denial
				                    {
  					                    rpgrulz.awardexp(Scorer,15);
			                        }
                                }
                            }
                            break;
                        }
                    }
                }
                else
                {
                    if(!bGameEnded && level.Game.bGameEnded)
                    {
                        level.Game.bGameEnded = false;
                        bGameEnded = true;
                    }
                    for(i=0;i<assists.length;i++)
                    {
                        c=assists[i];
                        if(c!=none && c.PlayerReplicationInfo!=none && c.PlayerReplicationInfo.team!=none &&
                            c.PlayerReplicationInfo.team.Score > score[c.PlayerReplicationInfo.team.TeamIndex] )  //maybe that team scored since last tick
                        {
                            rpgrulz.awardexp(c,max(20/assists.Length,2)+10*int(i==0)+5*int(holder!=none && holder==c.Pawn));
                        }
                    }
                    if(bGameEnded)
                        level.Game.bGameEnded = true;
                }
        }
        flagloc=flag.Location;
        score[0]=level.GRI.Teams[0].Score;
        score[1]=level.GRI.Teams[1].Score;
        assists.Length=0;
        firsttouch=flag.FirstTouch;
        holder=flag.Holder;
        if(holder!=none)
        {
            holderloc=holder.Location;
            if( vehicle(holder.Base) != none && vehicle(holder.Base).Controller != none)
            {
                holderbase = vehicle(holder.Base);
                while(vehicle(holderbase.Base) != none && vehicle(holderbase.Base).Controller != none)
                    holderbase = vehicle(holderbase.Base);
            }
        }
        if(onsweaponpawn(holderbase) != none && onsweaponpawn(holderbase).VehicleBase != none)
            holderbase = onsweaponpawn(holderbase).VehicleBase;
        if(flag.assists.length>0)
        {
            for(i = 0;i < flag.assists.length;i++)
            {
                assists[assists.length]=flag.assists[i];
                if(!found && (holderbase == none || holderbase.Controller == flag.assists[i]) )
                    found = true;
            }
        }
        else found = true;
        if(!found)
        {
            assists[assists.length] = holderbase.Controller;
            flag.assists[flag.assists.length] = holderbase.Controller;
        }
        if(!bGameEnded && level.Game.bGameEnded)
            bGameEnded = true;
    }
}

function destroyed()
{
    super.Destroyed();
}

defaultproperties
{
     RemoteRole=ROLE_None
     bGameRelevant=True
}
