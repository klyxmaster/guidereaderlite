
GuideReaderLite_RegisterGuide("Winterspring (54-55)", "Burning Steppes (55-56)", "Alliance", function()
return [[
R Moonglade |N|Travel through Timbermaw Hold and exit into Winterspring. Speak with Salfa, who stands guard outside the entrance to Timbermaw Hold.| |C|Death Knight, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock, Warrior| |QID|8465|  |M|27.73 34.50|
f Get Fight Point |N|(48.1,67.3)| |C|Death Knight, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock, Warrior| |Z|Moonglade| |QID|8465|  |M|27.73 34.50|

R Winterspring |N|Travel through Timbermaw Hold and exit into Winterspring. Speak with Salfa, who stands guard outside the entrance to Timbermaw Hold.| |QID|8465|  |M|27.73 34.50|
T Speak to Salfa  |M|13.09,85.56| |QID|8465| |N|\n|
A Winterfall Activity  |M|13.09,85.56| |QID|8464| |N|Accept Winterfall Activity|
N Grab feathers you see |N|For "Moontouched Wildkin"| |QID|978| |NORAF|  |M|55.50 92.05|
T The New Springs  |Z|Winterspring| |M|41.82,88.56| |QID|980| |N|\n|
A Strange Sources  |M|41.82,88.56| |QID|4842| |N|Accept Strange Sources|
T It's a Secret to Everybody (Part 3)  |M|41.82,88.56| |QID|3908| |N|\n|
A Threat of the Winterfall  |M|41.82,88.56| |QID|5082| |N|Accept Threat of the Winterfall|

R Everlook |N|Follow the road east|
A Enraged Wildkin (Part 1)   |QID|6604| |N|Accept Enraged Wildkin|  |M|61.12 38.43|
h Everlook |QID|977| |N|Make this Inn your home|  |M|60.88 37.62|
A The Everlook Report   |QID|6028| |N|Accept The Everlook Report|  |M|61.35 38.97|
A Duke Nicholas Zverenhoff   |QID|6030| |N|Accept Duke Nicholas Zverenhoff|  |M|61.35 38.97|
A Sister Pamela   |QID|5601| |N|Accept Sister Pamela|  |M|61.28 38.98|
A Are We There, Yeti? (Part 1)   |QID|3783| |N|Accept Are We There, Yeti?|  |M|60.88 37.62|

C Strange Sources  |QID|4842| |N|Follow Donova Snowden's instructions, then report back.|  |M|31.27 45.16|

H Everlook  |QID|977| |N|Hearth back|  |M|60.88 37.62|
C Are We There, Yeti? (Part 1)  |NORAF|  | |QO|1| |QID|3783| |N|Collect 10 Thick Yeti Furs for Umi Rumplesnicker in Everlook.|  |M|60.88 37.62|
T Are We There, Yeti? (Part 1)   |QID|3783| |N|Return to Umi Rumplesnicker at Everlook in Winterspring.|  |M|60.88 37.62|
A Are We There, Yeti? (Part 2)   |QID|977| |N|Accept Are We There, Yeti?|  |M|60.88 37.62|
C Are We There, Yeti? (Part 2)  |NORAF|  | |QO|1| |QID|977| |N|Collect 2 Pristine Yeti Horns for Umi Rumplesnicker in Everlook.|  |M|60.88 37.62|
T Are We There, Yeti? (Part 2)   |QID|977| |N|Return to Umi Rumplesnicker at Everlook in Winterspring.|  |M|60.88 37.62|
A Are We There, Yeti? (Part 3)   |QID|5163| |N|Accept Are We There, Yeti?|  |M|60.88 37.62|
N Scare Legacki |N|East of the inn, use the Yeti| |U|12928| |QID|5163| |QO|Scare Legacki: 1/1| |NORAF|  |M|60.88 37.62|

C Winterfall Activity  |QO|1| |QID|8464| |N|Salfa wants you to kill 8 Winterfall Shaman, 8 Winterfall Den Watchers, and 8 Winterfall Ursa.  Salfa is located just outside the entrance to Timbermaw Hold in Winterspring.$B|  |M|27.73 34.50|
T To Winterspring!   |QID|5249| |N|\n|  |M|51.97 30.39|
T Starfall   |QID|5250| |N|\n|  |M|51.97 30.39|
A The Ruins of Kel'Theril   |QID|5244| |N|Accept The Ruins of Kel'Theril|  |M|51.97 30.39|
T Enraged Wildkin (Part 1)   |QID|6604| |N|\n|  |M|52.14 30.43|
T The Ruins of Kel'Theril   |QID|5244| |N|\n|  |M|52.14 30.43|
A Troubled Spirits of Kel'Theril   |QID|5245| |N|Accept Troubled Spirits of Kel'Theril|  |M|52.14 30.43|

C Troubled Spirits of Kel'Theril  |QO|1| |QID|5245| |N|Use Jaron's Pick to find the four Highborne Relic Fragments. Bring them to Aurora Skycaller in Eastern Plaguelands.|  |M|48.84 17.56|
C Threat of the Winterfall  |QO|1| |QID|5082| |N|Donova Snowden in Winterspring wants you to kill 8 Winterfall Pathfinders, 8 Winterfall Den Watchers, and 8 Winterfall Totemics.|  |M|31.27 45.16|
C Moontouched Wildkin  |NORAF|  | |QO|1| |QID|978| |N|Collect 10 Moontouched Feathers from Winterspring, then return to Erelas Ambersky in Rut'theran Village.|  |M|55.50 92.05|
A Winterfall Firewater  |U|12771| |QID|5083| |N|Accept Winterfall Firewater|  |M|31.27 45.16|
T Strange Sources  |M|41.82,88.56| |QID|4842| |N|Return to Donova Snowden in Winterspring.|
T Threat of the Winterfall  |M|41.82,88.56| |QID|5082| |N|Return to Donova Snowden in Winterspring.|
T Winterfall Firewater  |M|41.82,88.56| |QID|5083| |N|\n|
A Falling to Corruption  |M|41.82,88.56| |QID|5084| |N|Accept Falling to Corruption|
T Winterfall Activity  |M|13.09,85.56| |QID|8464| |N|Return to Salfa in Winterspring.|

R Felwood |N|Report back to Donova Snowden with your findings.| |QID|5085|  |M|31.27 45.16|
T Falling to Corruption  |Z|Felwood| |M|50.86,89.4| |QID|5084| |N|\n|
A Mystery Goo  |M|50.86,89.4| |QID|5085| |N|Accept Mystery Goo|
T Mystery Goo  |M|41.82,88.56| |QID|5085| |N|\n|

F Rut'theran Village |N|Speak with Rabine Saturna in the village of Nighthaven, Moonglade.||QID|6762|  |M|51.69 45.10|
T Moontouched Wildkin  |M|84.01,11.73| |QID|978| |N|Return to Erelas Ambersky at Rut'theran Village in Teldrassil.|

A The New Frontier (Part 1)  |M|3.62,45.63| |QID|1047| |N|Accept The New Frontier|
T The New Frontier (Part 1)  |M|19.35,39.31| |QID|1047| |N|\n|
A The New Frontier (Part 2)  |M|19.35,39.31| |QID|6761| |N|Accept The New Frontier|
T The New Frontier (Part 2)  |M|19.53,39.58| |QID|6761| |N|\n|
A Rabine Saturna  |M|19.53,39.58| |QID|6762| |N|Accept Rabine Saturna|

F Moonglade |N|Speak with Layo Starstrike near the Valor's Rest graveyard of Silithus, showing him Rabine's Letter.||QID|1124|  |M|81.87 18.93|
T Rabine Saturna  |Z|Moonglade| |M|5.11,79.09| |QID|6762| |N|\n|
A Wasteland  |M|5.11,79.09| |QID|1124| |N|Accept Wasteland|
]]

end)

