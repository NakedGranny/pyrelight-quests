use List::Util qw(max);
use List::Util qw(min);
use POSIX;
use JSON;

my $dz_duration     = 604800; # 7 Days


sub EVENT_TICK 
{
    CHECK_CHARM_STATUS();
    if ($npc->IsPet() and $npc->GetOwner()->IsClient()) { 
        UPDATE_PET($npc);        
    }
}

sub EVENT_SPAWN {
    #Pet Scaling
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->Charmed()) {
        SAVE_PET_STATS(); 
        UPDATE_PET();
        $npc->Heal();
    } else {
        # Check for FoS Instance
        if ($instanceversion == 10) {
            my $owner_id   = plugin::GetSharedTaskLeaderByInstance($instanceid);
            plugin::ModifyInstanceNPC();
            plugin::ModifyInstanceLoot($npc);  
        }

        # Do item upgrade variance
        my @lootlist = $npc->GetLootList();
        foreach my $item_id (@lootlist) {
            my $fabled_id = plugin::get_fabled_id($item_id);
            if ($fabled_id && rand() <= 0.001) {
                plugin::upgrade_item_to_fabled($item_id, $npc);
            }

            plugin::upgrade_item_npc($item_id, 1, $npc) if rand() <= 0.10;
            plugin::upgrade_item_npc($item_id, 1, $npc) if rand() <= 0.05;
            plugin::upgrade_item_npc($item_id, 1, $npc) if rand() <= 0.01;            
        }
    }
}

sub EVENT_KILLED_MERIT {
    # Check for FoS Instance
    if ($instanceversion == 10) {
    }  

    #Potions
    if ($client && $client->GetLevelCon($npc->GetLevel()) != 6 && rand() <= 0.20) {
        my $dbh = plugin::LoadMysql();

        my $pot_name = plugin::GetPotName();
        my $potion = "Distillate of " . $pot_name;
        if ($pot_name ne 'Antidote' and $pot_name ne 'Immunization' and $pot_name ne 'Skinspikes') {
            $potion .= plugin::GetRoman($client->GetLevel());
        }

        #quest::debug("Looking for potion: $potion");
        my $query = $dbh->prepare("SELECT id FROM items WHERE name LIKE '$potion';");
        $query->execute();
        my ($potion_id) = $query->fetchrow_array();

        if ($potion_id) {
            $npc->AddItem($potion_id);
        } else {
            #quest::debug("Invalid Potion Query: $query");
        }

        $query->finish();
        $dbh->disconnect();
    } elsif ($client && $client->GetLevelCon($npc->GetLevel()) != 6 && rand() <= 0.01 && !($client->GetBucket("ExpPotionDrop"))) {
        $npc->AddItem(40605); # Exp Pot
        $client->SetBucket("ExpPotionDrop", 1, 24 * 60 * 60);
    }
}

sub EVENT_DAMAGE_GIVEN 
{
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->IsTaunting()) {
        $entity_list->GetMobByID($entity_id)->AddToHateList($npc->GetOwner());
    }        
}

sub EVENT_COMBAT 
{
    my $ID = $npc->GetID();
    CHECK_CHARM_STATUS();
    if ($combat_state == 0 && $npc->GetCleanName() =~ /^The Fabled/) {
        quest::respawn($npc->GetNPCTypeID(), $npc->GetGrid());
    }

    # Pet Stuff
    if ($npc->IsPet() and $npc->GetOwner()->IsClient()) {
        my $owner = $npc->GetOwner()->CastToClient();
        if ($combat_state == 1) {            
                $npc->SetTimer("Pet_Abilities", 18);
        } else {
            $npc->StopTimer("Pet_Abilities");
        }        
    }
}

sub EVENT_TIMER {
    if ($npc->IsPet() && $npc->GetOwner()->IsClient() && $timer eq "Pet_Abilities" && $npc->IsTaunting()) {
        my $owner       = $npc->GetOwner()->CastToClient();
        my $target      = $npc->GetTarget();
        my @close_list  = $entity_list->GetCloseMobList($npc, 100);

        my $mage_epic = "1936";

        $AoE_Spell = "21690"; #Earthen Menance
        if (plugin::is_focus_equipped($owner, $mage_epic)) {            
            for $m (@close_list) {
                if ($m) {
                    my $m_target = $m->GetTarget();
                    if ($m_target->GetID() == $owner->GetID()) {
                        $m->AddToHateList($npc, 1000);
                    }
                }
            }
            $npc->CastSpell($AoE_Spell, $npc->GetID(), 0, 0);
        }
    }   
}

