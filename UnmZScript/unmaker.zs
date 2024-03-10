// Imitation of Doom 64 Unmaker by Agent_Ash aka Jekyll Grim Payne

class JGP_Unmaker : Weapon
{
	int sideBeamOffset; // holds the angle offset of the side beams
	protected int unmklevel; // holds the current Unmaker level (0-3)

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
	
	// Remove keys and reset Unmaker level on death.
	// Honestly, I don't know why this is here. Everyone keeps saying how 
	// "Demon Keys are lost upon death", but it's a meaningless statement.
	// ALL items are lost upon death in Doom. Demon Keys are not special
	// and they don't need any kind of special handling. The only reason
	// for this override to exist is multiplayer with "keep inventory"
	// setting, I guess.
	override void OwnerDied()
	{
		unmklevel = 0;
		owner.A_TakeInventory("JGP_UnmakerKeyCyan", 0);
		owner.A_TakeInventory("JGP_UnmakerKeyOrange", 0);
		owner.A_TakeInventory("JGP_UnmakerKeyPurple", 0);
	}

	// A static function that finds Unmaker in the carrier's inventory
	// and raises its level. Demon Keys call this when they're picked
	// up. If the level was successfully set, returns the updated
	// level. Otherwise returns -1.
	static int LevelUp(Actor carrier)
	{
		if (!carrier)
			return -1;
		
		// Find Unmaker in the carrier's inventory:
		JGP_Unmaker um = JGP_Unmaker(carrier.FindInventory("JGP_Unmaker"));
		if (um)
		{
			// update the level:
			um.GetLevel();
			return um.unmklevel;
		}

		return -1;
	}

