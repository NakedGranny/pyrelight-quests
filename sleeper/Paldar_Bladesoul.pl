#############
#Quest Name: Help the Bladesouls: Paldar
#Author: AndMetal
#NPCs Involved: Paldar Bladesoul, Paldar the Insane
#Zone: Sleeper's Tomb
#Items Involved: Spiritual Prismatic Pack, Bladesoul's Spiritual Pouch
#############

sub EVENT_SAY {
	if ($text=~/Hail/i) {quest::emote("jolts his head in the direction of the voice. 'You. . . you're not an apparition are you? No, you can't be, that's what I am. Well, I'm glad to meet you, my name is Paldar Bladesoul. I don't suppose you've seen [Ulessa] since you've entered this tomb, have you?'");}
	if ($text=~/Ulessa/i) {quest::emote("looks away in disgust, whether for himself or for this Ulessa person, you don't know. 'Ulessa was my beloved wife. It seems so long since we were together, but life without essence is an eternity. She was the most beautiful woman I'd ever seen, and she entranced me beyond all thought. We came to this ominous tomb in search of our good friend [Milas], but we weren't aware of truly how dangerous this place was until we got here.'");}
	if ($text=~/Milas/i) {quest::say("Milas An`Rev, one of the most ambitious gnomes I've ever met, not to mention one of the friendliest. Ulessa and I first met him shortly after we were wed in the small cauldron named after Dagnor, and from there embarked on a long series of 'explorative missions', as he put it. He had a way of always getting us into [trouble], but nothing we couldn't handle. Even after years of adventuring, even after we thought we'd seen everything there was to see, he would find something new to explore. He was quite an amazing little gnome.");}
	if ($text=~/trouble/i) {quest::say("You name it. Milas was always intrigued by new and exciting, often very dangerous things and he would always ask us if we wanted to come along. Being the intrepid explorers that we were, and that we were best friends with Milas, we couldn't say no. So we went along with him everywhere he went, and let me tell you, he had a keen eye for locale. We'd explore the lands of Antonica, then move on to something hidden and mysterious in the ancient ruins on Kunark. We spent more time on the road looking for that next piece of the puzzle, or trying to find that next smallest creature that we called the road home, and Milas our family. That is, until he asked us to explore the ancient mystery of the [sleeping dragon].");}
	if ($text=~/sleeping dragon/i) {quest::say("That's the same thing I asked Milas so long ago when he told us about this extraordinary creature. 'Paldar me ol' friend, Ulessa ya beaut', listen to what I 'ave found' he said to us. We had no idea of the immensity of this mighty creature until he had described, in detail, what the myths and tales had to say about this beast. We listened intently as he went on and on about this powerful sleeping dragon and how it had been put there by a great many dragons long ago. We both knew that [he was planning] something around this dragon, but we didn't know what it was exactly at the time.");}
	if ($text=~/planning/i) {quest::say("After he finished his fabulous tale, he explained to us that he was going to search the planet for the fabled prismatic beast, and that he wanted us to come along with him. We were stunned when he finished, and even more so that he asked us to come with him to find this monstrosity. Both Ulessa and I tried to talk Milas out of it. We pleaded with him not to go, and told him it was a [foolish endeavor], but he wouldn't listen.");}
	if ($text=~/foolish endeavor/i) {quest::say("Talk of a dragon almost as powerful as the creator herself?! A dragon that reigned supreme over all other dragons as they looked on and cowered in fear? Such beasts were unimaginably powerful and a group of three tireless adventurers would have no way to take on such a monster. We were honestly frightened by the story and we feared for anyone who tried to embark on a journey to find such a beast. But as I said, Milas paid no heed to our warnings and went off on his own anyway. We really had no idea what to think at that point, but we knew that we [had to do] something, before Milas got himself killed.");}
	if ($text=~/to do/i) {quest::say("He was our friend, though now we started to wonder if perhaps he had gotten too far into these explorative missions for his own good. Because he was our friend, we had to go after him to make sure he didn't do something he shouldn't. We followed his trail all over Norrath before finally finding out that he had made it to the [ancient tomb]. We found out where the tomb was and raced there to try and catch up to him.");}
	if ($text=~/ancient tomb/i) {quest::say("The walls shined dimly with a glacial velium bile the likes of which we had never seen before, not to mention the fact that they stood hundreds of feet high. I'm sure you felt the same way the first time you came here. The awe inspiring architecture clouded our minds for a brief moment while we took it all in. Truly, we thought, Milas had stumbled onto something magnificent, albeit terrifying. We proceeded through the tomb carefully, avoiding the various golems and gargoyles that we encountered, all the while trying to locate any sign of Milas. We came to the door directly across from this room and my first thought was, ''What's in here?'' Without a moment's thought, we moved forth towards the [door] to open it.");}
	if ($text=~/door/i) {quest::say("The door was gigantic and spanned the entire reach of the hall, from floor to ceiling. It took a great force to muster it open, and what we saw when we opened the door terrified us both. Beyond the door lay a humongous golem, over three times the size of the normal golems. We tried to close the door before it noticed us, but it was too late. It charged for us, the smaller golems following behind. I tried to fend off the huge golem to try and let my beloved wife escape. Unfortunately for me, I couldn't see whether or not she was able to escape, and for all I know, she could have died right then and there. As for me, I was quickly done in by the mighty progenitor, and have spent the last. . . eternity here [waiting for] Ulessa.");}
	if ($text=~/waiting for/i) {quest::say("I'm fairly certain that my beloved wife perished in this condemned tomb shortly after me, and while that makes me sad, I still have nothing but love for her and wish to find her. I've had plenty of time over the years to come up with a way to try and escape this prison I'm in so that I might be able to find her, but unfortunately the bond between my soul and this statue are far too strong to allow me to go anywhere. I've been waiting for quite some time for someone to come to aid me in my struggles, but I don't know anyone who will help.");}
	if ($text=~/will help/i) {
		quest::say("You will? That's fantastic, this might just work. I've concocted a way to put my spirit into a mortal body, at least long enough to search the tomb for any sign of Ulessa. I've come up with the perfect way to do this, and here's what it's going to take. I'm going to need you to bring me the lifeblood of several of the creatures in the tomb. I don't wish to upset the creatures or their spirits in this tomb, so all I'll say is that the more powerful beasts will be the ones that will have what I need. Gather the ten components for me and bring them back to me, I'll be able to use them to form the creature that I can join my spirit with.");
		quest::summonitem(17147);	# Spiritual Prismatic Pack
	}
}

sub EVENT_ITEM {
	if (plugin::check_handin(\%itemcount, 20410 => 1)) {	# Bladesoul's Spiritual Pouch
		quest::say("Paldar Bladesoul melds the components inside the pouch to form a spiritual concoction. He then ingests the mixture and changes shape into a menacing drake. Unawares of the difficulties of spiritual transference to corporeal form, the beast goes insane and begins attacking you!");
		quest::depop_withtimer();
		quest::spawn2(128140,0,0,$x,$y,$z,$h);
	}

	plugin::return_items(%itemcount);
}