sub EVENT_ITEM
{
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->Charmed()) {
        plugin::YellowText("You must use a Summoner's Syncrosatchel to equip your pet.");
        plugin::return_items_silent(\%itemcount);
    }
}

sub EVENT_DEATH_COMPLETE {
    CHECK_CHARM_STATUS(); 
}

sub EVENT_CAST_ON {
    if (quest::IsCharmSpell($spell_id) && $entity_list->GetClientByID($caster_id)) {
        quest::debug("I WAS CHARMED!");
        $npc->ScaleNPC($entity_list->GetClientByID($caster_id)->GetLevel());
    }
}

sub CHECK_CHARM_STATUS
{
    if ($npc->Charmed() and not plugin::REV($npc, "is_charmed")) {     
        my @lootlist = $npc->GetLootList();
        my @inventory;
        foreach my $item_id (@lootlist) {
            my $quantity = $npc->CountItem($item_id);
            push @inventory, "$item_id:$quantity";
        }

        my $data = @inventory ? join(",", @inventory) : "EMPTY";
        plugin::SEV($npc, "is_charmed", $data);

    } elsif (not $npc->Charmed() and plugin::REV($npc, "is_charmed")) {
        
        my $data = plugin::REV($npc, "is_charmed");
        my @inventory = split(",", $data);

        my @lootlist = $npc->GetLootList();
        while (@lootlist) { # While lootlist has elements
            foreach my $item_id (@lootlist) {
                $npc->RemoveItem($item_id);
            }
            @lootlist = $npc->GetLootList(); # Update the lootlist after removing items
        }

        foreach my $item (@inventory) {
            my ($item_id, $quantity) = split(":", $item);
            #quest::debug("Adding: $item_id x $quantity");
            $npc->AddItem($item_id, $quantity);
        }

        plugin::SEV($npc, "is_charmed", "");
    }
}