	// This really should be called "UpdateLevel", but it is what it is.
	// This function updates the unmklevel variable to make sure it
	// reflects the Unmaker's current level. It really didn't have to
	// be done like that; the Demon Keys could just increment unmklevel
	// manually, but I wanted to wrap it all into a function. This also
	// updates the level regardless of the order of keys. AND this updates
	// Unmaker's HUD icon!
	int GetLevel()
	{
		if (!owner)
			return -1;

		int lv = 0;
		// Increment level by 1 for each of the Demon Keys:
		if (owner.FindInventory("JGP_UnmakerKeyCyan"))
			lv++;
		if (owner.FindInventory("JGP_UnmakerKeyOrange"))
			lv++;
		if (owner.FindInventory("JGP_UnmakerKeyPurple"))
			lv++;
		
		// Update the HUD icon based on the level (the icon is
		// defined in TEXTURES):
		name iconName = "LGUNA0";
		switch (lv) {
		case 1:
			iconName = "LGUNB0";
			break;
		case 2:
			iconName = "LGUNC0";
			break;
		case 3:
			iconName = "LGUND0";
			break;
		}

		Icon = TexMan.CheckForTexture(iconName, TexMan.Type_Any, TexMan.Type_Any);

		unmklevel = lv;
		return unmklevel;
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

	// Update the level once the gun is received:
	override void AttachToOwner(Actor other)
	{
		super.AttachToOwner(other);
		GetLevel();
	}

	// Fires a single beam at the specified angle, dealing specified damage:
	action void FireSingleBeam(double angleofs, int damage = 10)
	{
		// Vanilla Unmaker multiplies damage by 1d8:
		damage *= random(1, 8);
		// Vertical slope is sensitive to vertical autoaim, so we use
		// the vanilla BulletSlope() function to obtain it:
		double aSlope = BulletSlope();
		// Calculate angle relative to player angle:
		double aAngle = angle + angleofs;
		// Lineattack. Note that 64 Unmaker has a range of 4096, as opposed
		// to normal hitscans that have 8192:
		let puf = JGP_UnmakerPuff(LineAttack(aAngle, 4096, aSlope, damage, 'Hitscan', "JGP_UnmakerPuff", LAF_NORANDOMPUFFZ));
		// Fire a projectile aimed at a puff. Using SpawnPlayerMissile here
		// to get around any special implicit behavior from A_FireProjectile.
		// SpawnPlayerMissile uses absolute angle, so we need to calculate the
		// angle to fire the projectile at from the player's angle:
		vector2 trackerOfs = AngleToVector(angle - 90, angleofs);
		// This projectile is used to handle the visuals of the beam. The projectile
		// is f ired at the puff, then a beam actor (JGP_UnmakerBeam) is created,
		// and the 3D-model beam is stretched from the projectile to the puff.
		// This imitates the behavior of the original Unmaker, where the beam immediately
		// stretches over the whole distance, and then gradually starts disappearing
		// from the beginning.
		let tracker = JGP_UnmakerBeamTracker(SpawnPlayerMissile("JGP_UnmakerBeamTracker", aAngle, trackerOfs.x, trackerOfs.y, -16));
		if (tracker && puf)
		{
			// Get difference between tracker position and puff position:
			let diff = Level.Vec3Diff(tracker.pos, puf.pos);
			// If it's too short, destroy the tracker. Otherwise it can
			// cause weird angles and visuals due to how projectiles
			// behave:
			if (diff.Length() <= tracker.speed)
			{
				tracker.Destroy();
			}
			// Otherwise launch the tracker at the puff:
			let dir = diff.Unit();
			tracker.vel = dir * tracker.speed;
			tracker.A_FaceMovementDirection();
		}
	}

	// A dedicated function to perform the Unmaker attack.
	action void A_FireUnmaker()
	{
		if (!player)
			return;

		// Get the level:
		int ulevel = invoker.GetLevel();

		// Modify ammouse based on the level:
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
		// Try consuming ammo. Stop here if 
		// the player doesn't have enough ammo:
		if (!invoker.DepleteAmmo(false))
		{
			return;
		}

		// Determine the duration of the firing frame
		// based on the level:
		int ttics;
		switch (ulevel) {
		default:
			ttics = FIRERATE_LV0;
		case 1:
			ttics = FIRERATE_LV1;
			break;
		case 2:
		case 3:
			ttics = FIRERATE_LV2;
			break;
		}
		// Set duration:
		A_SetTics(ttics);

		
		// Sound and flash:
		A_StartSound("gzunmaker/fire", CHAN_WEAPON);
		A_Overlay(100, "UnFlash");
		
		// Now, perform the actual attacks based on level.

		// Levels 0-1: a single forward beam:
		if (ulevel <= 1)
		{
			FireSingleBeam(0);
		}

		// Level 2: two extra beams to the right/left:
		if (ulevel == 2)
		{
			FireSingleBeam(2);
			FireSingleBeam(-2);
		}

		// Level 3: the side beams are being gradually moved,
		// their current angle is stored in sideBeamOffset variable:
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
			// Reset sideBeamOffset immediately if
			// we stopped firing:
			invoker.sideBeamOffset = 0;
		}
		goto Ready;

	// A bit of a fancier flash than in the original:
	UnFlash:
		TNT1 A 0 
		{
			// Additive flash:
			A_OverlayFlags(OverlayID(), PSPF_RenderStyle|PSPF_ForceAlpha, true);
			A_OverlayRenderstyle(OverlayID(), STYLE_Add);
			// Add dynami light:
			A_AttachLight(
				"UnmakerMuzzleFlash",
				DynamicLight.FlickerLight ,
				"ff350d",
				80,
				72,
				DYNAMICLIGHT.LF_ATTENUATE,
				param: 0.2
			);

		}
		LASR IHGFEDCB 1 bright;
		TNT1 A 0 A_RemoveLight("UnmakerMuzzleFlash");
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

// Beam actor, based on the beam from GZBeamz.
// Slightly bigger than normal and uses Normal
// renderstyle to imitate the original look:
class JGP_UnmakerBeam : JGPUNM_LaserBeam
{
	Default
	{
		Renderstyle 'Normal';
		Alpha 1.0;
		xscale 2.85;
		+BRIGHT
	}
}

// Pseudo projectile fired by the attack. Aimed at a puff.
// The 3D beam is stretched between it and the puff.
class JGP_UnmakerBeamTracker : Actor
{
	JGP_UnmakerBeam beam;

	Default
	{
		Projectile;
		+BLOODLESSIMPACT
		damage 0;
		speed 56;
		radius 1;
		height 1;
	}

	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		beam = JGP_UnmakerBeam(JGPUNM_LaserBeam.Create(self, 0, 0, 0, type: "JGP_UnmakerBeam"));
		beam.SetEnabled(true);
	}

	States {
	Spawn:
		TNT1 A -1;
		stop;
	Death:
		TNT1 A 1
		{
			if (beam)
				beam.Destroy();
		}
		stop;
	}
}

// Base class for keys. Keys are simple items.
// I added a bit of flair with colored particles.
class JGP_UnmakerKeyBase : Inventory abstract
{
	color keycolor; //color of the particles and the dynamic lights
	property keycolor : keycolor;

