function event_say(e)
	if(e.message:findi("koada dal falchion")) then
		e.self:Say("Koada`Dal Falchions are highly enchanted weapons crafted of the finest mithril. The blade is forged of folded mithril, quenched in morning dew, and the pommel is then set with an emerald imbued by a cleric of the Mother. If you have an unfinished falchion of the Koada`Vie, bring it to me with such an emerald and two skins of morning dew, and I will finish it for you.");
	end
end
function event_trade(e)
	local item_lib = require("items");
-- Falchion Of The Koada'Vie can be obtained from the quest in Felwithe around level 20, though on P99 it might drop from two specific guards in the Firiona Vie outpost in Kunark, Morning Dew can be Foraged
	if(item_lib.check_turn_in(e.trade, {item1 = 5379,item2 = 16594,item3 = 16594,item4 = 22507})) then --Falchion Of The Koada'Vie, Morning Dew, Morning Dew, Imbued Emerald
		e.self:Say("Here, then, is your blade, newly born of the Mother that it will stand in defense of all this is good and right in the world.");
		e.other:SummonItem(21548); --Koada`Dal Falchion of Tunare is originally created by tradeskill combine, using it now as a placeholder reward for this quest
		e.other:Ding();
		e.other:Faction(226,10,0);  --Clerics of Tunare
		e.other:Faction(279,10,0);  --King Tearis Thex
		e.other:Faction(246,12,0);  --Faydark's Champions
		e.other:AddEXP(3000);
	end
	item_lib.return_items(e.self, e.other, e.trade);
end
-- END of FILE Zone:felwithea  ID:61048 -- Opal_Leganyn
