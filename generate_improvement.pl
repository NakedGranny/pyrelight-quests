#!/usr/bin/perl
use warnings;
use DBI;
use POSIX;
use List::Util qw(max);

sub LoadMysql {
        use DBI;
        use DBD::mysql;
        use JSON;

        my $json = new JSON();

        #::: Load Config
        my $content;
        open(my $fh, '<', "../eqemu_config.json") or die; {
                local $/;
                $content = <$fh>;
        }
        close($fh);

        #::: Decode
        $config = $json->decode($content);

        #::: Set MySQL Connection vars
        $db   = $config->{"server"}{"database"}{"db"};
        $host = "10.10.20.220";
        $user = $config->{"server"}{"database"}{"username"};
        $pass = $config->{"server"}{"database"}{"password"};

        #::: Map DSN
        $dsn = "dbi:mysql:$db:$host:3306";

        #::: Connect and return
        $connect = DBI->connect($dsn, $user, $pass);

        return $connect;
}

# Use the LoadMysql function to get the database handle
my $dbh = LoadMysql();

# Check if successfully connected
unless ($dbh) {
    die "Failed to connect to database.";
}

sub slots {
    my ($bitmask, @slots) = @_;
    my %slot_to_bitmask = (
        'Secondary' => 16384,
        'Head' => 4,
        'Face' => 8,
        'Shoulder' => 64,
        'Arms' => 128,
        'Back' => 256,
        'Bracer 1' => 512,
        'Bracer 2' => 1024,
        'Hands' => 4096,
        'Chest' => 131072,
        'Legs' => 262144,
        'Feet' => 524288,
        'Ear 1' => 2,
        'Ear 2' => 16,
        'Neck' => 32,
        'Primary' => 8192,
        'Ring 1' => 32768,
        'Ring 2' => 65536,
        'Waist' => 1048576
    );
    foreach my $slot (@slots) {
        return 1 if ($bitmask & $slot_to_bitmask{$slot});
    }
    return 0;
}

sub ceil_to_nearest_5 {
    my ($value) = @_;
    return ceil($value / 5) * 5;
}

my $max_id = 200000;
my $chunk_size = 200000;

for my $tier (1..100) {
    for (my $id = 0; $id < $max_id; $id += $chunk_size) {
        # Fetch data from the table
        my $sth = $dbh->prepare("SELECT * FROM items WHERE items.id BETWEEN ? AND ?");
        $sth->execute($id, $id + $chunk_size - 1) or die $DBI::errstr;

        while (my $row = $sth->fetchrow_hashref()) {
            if ($row->{slots} > 0 and $row->{classes} > 0 and $row->{Name} !~ /^Apocryphal/) {

                my @keys = qw(hp mana endur proceffect damage mr cr fr pr dr astr asta adex aagi aint awis heroic_str heroic_sta heroic_dex heroic_agi heroic_int heroic_wis heroic_cha heroic_mr heroic_cr heroic_fr heroic_dr heroic_pr);

                my $all_zero = 1;
                for my $key (@keys) {
                        if ($row->{$key} > 0) {
                                $all_zero = 0;
                                last;
                        }
                }

                next if $all_zero; # Skip to next iteration if all values are zero or less

                my $modifier 	   = $tier * 0.33;
                my $modifier_minor = $modifier/2;
				
				# Name & ID
				$row->{id} = $row->{id} + (1000000 * $tier);
                $row->{Name} = $row->{Name} . " +$tier";
				if ($row->{charmfile} =~ /^(\d+)#/) {
					$row->{charmfile} =~ s/^\d+#/$row->{id}#/;
				}

                $row->{attuneable} = 1;
                $row->{nodrop} = 0;
                $row->{price} = $row->{price} * $modifier + $tier;

                if ($row->{skillmodvalue} > 0 && $row->{skillmodmax} > 0) {
                    $row->{skillmodmax} = $row->{skillmodmax} + ceil($row->{skillmodmax}*$modifier);
                    
                }
                $row->{skillmodvalue} = $row->{skillmodvalue} + ($row->{skillmodvalue}*$modifier);
				
				# Basic Stats                                
                if ($row->{damage} > 0 && $row->{delay} > 0 && $row->{itemtype} != 54) {
                    my $current_ratio = $row->{damage} / $row->{delay};  # Calculate the current damage/delay ratio
                    my $new_ratio = $current_ratio * (1 + $modifier_minor);   # Compute the new ratio

                    # Calculate the additional damage required to achieve the new ratio
                    my $additional_damage = ($new_ratio * $row->{delay}) - $row->{damage};
                    
                    $row->{damage} = max($tier, $row->{damage} + $additional_damage);
                    
                } elsif ($row->{damage} > 0 && grep { $_ == $row->{itemtype} } (0, 1, 2, 3, 4, 5, 7, 35, 45)) {
                    $row->{damage} = $row->{damage} + $tier;
                }

                if ($row->{proceffect} > 0) {
                    $row->{procrate} += abs($row->{procrate}) * $modifier;
                }


                $row->{hp} = ceil_to_nearest_5($row->{hp} + abs($modifier * $row->{hp}));
                $row->{ac} += max($row->{ac} ? $tier : 0, ceil(abs($row->{ac} * $modifier_minor)));

				
                # Adjusting Heroic Stats
                foreach my $stat (qw(heroic_str heroic_sta heroic_dex heroic_agi heroic_int heroic_wis heroic_cha heroic_mr heroic_fr heroic_cr heroic_dr heroic_pr
                                     avoidance accuracy spellshield dotshielding shielding strikethrough manaregen regen stunresist combateffects)) {
                    $row->{$stat} += max($row->{$stat} ? $tier : 0, ceil(abs($row->{$stat} * $modifier)));
                }

                # Create an INSERT statement dynamically
                my $columns = join(",", map { $dbh->quote_identifier($_) } keys %$row);
                my $values  = join(",", map { $dbh->quote($_) } values %$row);
                my $sql = "REPLACE INTO items ($columns) VALUES ($values)";

                print "Creating: $row->{id} ($row->{Name})\n";
                # Insert the new row into the table
                                my $isth = $dbh->prepare($sql)
                                  or die "Failed to prepare insert: " . $dbh->errstr;
                                $isth->execute() or die $DBI::errstr;
            }
        }
    }
}

$dbh->disconnect();