sub UPDATE_PET {
    #quest::debug("--Syncronizing Pet Inventory--");
    my $owner = $npc->GetOwner()->CastToClient();
    my $bag_size = 200; # actual bag size limit in source
    my $bag_id = 199999; # Custom Item
    my $bag_slot = 0;

    if ($owner) {       
        my %new_pet_inventory;
        my %new_bag_inventory;
        my $updated = 0;

        my $inventory = $owner->GetInventory();
        #Determine if first instance of pet bag is in inventory or bank
        for (my $iter = quest::getinventoryslotid("general.begin"); $iter <= quest::getinventoryslotid("bank.end"); $iter++) {
            if ((($iter >= quest::getinventoryslotid("general.begin") && $iter <= quest::getinventoryslotid("general.end")) ||
                ($iter >= quest::getinventoryslotid("bank.begin") && $iter <= quest::getinventoryslotid("bank.end")))) {
                
                if ($owner->GetItemIDAt($iter) == $bag_id) {
                        $bag_slot = $iter;
                }
            }
        }
        if ($bag_slot) {
            # Determine contents
            if ($bag_slot >= quest::getinventoryslotid("general.begin") && $bag_slot <= quest::getinventoryslotid("general.end")) {
                %new_bag_inventory = GET_BAG_CONTENTS(\%new_bag_inventory, $owner, $bag_slot, quest::getinventoryslotid("general.begin"), quest::getinventoryslotid("generalbags.begin"), $bag_size);
            } elsif ($bag_slot >= quest::getinventoryslotid("bank.begin") && $bag_slot <= quest::getinventoryslotid("bank.end")) {
                %new_bag_inventory = GET_BAG_CONTENTS(\%new_bag_inventory, $owner, $bag_slot, quest::getinventoryslotid("bank.begin"), quest::getinventoryslotid("bankbags.begin"), $bag_size);
            } else {
                return;
            }

            # Fetching pet's inventory
            my @lootlist = $npc->GetLootList();

            # Sort the lootlist based on criteria
            @lootlist = sort {
                my $a_proceffect = $npc->GetItemStat($a, "proceffect") || 0;
                my $a_damage = $npc->GetItemStat($a, "damage") || 0;
                my $a_delay = $npc->GetItemStat($a, "delay") || 0;
                my $a_ratio = ($a_delay > 0 ? $a_damage / $a_delay : 0);
                my $a_ac = $npc->GetItemStat($a, "ac") || 0;
                my $a_hp = $npc->GetItemStat($a, "hp") || 0;

                my $b_proceffect = $npc->GetItemStat($b, "proceffect") || 0;
                my $b_damage = $npc->GetItemStat($b, "damage") || 0;
                my $b_delay = $npc->GetItemStat($b, "delay") || 0;
                my $b_ratio = ($b_delay > 0 ? $b_damage / $b_delay : 0);
                my $b_ac = $npc->GetItemStat($b, "ac") || 0;
                my $b_hp = $npc->GetItemStat($b, "hp") || 0;

                ($b_proceffect > 0 ? 1 : 0) <=> ($a_proceffect > 0 ? 1 : 0)
                || $b_ratio <=> $a_ratio
                || $b_ac <=> $a_ac
                || $b_hp <=> $a_hp
                || $b <=> $a  # using item IDs for final tiebreaker
            } @lootlist;

            foreach my $item_id (@lootlist) {
                my $quantity = $npc->CountItem($item_id);
                if ($quantity > 1) {
                    $updated = 1;
                    last;
                }
                $new_pet_inventory{$item_id} += $quantity;
            }
            
            foreach my $item_id (keys %new_pet_inventory) {
                # if the key doesn't exist in new_bag_inventory or the values don't match
                if (!exists $new_bag_inventory{$item_id}) {
                    $updated = 1; # set updated to true
                    quest::debug("Inconsistency detected: $item_id not in bag or quantities differ.");
                    last; # exit the loop as we have found a difference
                }
            }

            # if $updated is still false, it could be because new_bag_inventory has more items, check for that
            if (!$updated) {
                foreach my $item_id (keys %new_bag_inventory) {
                    # if the key doesn't exist in new_pet_inventory
                    if (!exists $new_pet_inventory{$item_id}) {                    
                        $updated = 1; # set updated to true
                        last; # exit the loop as we have found a difference
                    }
                }
            }

            if ($updated) {
                quest::debug("--Pet Inventory Reset Triggered--");
                my @lootlist = $npc->GetLootList();
                while (@lootlist) { # While lootlist has elements
                    foreach my $item_id (@lootlist) {
                        $npc->RemoveItem($item_id);
                    }
                    @lootlist = $npc->GetLootList(); # Update the lootlist after removing items
                }            

                while (grep { $_->{quantity} > 0 } values %new_bag_inventory) {
                    # Preprocess and sort item_ids by GetItemStat in ascending order
                    my @sorted_item_ids = sort {
                        my $count_a = () = unpack('B*', $owner->GetItemStat($a, "slots")) =~ /1/g;
                        my $count_b = () = unpack('B*', $owner->GetItemStat($b, "slots")) =~ /1/g;
                        $count_a <=> $count_b
                    } keys %new_bag_inventory;
                    
                    foreach my $item_id (@sorted_item_ids) {
                        quest::debug("Processing item to add: $item_id");
                        if ($new_bag_inventory{$item_id}->{quantity} > 0) {
                            $npc->AddItem($item_id, 1, 1, @{$new_bag_inventory{$item_id}->{augments}});
                            $new_bag_inventory{$item_id}->{quantity}--;
                        }
                    }
                }

            }
        }

        if (not $npc->Charmed()) {
            UPDATE_PET_STATS();
        }  
    } else {
        quest::debug("The owner is not defined");
        return;
    }
}

