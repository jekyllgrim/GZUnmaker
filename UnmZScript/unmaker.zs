class JGP_Unmaker : Weapon
{
    int sideBeamOffset;
    protected int unmklevel;
    const MAXLEVEL = 3;

    // The original tic values are 8, 5 and 4,
    // but D64's ticrate is 30, not 35.
    // Adding 1 tic for Doom feels fair, but
    // feel free to adjust this.
    enum EFirerates 
    {
        FIRERATE_LV0 = 9,
        FIRERATE_LV1 = 6,
        FIRERATE_LV2 = 5,
    }
    
    override void OwnerDied()
    {
        unmklevel = 0;
    }

    clearscope int GetLevel()
    {
        return unmklevel;
    }

    static int LevelUp(Actor carrier)
    {
        if (!carrier)
            return -1;
        
        JGP_Unmaker um = JGP_Unmaker(carrier.FindInventory("JGP_Unmaker"));
        if (um)
        {
            um.unmklevel = Clamp(um.unmklevel + 1, 0, JGP_Unmaker.MAXLEVEL);
            return um.unmklevel;
        }

        return -1;
    }

    Default
    {
        Weapon.slotnumber 8;
        Weapon.ammoType "Cell";
        Weapon.ammouse 1;
        Weapon.ammoGive 80;
        Tag "Unmaker";
        Inventory.PickupMessage "What the !@#%* is this!";
    }

    override void AttachToOwner(Actor other)
    {
        super.AttachToOwner(other);
        if (owner)
        {
            owner.A_GiveInventory("JGP_Unmaker", 1);
        }
    }

    action void FireSingleBeam(double angleofs, int damage = 10)
    {
        damage *= random(1, 8);
        A_FireBullets(angleofs, 0, -1, damage, "JGP_UnmakerPuff", FBF_NoRandom|FBF_NoRandomPuffZ|FBF_ExplicitAngle, missile: "JGP_UnmakerProjectile", spawnheight: 0);
    }

    action void A_FireUnmaker()
    {
        if (!player)
            return;
        
        let psp = player.FindPSprite(OverlayID());
        if (!psp)
            return;

        int ulevel = invoker.unmklevel;

        int ttics = FIRERATE_LV0;
        switch (ulevel) {
        case 1:
            ttics = FIRERATE_LV1;
            break;
        case 2:
        case 3:
            ttics = FIRERATE_LV2;
            break;
        }
        A_SetTics(ttics);

        switch (ulevel) {       
        default:
            invoker.ammouse1 = invoker.default.ammouse1;
            break;
        case 2:
            invoker.ammouse1 = 2;
            break;
        case 3:
            invoker.ammouse1 = 3;
            break;            
        }

        if (!invoker.DepleteAmmo(false))
            return;
        
        A_StartSound("weapons/unmaker/fire", CHAN_WEAPON);
        A_Overlay(100, "UnFlash");
        
        if (ulevel <= 1)
        {
            FireSingleBeam(0);
        }

        if (ulevel == 2)
        {
            FireSingleBeam(2);
            FireSingleBeam(-2);
        }

        if (ulevel >= 3)
        {
            FireSingleBeam(0);

            invoker.sideBeamOffset += 3;
            if (invoker.sideBeamOffset > 12)
                invoker.sideBeamOffset = 3;
            
            FireSingleBeam(invoker.sideBeamOffset);
            FireSingleBeam(-invoker.sideBeamOffset);
        }
    }

    States {
    Spawn:
        LGUN A -1;
        stop;
    
    Select:
        LASR A 1 A_Raise;
        loop;
    
    Deselect:
        LASR A 1 A_Lower;
        loop;
    
    Ready:
        LASR A 1 A_WeaponReady;
        loop;

    Fire:
        LASR A 8 A_FireUnmaker();
        TNT1 A 0 A_ReFire();
        TNT1 A 0
        {
            invoker.sideBeamOffset = 0;
        }
        goto Ready;

    UnFlash:
        TNT1 A 0 
        {
            A_OverlayFlags(OverlayID(), PSPF_RenderStyle|PSPF_ForceAlpha, true);
            A_OverlayRenderstyle(OverlayID(), STYLE_Add);
        }
        LASR IHGFEDCB 1 bright;
        stop;
    }
}

class JGP_UnmakerPuff : Actor
{
    Default
    {
        -ALLOWPARTICLES
        +NOINTERACTION
        +BRIGHT
        +PUFFONACTORS
        RenderStyle 'Add';
    }

    States {
    Spawn:
    XDeath:
        TNT1 A 1;
        stop;
    Crash:
        LPUF AB 2;
    Fade:
        LPUF AB 2 A_FadeOut(0.2);
        loop;
    }
}

class JGP_UnmakerProjectile : Actor
{
    Default
    {
        Projectile;
        damage 0;
        +THRUACTORS
        +BRIGHT
        speed 64;
    }

    override void PostBeginPlay()
    {
        super.PostBeginPlay();
        A_FaceMovementDirection();
    }

    States {
    Spawn:
        AMRK DCB 1;
        AMRK A -1;
        stop;
    Death:
        AMRK BCD 1;
        stop;
    }
}

class JGP_UnmakerKeyBase : Inventory abstract
{
    Default
    {
        +INVENTORY.AUTOACTIVATE
        Inventory.maxamount 1;
        Inventory.pickupsound "misc/p_pkup";
    }

    override bool Use (bool pickup)
    {
        if (owner)
        {
            JGP_Unmaker.LevelUp(owner);
            return true;
        }
        return false;
    }
}

class JGP_UnmakerKeyOrange : JGP_UnmakerKeyBase
{
    Default
    {
        Inventory.Pickupmessage "You have a feeling that that it wasn't to be touched...";
    }

    States {
    Spawn:
        ART1 ABCDEDCB 2;
        loop;
    }
}

class JGP_UnmakerKeyPurple : JGP_UnmakerKeyBase
{
    Default
    {
        Inventory.Pickupmessage "Whatever it is, it doesn't belong in this world...";
    }

    States {
    Spawn:
        ART2 ABCDEDCB 2;
        loop;
    }
}

class JGP_UnmakerKeyCyan : JGP_UnmakerKeyBase
{
    Default
    {
        Inventory.Pickupmessage "It must do something...";
    }

    States {
    Spawn:
        ART3 ABCDEDCB 2;
        loop;
    }
}