// [!] You should not make a change here if you have no idea to edit this properly.
// |======================|  Features  |======================| \\
 // [!] Please read "! HowToConfig.txt" for configurating instruction.
  #define enableClouds           // [!] Disabling this could help shaders run faster.
  #define enableStars            // [!] Disabling this could potentially help shaders run faster.
  //#define enableAurora           // [!] Harmful to shaders' performance.
  #define enableAO               // (i) Ambient occlusion
  #define enablePBR              // (i) Physically-Based Rendering
  #define enableFXAA             // (i) Fast-approximate Anti-Aliasing
  //#define enableCaustic          // [!] Potentially harmful to shaders' performance.
  #define enableWetEffect        // [!] Disabling this could help shaders run faster.
  #define enableFog              // [!] Indirectly effect the overall visuals, but also potentially harmful to performance.
 
 
 
// |====================|  Post-process  |====================| \\
 // (i) Tonemapper
  #define tExposure 0.85         // (i) Multiply the color
  #define tContrast 0.85         // (i) [ = 1 ] : Linear, [ > 1 ] : Contrast, [ < 1 ] : Gamma
  #define tSaturation 1.15       // (i) Color saturation ( Like, obviously. )
  
  
  
// |========================|  Sl2y  |========================| \\
 // (i) Clouds
  #define cloudsMode 1           // (i) 0 : Fluffy clouds
                                 //          [!] Performance disaster.
                                 //     1 : Blocky clouds
                                 //          [!] Performance harmful, but not as much as fluffy one.

 // (i) Stars
  #define enableStarsShooting    // (i) Shooting stars..?
  #define sShootingSpeed 1.0     // (i) Stars shooting speed
  
  
  
// |======================|  Terrains  |======================| \\
 // (i) Ambient occlusion
  #define aoIntensity 6.0        // (i) [ ambientOcclusion^aoIntensity ]

 // (i) Shadows
  #define shStyle 0              // (i) 0 : Every single block in existence has its own shadow.
                                 //          [!] Glitched on some of blocks, like slabs.
                                 //     1 : Only a group of blocks has a shadow.
                                 //          [!] Unlike the 0, there's no glitches.

 // (i) Fog
  #define unloadedChunksFog      // (i) Sky-liked color fog in a certain distance which chunks didn't loaded.
                                 //      [!] Performance harmful-o-meter : sky_shaders*2.0
  #define fakeSunBloom           // (i) I should've called it "sun mist", "sun fog", something like this. But people seem to be used to "Bloom" more.
  
 // (i) Miscellaneous
  //#define soulValleyBlueLight    // (i) Blue color source lights in Soul Sand Valley biome.
                                 //      [!] Not stable (glitches occured : transition to Basalt Deltas and Wrapped Forest biomes)
  #define RBlobbyLight           // (i) Red-Blue dirlight of the character in the lobby/menu.



// configuration.file("end");















































// Name : EVBE's configurator file v0.8r
// Notice : -
// Date : 3/6/2023
// (c) 2023 CuteBoii, all rights reserved.