GuideReaderLite_RegisterGuide("Swamp of Sorrows (48-49)", "Tanaris (49-50)", "Horde", function()
return [[
F Stonard |N|Swamp of Sorrows| |NORAF|
A Accept Fall |N|Go to Fallen Hero of the Horde and accept Fall|    |QID|2784| |NODEBUG| |NORAF|  |M|34.3,66.1|
T Fall From Grace |N|Listen to the Fallen Hero of the Horde tell his story.|    |QID|2784| |NODEBUG| |NORAF|  |M|34.3,66.1|
A Accept The Disgraced One |N|Go to Fallen Hero of the Horde and accept The Disgraced One|    |QID|2621| |NORAF|  |M|34.3,66.1|
T Cortello's Riddle (Part 1)  |N|Solve the riddle!.|    |QID|624| |NORAF| 
A Accept Cortello's Riddle (Part 2) |N|Go to A Soggy Scroll and accept Cortello's Riddle (Part 2)|    |QID|625| |NORAF| 

T The Disgraced One  |N|Speak to Dispatch Commander Ruag at Stonard in Swamp of Sorrows.|    |QID|2621| |NORAF|  |M|47.9,55|
A Accept The Missing Orders |N|Go to Dispatch Commander Ruag and accept The Missing Orders|    |QID|2622| |NORAF|  |M|47.9,55|
T The Missing Orders  |N|Speak to Bengor at Stonard in Swamp of Sorrows.|    |QID|2622| |NORAF|  |M|45,57.2|
A Accept The Swamp Talker |N|Go to Bengor and accept The Swamp Talker|    |QID|2623| |NORAF|  |M|45,57.2|

C The Swamp Talker  |QID|2623| |NORAF| |N|Retrieve the Warchief's Orders and return them to the Fallen Hero of the Horde.|  |M|34.29 66.14|
K Jarquia |N|At around (94,50) or (92,65)| |NORAF|

T The Swamp Talker  |N|Retrieve the Warchief's Orders and return them to the Fallen Hero of the Horde.|    |QID|2623| |NORAF|  |M|34.3,66.1|
A Accept A Tale of Sorrow |N|Go to Fallen Hero of the Horde and accept A Tale of Sorrow|    |QID|2801| |NORAF|  |M|34.3,66.1|
T A Tale of Sorrow  |N|Listen to the Fallen Hero of the Horde tell his story.|    |QID|2801| |NORAF|  |M|34.3,66.1|

H The Salty Sailor Tavern  |NORAF| |N|Hearth back|
F Brackenwall Village |N|Boat to Ratchet and fly down| |NORAF|
A Accept The Brood of Onyxia |N|Go to Draz'Zilb and accept The Brood of Onyxia|    |T| |QID|1172| |NORAF|  |M|37.1,33|

N Get Overdue Package |N|From the zeppelin crash (54,55) for "Ledger from Tanaris"| |Z|Dustwallow Marsh| |ITEM|11724| |NORAF|
C The Brood of Onyxia  |Z|Dustwallow Marsh| |QID|1172| |NORAF| |N|Draz'Zilb in Brackenwall Village wants you to destroy 5 Eggs of Onyxia.|  |M|37.15 33.09|
T Cortello's Riddle (Part 2)  |N|Solve the riddle!.|    |Z|Dustwallow Marsh| |QID|625| |NORAF| 
A Accept Cortello's Riddle (Part 3) |N|Go to Musty Scroll and accept Cortello's Riddle (Part 3)|    |QID|626| |NORAF| 

T The Brood of Onyxia  |N|Draz'Zilb in Brackenwall Village wants you to destroy 5 Eggs of Onyxia.|    |T| |QID|1172| |NORAF|  |M|37.1,33|
A Accept Challenge Overlord Mok'Morokk |N|Go to Overlord Mok'Morokk and accept Challenge Overlord Mok'Morokk|    |T| |QID|1173| |NORAF|  |M|36.3,31.4|
C Challenge Overlord Mok'Morokk  |T| |QID|1173| |NORAF| |N|Defeat Mok'Morokk and report the news to Draz'Zilb in Brackenwall Village.|  |M|37.15 33.09|
T Challenge Overlord Mok'Morokk |N|Defeat Mok'Morokk and report the news to Draz'Zilb in Brackenwall Village.|    |T| |QID|1173| |NORAF|  |M|37.1,33|
]]
end)