	Default
	{
		+INVENTORY.AUTOACTIVATE
		+BRIGHT
		Inventory.maxamount 1;
		Inventory.pickupsound "gzunmaker/key";
		YScale 0.834;
	}

	override void Tick()
	{
		super.Tick();
		if (owner || bNOSECTOR)
		{
			A_RemoveLight("UnmakerKeyLight");
		}
	}

	override bool Use (bool pickup)
	{
		if (owner)
		{
			JGP_Unmaker.LevelUp(owner);
		}
		return false;
	}

	void SpawnLights(double baseLightSize = 36, int lightSizeStep = 3)
	{
		// This dynamically attaches a light whose size
		// depends on the current sprite frame.
		// I'd like a smooth pulselight instead, but those
		// cannot be properly synced with ticrate.
		A_AttachLight(
			"UnmakerKeyLight", 
			DynamicLight.PointLight, 
			keycolor,
			baseLightSize - curstate.frame * lightSizeStep,
			0,
			flags: DYNAMICLIGHT.LF_ATTENUATE,
			ofs: (0, 0, 32)
		);

		FSpawnParticleParams pp;
		pp.color1 = keycolor;
		pp.flags = SPF_FULLBRIGHT;
		pp.startalpha = 1.0;
		pp.fadestep = -1;
		if (random[unmp](1, 2) == 2)
		{
			Vector2 hvel = (frandom[unmp](0.3, 1.0), frandom[unmp](0.3, 1.0));
			pp.vel.xy = Actor.RotateVector(hvel, frandom[unmp](0,360));
			pp.vel.z = frandom[unmp](0.5, 1.2);
			pp.lifetime = random[unmp](25, 35);
			pp.size = random[unmp](3,5);
			pp.pos.x = pos.x + frandom[unmp](-12,12);
			pp.pos.y = pos.y + frandom[unmp](-12,12);
			pp.pos.z = pos.z + frandom[unmp](40, 48);
			pp.accel.xy = -(pp.vel.xy * 0.1);
			pp.accel.z = -(pp.vel.z * 0.05);
			pp.sizestep = -(pp.size / pp.lifetime);
			Level.SpawnParticle(pp);
		}
	}
}

class JGP_UnmakerKeyOrange : JGP_UnmakerKeyBase
{
	Default
	{
		Inventory.Pickupmessage "You have a feeling that that it wasn't to be touched...";
		JGP_UnmakerKeyBase.keycolor "d05f03";
	}

	States {
	Spawn:
		UMK1 ABCDEDCB 4 SpawnLights();
		loop;
	}
}

class JGP_UnmakerKeyPurple : JGP_UnmakerKeyBase
{
	Default
	{
		Inventory.Pickupmessage "Whatever it is, it doesn't belong in this world...";
		JGP_UnmakerKeyBase.keycolor "7800e0";
	}

	States {
	Spawn:
		UMK2 ABCDEDCB 4 SpawnLights();
		loop;
	}
}

class JGP_UnmakerKeyCyan : JGP_UnmakerKeyBase
{
	Default
	{
		Inventory.Pickupmessage "It must do something...";
		JGP_UnmakerKeyBase.keycolor "0ba6da";
	}

	States {
	Spawn:
		UMK3 ABCDEDCB 4 SpawnLights();
		loop;
	}
}