sub GET_BAG_CONTENTS {
    my %blacklist = map { $_ => 1 } (5532, 10099, 20488, 14383, 20490, 10651, 20544, 28034, 10650, 8495);
    my ($new_bag_inventory_ref, $owner, $bag_slot, $ref_general, $ref_bags, $bag_size) = @_;
    my %new_bag_inventory;

    my %occupied_slots; # To keep track of slots already taken
    my @items;

    my $rel_bag_slot = $bag_slot - $ref_general;
    my $bag_start = $ref_bags + ($rel_bag_slot * $bag_size);
    my $bag_end = $bag_start + $bag_size;

    for (my $iter = $bag_start; $iter < $bag_end; $iter++) {                
        my $item_id = $owner->GetItemIDAt($iter);
        if ($item_id > 0 && !exists($blacklist{$item_id})) {
            my @augments;
            for (my $aug_iter = 0; $aug_iter < 6; $aug_iter++) {
                if ($owner->GetAugmentAt($iter, $aug_iter)) {
                    push @augments, $owner->GetAugmentIDAt($iter, $aug_iter);
                } else {
                    push @augments, 0;
                }
            }
            if ($owner->GetItemStat($item_id, "itemtype") != 54) {
                push @items, {
                    slot => $iter,
                    id => $item_id,
                    proceffect => $owner->GetItemStat($item_id, "proceffect") || 0,
                    ratio => ($owner->GetItemStat($item_id, "delay") > 0 ? ($owner->GetItemStat($item_id, "damage") / $owner->GetItemStat($item_id, "delay")) : 0),
                    ac => $owner->GetItemStat($item_id, "ac") || 0,
                    hp => $owner->GetItemStat($item_id, "hp") || 0,
                    slots => $owner->GetItemStat($item_id, "slots"),
                    augments => \@augments
                };
            }
        }
    }

    # Sort items by proceffect in descending order
    @items = sort { ($b->{proceffect} > 0 ? 1 : 0) <=> ($a->{proceffect} > 0 ? 1 : 0) ||
                     $b->{ratio} <=> $a->{ratio} ||
                     $b->{ac} <=> $a->{ac} || $b->{hp} <=> $a->{hp} || 
                     $b->{id} <=> $a->{id} } @items;

    foreach my $item (@items) {
        for my $slot_bit (reverse 0..20) {
            if ($item->{slots} & (1 << $slot_bit) && !$occupied_slots{$slot_bit}) {
                $occupied_slots{$slot_bit} = 1;
                $new_bag_inventory{$item->{id}} = { quantity => 1, slot => $item->{slot}, augments => $item->{augments} };
                last;
            }
        }
    }

    return %new_bag_inventory;
}

sub APPLY_FOCUS {
    my $owner = $npc->GetOwner()->CastToClient();
    my $inventory = $owner->GetInventory();
    my $true_race = $owner->GetBucket("pet_race");
    my $total_focus_scale = 1.0;

    if (grep { $_ == $owner->GetClass() } (13, 15, 11)) {
        $total_focus_scale += 0.30;
    }

    my %focus_data = (
        'Manifest Elements'   => { 'focus' => 1936, 'buff' => 847,   'factor' => 0.30 },
        'Minion of Air'       => { 'focus' => 4396, 'buff' => undef, 'factor' => 0.05 },
        'Minion of Fire'      => { 'focus' => 4397, 'buff' => undef, 'factor' => 0.05 },
        'Minion of Water'     => { 'focus' => 4398, 'buff' => undef, 'factor' => 0.05 },
        'Minion of Earth'     => { 'focus' => 4399, 'buff' => undef, 'factor' => 0.05 },
        'Minion of Hate'      => { 'focus' => 4404, 'buff' => undef, 'factor' => 0.05 },
        'Servant of Fire'     => { 'focus' => 4401, 'buff' => undef, 'factor' => 0.10 },
        'Servant of Water'    => { 'focus' => 4402, 'buff' => undef, 'factor' => 0.10 },
        'Servant of Earth'    => { 'focus' => 4403, 'buff' => undef, 'factor' => 0.10 },
        'Servant of Air'      => { 'focus' => 4400, 'buff' => undef, 'factor' => 0.10 },
        'Summoner\'s Boon'    => { 'focus' => 4400, 'buff' => undef, 'factor' => 0.15 },
        'Ritual Summoning'    => { 'focus' => 4410, 'buff' => undef, 'factor' => 0.15 },
        'Minion of Eternity'  => { 'focus' => 4405, 'buff' => undef, 'factor' => 0.40 },
        'Minion of Discord'   => { 'focus' => 5061, 'buff' => undef, 'factor' => 0.20 },
        'Servant of Chaos'    => { 'focus' => 6089, 'buff' => undef, 'factor' => 0.30 },
        'Spire Servant'       => { 'focus' => 8399, 'buff' => undef, 'factor' => 0.20 },
        'Servitor of Scale'   => { 'focus' => 9618, 'buff' => undef, 'factor' => 0.20 },
    );
    
    # Loop through each focus item in the focus_data hash
    foreach my $focus_name (keys %focus_data) {
        my $focus_id = $focus_data{$focus_name}{'focus'};
        my $buff_id = $focus_data{$focus_name}{'buff'};
        my $factor = $focus_data{$focus_name}{'factor'};

        if (plugin::is_focus_equipped($owner, $focus_id)) { 
            if ($buff_id && !$npc->FindBuff($buff_id)) {
                $npc->CastSpell($buff_id, $npc->GetID());
            }
            $total_focus_scale += $factor;
        }
    }

    return $total_focus_scale;
}

