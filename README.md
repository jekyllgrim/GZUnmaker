# GZUnmaker

An accurate recreation of the Doom 64 Unmaker weapon for GZDoom using ZScript. **This is not a gameplay mod** (the Unmaker and its keys  won't automatically spawn in maps, and it's not set up to replace any of the vanilla Doom weapons), this is a resource. Authors can add it to their projects. To add it to your project, you will need the following:

1. Give [DoomEdNums aka editor numbers](https://zdoom.org/wiki/MAPINFO/Editor_number_definition) to the `JGP_Unmaker` class. Giving it a DoomEdNum will let you place it in your custom maps.
   
   This is the Unmaker itself. By default it's assigned to slot 8. If you want to change that, modify the slot in the Default block of the JGP_Unmaker class.

2. Give DoomEdNums to `JGP_UnmakerKeyCyan`, `JGP_UnmakerKeyOrange` and `JGP_UnmakerKeyPurple` classes. Giving them DoomEdNums will let you place them in your custom maps.
   
   These are the Demon Keys that upgrade the Unmaker.Keys can be collected in any order and will upgrade the Unmaker's level. Keys can be collected *before* getting the Unmaker as well; in this case the Unmaker's level will be set when you receive for the first time.

## License

MIT License. This means that anyone can use this code for any purpose, just give credit to me (and other authors, see Credits below), and copy the LICENSE.txt file (found under the UnmZScript folder).

## How accurate is this version to the Doom 64 Unmaker?

This version of the Unmaker accurately emulates the following:

* Different power levels that are increased by collecting Demon Keys. Levels increase the number of beams fired by it, and the gun's firerate.

* The damage is the same as the original: 10 * 1d8 (meaning, between 10–80 damage per shot).

* Accurate emulation of the beam behavior: the base attack is a hitscan; beams instantly extend from the gun towards the points of impact, and then gradually fold into those points until they disappear.

* The gun's icon changes to reflect the level.

* Uses original graphics.

There are some visual "lore-friendly" changes to add a tiny bit of flair:

* The gun's muzzle flash isn't a static image, but instead has some fluctuating animation.

* The gun uses a red dynamic light around the player when fired.

* The beams are made with simple 3D models, and their animation (folding) is smoother than in Doom 64.

* Demon keys have dynamic lights attached and also spawn some colored particles.

Mechanical differences:

Like in the original, GZUnmaker's fire speed increases with level. However, Doom 64 has a ticrate of 30, while GZDoom (and vanilla Doom) has a ticrate of 35, so perfectly accurate emulation of speeds is simply not possible due to the different speeds of the engine. For reference, Doom 64 Unmaker's fire speeds are: **3.75** shots/sec (no demon keys), **5** shots/sec (1 demon key) and **7.5** shots/sec (2 or more demon keys). As the closest possible compromise, GZUnmaker has fire speeds of **3.88**, **5.83** and **7** shots per second respectively. (If you want to know why the second value is 5.83 and not 5, which is possible in GZDoom, this is mainly to keep the dynamics of the progression similar to the original between levels.)

You can adjust firing speeds by editing the `EFirerates` enum block in the JGP_Unmaker class. The constants `FIRERATE_LV0`, `FIRERATE_LV1` and `FIRERATE_LV2` contain the values that determine per how many tics a shot can be fired at level 0, level 1 and levels 2-3. 

## Credits

Agent_Ash - code, graphics editing

Midway Studios - original concept, graphics
