class JGP_Unmaker : Weapon
{
	int sideBeamOffset;
	protected int unmklevel;

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
		owner.A_TakeInventory("JGP_UnmakerKeyCyan", 0);
		owner.A_TakeInventory("JGP_UnmakerKeyOrange", 0);
		owner.A_TakeInventory("JGP_UnmakerKeyPurple", 0);
	}

	static int LevelUp(Actor carrier)
	{
		if (!carrier)
			return -1;
		
		JGP_Unmaker um = JGP_Unmaker(carrier.FindInventory("JGP_Unmaker"));
		if (um)
		{
			um.GetLevel();
			return um.unmklevel;
		}

		return -1;
	}

	int GetLevel()
	{
		if (!owner)
			return -1;

		int lv = 0;
		if (owner.FindInventory("JGP_UnmakerKeyCyan"))
			lv++;
		if (owner.FindInventory("JGP_UnmakerKeyOrange"))
			lv++;
		if (owner.FindInventory("JGP_UnmakerKeyPurple"))
			lv++;
		
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

	override void AttachToOwner(Actor other)
	{
		super.AttachToOwner(other);
		GetLevel();
	}

	action void FireSingleBeam(double angleofs, int damage = 10)
	{
		damage *= random(1, 8);
		double aSlope = BulletSlope();
		double aAngle = angle + angleofs;
		let puf = JGP_UnmakerPuff(LineAttack(aAngle, 4096, aSlope, damage, 'Hitscan', "JGP_UnmakerPuff", LAF_NORANDOMPUFFZ));
		vector2 trackerOfs = AngleToVector(angle - 90, angleofs);
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
		//let beam = JGP_UnmakerBeam(JGP_UnmakerBeam.Create(
		//A_FireBullets(angleofs, 0, -1, damage, "JGP_UnmakerPuff", FBF_NoRandom|FBF_NoFlash|FBF_NoRandomPuffZ|FBF_ExplicitAngle, missile: "JGP_UnmakerBeamTracker", spawnheight: 0);
	}

	action void A_FireUnmaker()
	{
		if (!player)
			return;
		
		let psp = player.FindPSprite(OverlayID());
		if (!psp)
			return;

		int ulevel = invoker.GetLevel();

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
		
		A_StartSound("gzunmaker/fire", CHAN_WEAPON);
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

class JGP_UnmakerBeam : JGPUNM_LaserBeam
{
	double alphadir;
	
	Default
	{
		Renderstyle 'Normal';
		Alpha 1.0;
		xscale 2.85;
		+BRIGHT
	}
}

class JGP_UnmakerBeamTracker : Actor
{
	JGP_UnmakerBeam beam;
	vector3 endpos;

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
		//beam.StartTracking(endpos);
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

class JGP_UnmakerKeyBase : Inventory abstract
{
	color keycolor;
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
		A_AttachLight(
			"UnmakerKeyLight", 
			DynamicLight.PointLight, 
			keycolor,
			baseLightSize - curstate.frame * lightSizeStep,
			0,
			flags: DYNAMICLIGHT.LF_ATTENUATE,
			ofs: (0, 0, 32)
		);

		if (random[unmp](1, 2) == 2)
		{
			double vx = frandom[unmp](0.3, 1.0);
			double vz = frandom[unmp](0.3, 0.9);
			int lt = random[unmp](18, 25);
			A_SpawnParticle(
				keycolor,
				flags: SPF_RELATIVE|SPF_FULLBRIGHT,
				lifetime: lt,
				size: random[unmp](3,5),
				angle: random[unmp](0, 359),
				xoff: frandom[unmp](-12,12),
				zoff: frandom[unmp](40, 48),
				velx: vx,
				velz: vz,
				accelx: -(vx * 0.1),
				accelz: -(vz * 0.05),
				sizestep: -0.03
			);
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