sub SAVE_PET_STATS
{
    my $pet = $npc;
    my $owner = $pet->GetOwner()->CastToClient();

    if ($owner) {     
        my @stat_list = qw(atk accuracy avoidance hp_regen min_hit max_hit max_hp ac mr fr cr dr pr);
        foreach my $stat (@stat_list) {
            $owner->SetBucket("pet_$stat", $pet->GetNPCStat($stat));
        }
        
        $owner->SetBucket("pet_race", $pet->GetBaseRace());
    }
}

sub UPDATE_PET_STATS
{
    my $pet = $npc;
    my $owner = $pet->GetOwner()->CastToClient();

    if ($owner) {
        # Create Scalar.
        my $pet_scalar = APPLY_FOCUS();

        # This is so damned weird. The value reported by GetNPCStat is 40x lower than the 'real' value.
        # this is actually correct to set pet's speed to slightly faster than owner's.
        my $owner_speed = $owner->GetRunspeed() + 20;
        my $pet_speed = $pet->GetNPCStat("runspeed")*40;

        if ($owner_speed > $pet_speed) {            
            $pet->ModifyNPCStat("runspeed", $owner_speed/40);
        }

        my $pet_hstr = $owner->GetItemBonuses()->GetHeroicSTR();
        my $pet_hsta = $owner->GetItemBonuses()->GetHeroicSTA();
        my $pet_hagi = $owner->GetItemBonuses()->GetHeroicAGI();
        my $pet_hdex = $owner->GetItemBonuses()->GetHeroicDEX();
        my $pet_hint = $owner->GetItemBonuses()->GetHeroicINT();
        my $pet_hwis = $owner->GetItemBonuses()->GetHeroicWIS();
        my $pet_hcha = $owner->GetItemBonuses()->GetHeroicCHA();
        my $pet_hstat_total = 0;

        # Fetching pet's inventory
        my @lootlist = $npc->GetLootList();                
        foreach my $item_id (@lootlist) {
            $pet_hsta += $pet->GetItemStat($item_id, "heroicsta");
            $pet_hstr += $pet->GetItemStat($item_id, "heroicstr");
            $pet_hagi += $pet->GetItemStat($item_id, "heroicagi");
            $pet_hdex += $pet->GetItemStat($item_id, "heroicdex");
            $pet_hint += $pet->GetItemStat($item_id, "heroicint");
            $pet_hwis += $pet->GetItemStat($item_id, "heroicwis");
            $pet_hcha += $pet->GetItemStat($item_id, "heroiccha");
        }

        $pet_hstat_total = $pet_hsta + $pet_hstr + $pet_hagi + $pet_hdex + $pet_hint + $pet_hwis + $pet_hcha;

        my @stat_list = qw(avoidance atk accuracy hp_regen min_hit max_hit max_hp ac mr fr cr dr pr);
        foreach my $stat (@stat_list) {
            my $bucket_value = $owner->GetBucket("pet_$stat") || 0;

            if ($stat eq 'max_hp') {
                $bucket_value += 20 * ($pet_hsta);                            
            }

            if ($stat eq 'avoidance') {
                $bucket_value += 2 * $pet_hagi;
            }

            if ($stat eq 'ac') {
                $bucket_value += 10 * $pet_hagi;
            }

            if ($stat eq 'max_hit' || $stat eq 'min_hit') {                
                my $damage_bonus = 0;
                foreach my $item_id (7..8) {
                    my $equipment_id = $npc->GetEquipment($item_id);

                    if ($equipment_id > 0) {        
                        my $damage = $npc->GetItemStat($equipment_id, "damage");
                        my $delay = $npc->GetItemStat($equipment_id, "delay");
                        if ($delay > 0) {
                            my $ratio = $damage / $delay;
                            $damage_bonus += $ratio;
                        }                        
                    }
                }
                $damage_bonus = $damage_bonus/2 * $npc->GetLevel();

                if ($stat eq 'min_hit') {
                    $bucket_value = max($damage_bonus, $bucket_value);
                } else {
                    $bucket_value = max($damage_bonus*2, $bucket_value);
                }

                $bucket_value += floor($owner->GetItemBonuses()->GetHeroicSTR() / 10);            
            }

            $bucket_value *= $pet_scalar;
            $pet->ModifyNPCStat($stat, ceil($bucket_value));
        }
    }
}