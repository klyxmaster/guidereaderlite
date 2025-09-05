GuideReaderLite_RegisterGuide("Elwynn Forest (1-12)", "Darkshore (12-17)", "Alliance", function()
return [[
A Accept Accept A Threat Within |N|Go to Deputy Willem and accept Accept A Threat Within|    |QID|783|  |M|48.06,43.44| 
T A Threat Within     |N|Speak with Marshal McBride.|    |QID|783|  |M|48.8,41.6| 
A Accept Accept Kobold Camp Cleanup |N|Go to Marshal McBride and accept Accept Kobold Camp Cleanup|    |QID|7|  |M|48.8,41.6| 
A Accept Accept Eagan Peltskinner |N|Go to Deputy Willem and accept Accept Eagan Peltskinner|    |QID|5261|  |M|48.06,43.44| 
T Eagan Peltskinner     |N|Speak with Eagan Peltskinner.|    |QID|5261|  |M|48.8,40.2| 
A Accept Accept Wolves Across the Border |N|Go to Eagan Peltskinner and accept Accept Wolves Across the Border|    |QID|33|  |M|48.8,40.2| 

C Wolves and Kobolds |QID|7,33| |N|Kill 8 Kobold Vermin and Kill diseased wolves for 8 pelts.| |QO|1,1|  |M|49,36|

T Wolves Across the Border     |N|Bring 8 Diseased Wolf Pelts to Eagan Peltskinner outside Northshire Abbey.|    |QID|33|  |M|48.8,40.2| 
T Kobold Camp Cleanup     |N|Kill 8 Kobold Vermin, then return to Marshal McBride.|    |QID|7|  |M|48.8,41.6| 

A Accept Accept Consecrated Letter |N|Go to Marshal McBride and accept Accept Consecrated Letter|    |QID|3101|  |C|Paladin| |R|Human|  |M|48.8,41.6| 
A Accept Accept Glyphic Letter |N|Go to Marshal McBride and accept Accept Glyphic Letter|    |QID|3104|  |C|Mage| |R|Human|  |M|48.8,41.6| 
A Accept Accept Encrypted Letter |N|Go to Marshal McBride and accept Accept Encrypted Letter|    |QID|3102|  |C|Rogue| |R|Human|  |M|48.8,41.6| 
A Accept Accept Simple Letter |N|Go to Marshal McBride and accept Accept Simple Letter|    |QID|3100|  |C|Warrior| |R|Human| |M|48.8,41.6| 
A Accept Accept Hallowed Letter |N|Go to Marshal McBride and accept Accept Hallowed Letter|    |QID|3103|  |C|Priest| |R|Human|  |M|48.8,41.6| 
A Accept Accept Tainted Letter |N|Go to Marshal McBride and accept Accept Tainted Letter|    |QID|3105|  |C|Warlock| |R|Human| |M|48.8,41.6| 

A Accept Accept Investigate Echo Ridge |N|Go to Marshal McBride and accept Accept Investigate Echo Ridge|    |QID|15|  |M|48.8,41.6| 
A Accept Accept Brotherhood of Thieves |N|Go to Deputy Willem and accept Accept Brotherhood of Thieves|    |QID|18|  	|M|48.06,43.44| 

T Consecrated Letter     |N|Read the Consecrated Letter and speak to Brother Sammuel in Northshire Abbey.|    |QID|3101|  |C|Paladin| |R|Human|   |M|50.43 42.12|
T Glyphic Letter     |N|Read the Glyphic Letter and speak to Khelden Bremen inside Northshire Abbey.|    |QID|3104|  |C|Mage| |R|Human|   |M|49.66 39.40|
T Encrypted Letter     |N|Read the Encrypted Letter and speak to Jorik Kerridan in the stable behind Northshire Abbey.|    |QID|3102|  |C|Rogue| |R|Human|   |M|50.31 39.92|
T Simple Letter     |N|Read the Simple Letter and speak to Llane Beshere in Northshire Abbey.|    |QID|3100|  |C|Warrior| |R|Human|   |M|50.24 42.29|
T Hallowed Letter     |N|Read the Hallowed Letter and speak to Priestess Anetta in Northshire Abbey.|    |QID|3103|  |C|Priest| |R|Human|   |M|49.81 39.49|
T Tainted Letter     |N|Read the Tainted Letter and speak to Drusilla La Salle next to Northshire Abbey.|    |QID|3105|  |C|Warlock| |R|Human|   |M|49.87 42.65|
A The Stolen Tome     |N|Retrieve the Powers of the Void for Drusilla La Salle.|    |QID|1598|  |C|Warlock| |R|Human|   |M|49.87 42.65|

C Investigate Echo Ridge |QID|15|   |M|48.8,35| |N|Kill 8 Kobold Workers.|
C The Stolen Tome |QID|1598|   |C|Warlock| |R|Human| |N|Retrieve the Powers of the Void for Drusilla La Salle.|  |M|56.7 44.0|
C Brotherhood of Thieves |QID|18| 	|M|53,45| |N|Kill thieves and get 8 Red Burlap Bandanas from them|

T Brotherhood of Thieves     |N|Bring 8 Red Burlap Bandanas to Deputy Willem outside the Northshire Abbey.|    |QID|18| 	|M|48.06,43.44| 
A Accept Accept Milly Osworth |N|Go to Deputy Willem and accept Accept Milly Osworth|    |QID|3903|   |M|48.17 42.94|
A Accept Accept Bounty on Garrick Padfoot |N|Go to Deputy Willem and accept Accept Bounty on Garrick Padfoot|    |QID|6| 	|M|48.06,43.44| 
T Investigate Echo Ridge     |N|Kill 8 Kobold Workers, then report back to Marshal McBride.|    |QID|15|   |M|48.8,41.6| 
A Accept Accept Skirmish at Echo Ridge |N|Go to Marshal McBride and accept Accept Skirmish at Echo Ridge|    |QID|21|   |M|48.8,41.6| 
T Milly Osworth     |N|Speak with Milly Osworth.|    |QID|3903| 	|M|50.8, 39.6| 
A Accept Accept Milly's Harvest |N|Go to Milly Osworth and accept Accept Milly's Harvest|    |QID|3904|  	|M|50.8, 39.6| 

C Skirmish at Echo Ridge |QID|21|   |M|48.2 30.2| |N|Return to Echo Ridge and enter to Kill 8 Kobold Laborers.|
G Milly's Harvest |QID|3904| |N|Gather 8 crates of Milly's Harvest - By the thieves|  |M|55,49|  |QO|1|
G Bounty on Garrick Padfoot |QID|6| |N|Kill Garrick Padfoot and loot his head.|  |M|57.4 48.6|  |QO|1|

T Milly's Harvest     |N|Bring 8 crates of Milly's Harvest to Milly Osworth at Northshire Abbey.|    |QID|3904|  |M|50.8, 39.6| 
A Accept Accept Grape Manifest |N|Go to Milly Osworth and accept Accept Grape Manifest|    |QID|3905| 	|M|50.8, 39.6| 
T Skirmish at Echo Ridge     |N|Kill 8 Kobold Laborers, then return to Marshal McBride at Northshire Abbey.|    |QID|21|   |M|48.8,41.6| 
A Accept Accept Report to Goldshire |N|Go to Marshal McBride and accept Accept Report to Goldshire|    |QID|54|  	|M|48.8,41.6| 
T Bounty on Garrick Padfoot     |N|Kill Garrick Padfoot and bring his head to Deputy Willem at Northshire Abbey.|    |QID|6| 	|M|48.06,43.44| 

T Grape Manifest     |N|Bring the Grape Manifest to Brother Neals in Northshire Abbey.|    |QID|3905| 	|M|49.4 41.4| 
A Accept Accept Rest and Relaxation |N|Go to Falkhaan Isenstrider and accept Accept Rest and Relaxation|    |QID|2158| 	|M|45.6 47.8| 

|Z| Elwynn Forest|
R Run to Goldshire |N|Stay on the road to avoid mobs. Click NEXT when you arrive.|  |M|42.2 65.8|
T Report to Goldshire     |N|Take Marshal McBride's Documents to Marshal Dughan in Goldshire.|    |QID|54| 	|M|42.2 65.8| 
A Accept Accept The Fargodeep Mine |N|Go to Marshal Dughan and accept Accept The Fargodeep Mine|    |QID|62| 	|M|42.2 65.8| 
A Accept Accept Gold Dust Exchange |N|Go to Remy "Two Times and accept Accept Gold Dust Exchange|    |QID|47| 	|M|42.2 67.2| 
T Rest and Relaxation     |N|Speak with Innkeeper Farley at the Lion's Pride Inn.|    |QID|2158| 	|M|43.8 65.8| 
h Goldshire  |M|43.8,65.8| |N|Make this Inn your home|
A Accept Accept Kobold Candles |N|Go to William Pestle and accept Accept Kobold Candles|    |QID|60| 	|M|43.2 65.8| 
T In Favor of the Light        |N|Speak to Priestess Josetta in Elwynn Forest.|    |C|Priest| |QID|5623| |R|Human|  |M|43.4 65.6| 
A Accept Accept Garments of the Light |N|Go to Maxan Anvol and accept Accept Garments of the Light|    |C|Priest| |QID|5625| |R|Human|	|M|43.4 65.6| 
G Garments of the Light 	 |C|Priest| |QID|5624| |R|Human| |M|48.0 67.6| |N|Find Guard Roberts and heal his wounds using Lesser Heal (Rank 2). Afterwards, grant him Power Word: Fortitude and then return to Priestess Josetta in Goldshire.|
T Garments of the Light  	    |N|Find Mountaineer Dolf and heal his wounds using Lesser Heal (Rank 2).|    |C|Priest| |QID|5625| |R|Human| |M|43.4 65.6| 

A Accept Accept Lost Necklace |N|Go to Auntie" Bernice Stonefield and accept Accept Lost Necklace|    |QID|85| 	|M|34.6 84.2| 
T Lost Necklace     |N|Speak with Billy Maclure.|    |QID|85| 	|M|43.0 85.8| 
A Accept Accept Pie for Billy |N|Go to Billy Maclure and accept Accept Pie for Billy|    |QID|86| 	|M|34.6 84.2| 
A Accept Accept Young Lovers |N|Go to Maybell Maclure and accept Accept Young Lovers|    |QID|106|  	|M|43.0 89.6| 
C Pie for Billy |QID|86| 	|M|41.8 86.6| |N|Bring 4 Chunks of Boar Meat to Auntie Bernice Stonefield at the Stonefield's Farm.|
T Pie for Billy     |N|Bring 4 Chunks of Boar Meat to Auntie Bernice Stonefield at the Stonefield's Farm.|    |QID|86| 	 	|M|34.6 84.2| 
A Accept Accept Back to Billy |N|Go to Auntie" Bernice Stonefield and accept Accept Back to Billy|    |QID|84| 	 	|M|34.6 84.2| 
A Accept Accept Princess Must Die! |N|Go to Ma Stonefield and accept Accept Princess Must Die!|    |QID|88| |M|34.6 84.6| 
T Young Lovers     |N|Give Maybell's Love Letter to Tommy Joe Stonefield.|    |QID|106| 	|M|29.8 86.0| 
A Accept Accept Speak with Gramma |N|Go to Tommy Joe Stonefield and accept Accept Speak with Gramma|    |QID|111|  	|M|29.8 86.0| 
T Speak with Gramma     |N|Speak with Gramma Stonefield.|    |QID|111| 		|M|34.8 83.8| 
A Accept Accept Note to William |N|Go to Gramma Stonefield and accept Accept Note to William|    |QID|107| 	|M|34.8 83.8| 

T Back to Billy     |N|Bring the Pork Belly Pie to Billy Maclure at the Maclure Vineyards.|    |QID|84|  	|M|43.0 85.8| 
A Accept Accept Goldtooth |N|Go to Billy Maclure and accept Accept Goldtooth|    |QID|87|  	|M|43.0 85.8| 

C Adventure in the Mine |QID|47,87,60,62| 	|M|40.4 78.2|  |N| Kill Goldtooth for Necklace\n- Kill Kobolds for 10 Gold Dust and 8 Large Candles\nExplore the mine while you are here| |QO|1,1,1,1|


H Goldshire |N|Hearth back|
T Note to William     |N|Take Gramma Stonefield's Note to William Pestle.|    |QID|107|   |M|43.32 65.70|
T Kobold Candles     |N|Bring 8 Large Candles to William Pestle in Goldshire.|    |QID|60|   |M|43.32 65.70|
A Accept Accept Collecting Kelp |N|Go to William Pestle and accept Accept Collecting Kelp|    |QID|112|   |M|43.32 65.70|
T Gold Dust Exchange     |N|Bring 10 Gold Dust to Remy "Two Times" in Goldshire.|    |QID|47|   |M|42.14 67.26|
A Accept Accept A Fishy Peril |N|Go to Remy "Two Times and accept Accept A Fishy Peril|    |QID|40|   |M|42.14 67.26|
T A Fishy Peril     |N|Remy "Two Times" wants you to speak with Marshal Dughan in Goldshire.|    |QID|40|   |M|42.11 65.93|
A Accept Accept Further Concerns |N|Go to Marshal Dughan and accept Accept Further Concerns|    |QID|35|   |M|42.11 65.93|
T The Fargodeep Mine     |N|Explore the Fargodeep Mine, then return to Marshal Dughan in Goldshire.|    |QID|62|   |M|42.11 65.93|
A Accept Accept The Jasperlode Mine |N|Go to Marshal Dughan and accept Accept The Jasperlode Mine|    |QID|76|   |M|42.11 65.93|

A Accept Accept Shipment to Stormwind |N|Go to William Pestle and accept Accept Shipment to Stormwind|    |QID|61|   |M|43.32 65.70|

C Collecting Kelp |QID|112| |N|Bring 4 Crystal Kelp Fronds from the murlocs in the lade east of Goldshire.|  |M|52.4 65.0|
C The Jasperlode Mine |QID|76| |N|Explore the Jasperlode Mine, then report back to Marshal Dughan in Goldshire.|  |M| 62,53|


T Further Concerns     |N|Marshal Dughan wants you to speak with Guard Thomas.|    |QID|35|   |M|74.0 72.2|
A Accept Accept Find the Lost Guards |N|Go to Guard Thomas and accept Accept Find the Lost Guards|    |QID|37|   |M|74.0 72.2|
A Accept Accept Protect the Frontier |N|Go to Guard Thomas and accept Accept Protect the Frontier|    |QID|52|   |M|74.0 72.2|

A Accept Accept Red Linen Goods |N|Go to Sara Timberlain and accept Accept Red Linen Goods|    |QID|83|   |M|79.6 68.6|
A Accept Accept A Bundle of Trouble |N|Go to Supervisor Raelen and accept Accept A Bundle of Trouble|    |QID|5545|   |M|81.4 66.0|

T Find the Lost Guard   |N|Guard Thomas wants you to travel north up the river and search for the two lost guards, Rolf and Malakai.|    |QID|37| 	   |M|72,60| |QO|1|
A Accept Accept Discover Rolf's Fate |N|Go to A half-eaten body and accept Accept Discover Rolf's Fate|    |QID|45|  	 |M|72,60| |QO|1|
T Discover Rolf's Fate 	|N|Search the murloc village for Rolf, or signs of his death.|    |QID|45|	  |M|79.8, 55.6|
A Accept Accept Report to Thomas |N|Go to Rolf's corpse and accept Accept Report to Thomas|    |QID|71|		 |M|79.8, 55.6|

C A Bundle of Trouble 	|QID|5545,52|	|N|North of the campe kill 8 prowlers, 5 young forest bears and collect wood|   |QO|1,1,1|  |82,60|

T A Bundle of Trouble 	|N|Bring 8 Bundles of Wood to Raelen at the Eastvale Logging Camp.|    |QID|5545|	  |M|81.4 66.0|
T Report to Thomas  	|N|Deliver Rolf and Malakai's Medallions to Guard Thomas at the eastern Elwynn bridge.|    |QID|71| 		 |M|74.0 72.2|
A Accept Accept Deliver Thomas' Report |N|Go to Guard Thomas and accept Accept Deliver Thomas' Report|    |QID|39|		|M|74.0 72.2|
T Protect the Frontier |N|Kill 8 Prowlers and 5 Young Forest Bears, and then return to Guard Thomas at the east Elwynn bridge.|    |QID|52|			|M|74.0 72.2|

C Princess and Linen Goods |QID|88,83|	|N|KIll the princess for the neckless At the Brackwell Pumpkin Patch. Kill bandits for their "Red Bandanas"\n\nTIP: Princess can't jump the fense, kite her back and forth to kll her|	|QO|1,1,|	|M|70.6 79.0|
T Red Linen Goods |N|Bring 6 Red Linen Bandanas to Sara Timberlain at the Eastvale Logging Camp.|    |QID|83| 	|M|79.6 68.6|

H Goldshire |N|Hearth to Lion's Pride Inn|
A Accept Accept Speak with Jennea |N|Go to Zaldimar Wefhellt and accept Accept Speak with Jennea|    |C|Mage| |QID|1860| |R|Human| 
A Accept Accept Seek out SI: 7 |N|Go to Keryn Sylvius and accept Accept Seek out SI: 7|    |C|Rogue| |QID|2205| |R|Human| 
A Accept Accept Gakin's Summons |N|Go to Lago Blackwrench and accept Accept Gakin's Summons|    |C|Warlock| |QID|1717| |R|Human| 

T Collecting Kelp |N|Bring 4 Crystal Kelp Fronds to William Pestle in Goldshire.|    |QID|112|   |M|43.2 65.8|
A Accept Accept The Escape |N|Go to William Pestle and accept Accept The Escape|    |QID|114| 	 |M|43.2 65.8|
T Deliver Thomas' Report |N|Report to Marshal Dughan in Goldshire.|    |QID|39| 	|M|42.2 65.8|
T The Jasperlode Mine |N|Explore the Jasperlode Mine, then report back to Marshal Dughan in Goldshire.|    |QID|76| 	|M|42.2 65.8|
A Accept Accept Westbrook Garrison Needs Help! |N|Go to Marshal Dughan and accept Accept Westbrook Garrison Needs Help!|    |QID|239| 	|M|42.2 65.8|
A Accept Accept Elmore's Task |N|Go to Smith Argus and accept Accept Elmore's Task|    |QID|1097| 	|M|41.6 65.6|

A Accept Accept A Warrior's Training |N|Go to Ilsa Corbin and accept Accept A Warrior's Training|    |C|Warrior| |QID|1638| |R|Human| 

T The Escape |N|Take the Invisibility Liquor to Maybell Maclure.|    |QID|114| 	|M|43.0 89.6|
T Goldtooth |N|Bring Bernice's Necklace to "Auntie" Bernice Stonefield at the Stonefield Farm.|    |QID|87| 		|M|34.6 84.2|
T Princess Must Die! |N|Kill Princess, grab her collar, then bring it back to Ma Stonefield at the Stonefield Farm.|    |QID|88| 	|M|34.6 84.6|

T Westbrook Garrison Needs Help! |N|Go to the Westbrook Garrison and speak with Deputy Rainer.|    |QID|239| 	|M|24.2 74.6|
A Accept Accept Riverpaw Gnoll Bounty |N|Go to Deputy Rainer and accept Accept Riverpaw Gnoll Bounty|    |QID|11|  |M|24.2,74.5| |Z|Elwynn Forest|
C Riverpaw Gnoll Bounty |QID|11| |N|Kill Riverpaw Gnolls and collect 8 Gnoll Armbands.| |M|26.0,86.0| |Z|Elwynn Forest|
T Riverpaw Gnoll Bounty |N|Bring 8 Painted Gnoll Armbands to Deputy Rainer at the Barracks.|    |QID|11|  |M|24.2,74.5| |Z|Elwynn Forest|

R Westfall |N|Run west to Westfall.| |M|19.9,77.1| |Z|Elwynn Forest|
A Furlbrow's Deed |N|Bring Furlbrow's Deed to Farmer Furlbrow.|    |U|1972|  |QID|184|  |M|59.9,19.4| |Z|Westfall|
T Furlbrow's Deed |N|Bring Furlbrow's Deed to Farmer Furlbrow.|     |QID|184|  |M|59.9,19.4| |Z|Westfall|
A Accept Accept Report to Gryan Stoutmantle |N|Go to Deputy Rainer and accept Accept Report to Gryan Stoutmantle|    |QID|109|  |M|59.9,19.4| |Z|Westfall|
A Accept Accept Westfall Stew |N|Go to Salma Saldean and accept Accept Westfall Stew|    |QID|38|  |M|56.4,30.5| |Z|Westfall|
T Westfall Stew |N|Salma Saldean wants 3 Stringy Vulture Meat, 3 Goretusk Snouts, 3 Murloc Eyes, 3 Okra.|    |QID|38|  |M|56.4 30.6| |Z|Westfall|
T Report to Gryan Stoutmantle |N|Talk to Gryan Stoutmantle.|    |QID|109|  |M|56.3,47.6| |Z|Westfall|
A Accept Accept A Swift Message |N|Go to Quartermaster Lewis and accept Accept A Swift Message|    |QID|6181| |R|Human|  |M|56.3,47.6| |Z|Westfall|
T A Swift Message |N|Bring Lewis' Note to Thor the gryphon master.|    |QID|6181| |R|Human|  |M|56.4,52.6|
A Accept Accept Continue to Stormwind |N|Go to Thor and accept Accept Continue to Stormwind|    |QID|6281| |R|Human|  |M|56.6 52.6| |Z|Stormwind City|

F Stormwind City |N|Fly to Stormwind.| |M|56.6,52.6| |Z|Westfall|
T Shipment to Stormwind |N|Bring William's Shipment to Morgan Pestle in the Stormwind Trade District.|    |QID|61|  |M|63.2 74.6| |Z|Stormwind City|
A Accept Accept Wine Shop Advert |N|Go to Renato Gallina and accept Accept Wine Shop Advert|    |QID|332|  |M|63.8 73.6| |Z|Stormwind City|
A Accept Accept Harlan Needs a Resupply |N|Go to Harlan Bagley and accept Accept Harlan Needs a Resupply|    |QID|333|  |M|62.6 68.6| |Z|Stormwind City|
h Stormwind City |N|Set your hearthstone in Stormwind City at the inn.| |M|60.6 75.0| |Z|Stormwind City|
T Wine Shop Advert |N|Go to the Gallina Winery, and bring Suzetta Gallina the Wine Ticket for a free bottle of wine.|    |QID|332|  |M|60.4 76.0| |Z|Stormwind City|
T Harlan Needs a Resupply |N|Go to the Canal Tailor Shop and bring Rema Schneider the Cloth Request from Harlan Bagley.|    |QID|333|  |M|49.6,55.6| |Z|Stormwind City|
A Accept Accept Package for Thurman |N|Go to Rema Schneider and accept Accept Package for Thurman|    |QID|334|  |M|49.6,55.6| |Z|Stormwind City|
T Package for Thurman |N|Go to the Larson Clothiers in the Stormwind Mage Quarter, and give Thurman Schneider his Sewing Kit.|    |QID|334|  |M|42.5,76.2| |Z|Stormwind City|

T Speak with Jennea |N|Speak with Jennea Cannon in Stormwind.|    |C|Mage| |QID|1860| |R|Human|  |M|39.6,79.6| |Z|Stormwind City|
A Accept Accept Mirror Lake |N|Go to Jennea Cannon and accept Accept Mirror Lake|    |C|Mage| |QID|1861| |R|Human|  |M|39.6,79.6| |Z|Stormwind City|

T Gakin's Summons |N|Report to Gakin the Darkbinder in the Mage Quarter of Stormwind.|    |C|Warlock| |QID|1717| |R|Human|  |M|39.2,84.0| |Z|Stormwind City|
A Accept Accept Surena Caledon |N|Go to Gakin the Darkbinder and accept Accept Surena Caledon|    |C|Warlock| |QID|1688| |R|Human|  |M|39.2,84.0| |Z|Stormwind City|

T Continue to Stormwind |N|Buy a gryphon ride from the gryphon master Thor, then bring Lewis' Note to Osric Strang, in the shop Limited Immunity, in the Old Town of Stormwind.|    |QID|6281| |R|Human|  |M|74.2,47.4| |Z|Stormwind City|
A Accept Accept Dungar Longdrink |N|Go to Osric Strang and accept Accept Dungar Longdrink|    |QID|6261| |R|Human|  |M|74.2,47.4| |Z|Stormwind City|

T Seek out SI: 7 |N|Deliver Keryn Sylvius's package to Master Mathias Shaw at the Stormwind Barracks.|    |C|Rogue| |QID|2205| |R|Human|  |M|76.0,59.6| |Z|Stormwind City|
A Accept Accept Snatch and Grab |N|Go to Master Mathias Shaw and accept Accept Snatch and Grab|    |C|Rogue| |QID|2206| |R|Human|  |M|76.0,59.6| |Z|Stormwind City|

T A Warrior's Training |N|Speak with Harry Burlguard in Stormwind.|    |C|Warrior| |QID|1638| |R|Human|  |M|77.2,53.2| |Z|Stormwind City|
A Accept Accept Bartleby the Drunk |N|Go to Harry Burlguard and accept Accept Bartleby the Drunk|    |C|Warrior| |QID|1639| |R|Human|  |M|77.2,53.2| |Z|Stormwind City|
T Bartleby the Drunk |N|Speak with Bartleby.|    |C|Warrior| |QID|1639| |R|Human|  |M|76.6,52.6| |Z|Stormwind City|
A Accept Accept Beat Bartleby |N|Go to Bartleby and accept Accept Beat Bartleby|    |C|Warrior| |QID|1640| |R|Human|  |M|76.6,52.6| |Z|Stormwind City|
T Beat Bartleby |N|Beat Bartleby, then talk to him.|    |C|Warrior| |QID|1640| |R|Human|  |M|76.6,52.6| |Z|Stormwind City|
A Accept Accept Bartleby's Mug |N|Go to Bartleby and accept Accept Bartleby's Mug|    |C|Warrior| |QID|1665| |R|Human|  |M|76.6,52.6| |Z|Stormwind City|
T Bartleby's Mug |N|Bring Bartleby's Mug to Burlguard.|    |C|Warrior| |QID|1665| |R|Human|  |M|77.2,53.2| |Z|Stormwind City|
A Accept Accept Marshal Haggard |N|Go to Harry Burlguard and accept Accept Marshal Haggard|    |C|Warrior| |QID|1666| |R|Human|  |M|77.2,53.2| |Z|Stormwind City|

N Kill any bears you find


]]
end)