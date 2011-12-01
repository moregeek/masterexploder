#!/usr/bin/perl

# ##############################################################################
#                                                                              #
#     description : small game bot which comunicates via STDIN and STDOUT with #
#                   the server. This was implemented just for fun for a        #
#                   programmers contest - for more information visit:          #
#                   http://www.freiesmagazin.de/vierter_programmierwettbewerb  #
#                                                                              #
#          author : Stefan M.                                                  #
#            date : 30/11/2011                                                 #
#         license : CC BY-NC-SA                                                # 
#          source : https://github.com/moregeek/masterexploder                 #
#                                                                              #
# ##############################################################################

use Switch;

local $| = 1; # flush stdout!

my ( $settings, $values, $input ) = undef;
my %settings = (
                 debug    => '0',
                 max      => '1000',
               );

my %values   = (
                 round_to_play          => '0',
                 round_now              => '0',
                 botname                => int(rand(99999)),
                 # my
                 my_points              => '0',
                 my_points_negative     => '0',
                 my_points_plus         => '0',
                 # enemy
                 en_points              => '0',
                 en_points_negative     => '0',
                 en_points_plus         => '0', 
                 # strategy settings:
                 strategy_current       => 'strategy_minimal',
                 strategy_works         => 'yes',
                 # GreatNessLevel:
                 GreatNessLevel         => 0.5,
                 # strategy: minimal
                 strategy_minimal       => {
                                              max => int(500+rand(100)),
                                              min => '0'
                                           },
               );

# ##############################################################################
# Read STDIN                                                                   #
# ##############################################################################
while( $input = <STDIN>) {
  # Remove Line break at the end:
  chomp($input);

  # Log input for debugging:
  &debug("stdin::got", "$input") if ( $settings{'debug'} eq '1' );

  switch ( $input ) {
    case /^RUNDEN\s[0-9]+$/    {  $values{'round_to_play'} = &pharse_value;    }
    case /^RUNDE\s[0-9]+$/     {  $values{'round_now'}     = &pharse_value;    }
    case /^PUNKTE\s[0-9]+$/    {  &gPoints;       }
    case /^START$/             {  &main('start'); }
    case /^ANGEBOT\s[0-9]+$/   {  &main('offer'); }
    case /^JA$/                {  &main('yes');   }
    case /^NEIN$/              {  &main('no');    } 
    case /^ENDE$/              {  &gEnd;          }
    else               {  print STDERR "ERROR: Protocol Missmatch!\n"; exit 1; }
  }
}
# ##############################################################################


# ##############################################################################
# main subroutine
# ##############################################################################
sub main {

  &debug("sub::main", "<entered sub>") if ( $settings{'debug'} eq '1' );
  
  my $s     = shift;
  local $strat = &strategy;

  &debug("sub::main::action->value",   "$s")     if ( $settings{'debug'} eq '1' );
  &debug("sub::main::strategy->value", "$strat") if ( $settings{'debug'} eq '1' );

  if     ( $strat eq 'strategy_minimal'   ) { &stratMinimal($s); }
  elsif  ( $strat eq 'strategy_aggresive' ) { &stratFair($s); } # not implemented due to lack of time :/
  else   { &stratFair($s); }
               
  # some debug stuff:
  &debug("sub::main::value->my_points", "$values{'my_points'}") if ( $settings{'debug'} eq '1' );
  &debug("sub::main::value->my_points_negative", "$values{'my_points_negative'}") if ( $settings{'debug'} eq '1' );
  &debug("sub::main::value->my_points_plus", "$values{'my_points_plus'}") if ( $settings{'debug'} eq '1' );
  
  &debug("sub::main::value->en_points", "$values{'en_points'}") if ( $settings{'debug'} eq '1' );
  &debug("sub::main::value->en_points_negative", "$values{'en_points_negative'}") if ( $settings{'debug'} eq '1' );
  &debug("sub::main::value->en_points_plus", "$values{'en_points_plus'}") if ( $settings{'debug'} eq '1' );

  &debug("sub::main", "<leaving sub>") if ( $settings{'debug'} eq '1' );

}

# ##############################################################################
# Strategy: fair
# > ablehnlevel
# <= annahmelevel
# ##############################################################################
sub stratFair {

  local $s     = shift; 

  &debug("sub::stratFair::value->action", "$s") if ( $settings{'debug'} eq '1' );

  # START (other bot is waiting for my offer)
  # ------------------------------------------------------------------------------
  if ($s eq 'start') {

    local ($ret_y, $ret_n) = &calc_lower_uper_level;

    if ( $values{'GreatNessLevel'} < 0.3 ) { # other bot gives bad values...
      # than we give bad values two!
      $numb = rand($ret_no)
    } 
    else {
      # f: lower_level + random(my_max_give_away_value-acceptance level)
      $numb = int($ret_n+rand(500-$ret_y));
    }

    # internal stats:
    $values{'roundstats'}{"$values{'round_now'}"}{'value'} = $numb;
    
    # debug:
    &debug("sub::stratFair::value->send", $numb) if ( $settings{'debug'} eq '1' );
    &gSendAnswer( $numb );
    
  }

  # ANGEBOT (offer from other bot)
  # ------------------------------------------------------------------------------
  elsif ( $s eq 'offer' ) {
    # Offers are handeld the same way in every strategy:
    &gOffer;
  }

  # JA (offer was accepted)
  # ------------------------------------------------------------------------------
  elsif ( $s eq 'yes' ) {
    # internal stats:
    $values{'my_points_plus'}                   += 0;
    $values{'roundstats'}{"$values{'round_now'}"}{'yes_no'}    = 0;
  }
  
  # NEIN (offer was NOT accepted)
  # ------------------------------------------------------------------------------ 
  elsif ( $s eq 'no' ) {
    # internal stats:
    $values{'my_points_negative'}               += 1;
    $values{'roundstats'}{"$values{'round_now'}"}{'yes_no'}    = 1;
    
  }

}


# ##############################################################################
# Strategy: minimal
# ##############################################################################
sub stratMinimal {

  local $s     = shift;

  &debug("sub::stratMinimal::value->action", "$s") if ( $settings{'debug'} eq '1' );

  # START (other bot is waiting for my offer)
  # ------------------------------------------------------------------------------
  if ($s eq 'start') {
    
    # f: ( max - min ) / 2 + min
    $values{'strategy_minimal'}{'send'} =
      int (
              ($values{'strategy_minimal'}{'max'}
              -  $values{'strategy_minimal'}{'min'})
              / 2
              + $values{'strategy_minimal'}{'min'}
          );

    # stats save:
    $values{'roundstats'}{"$values{'round_now'}"}{'value'} = $values{'strategy_minimal'}{'send'};


    # debug:
    &debug("sub::stratMinimal::value->send", "$values{'strategy_minimal'}{'send'}") if ( $settings{'debug'} eq '1' );
    &gSendAnswer("$values{'strategy_minimal'}{'send'}");
    
  }

  # ANGEBOT (offer from other bot)
  # ------------------------------------------------------------------------------
  elsif ( $s eq 'offer' ) {

    # Offers are handeld the same way in every strategy:
    &gOffer;

  }

  # JA (offer was accepted)
  # ------------------------------------------------------------------------------
  elsif ( $s eq 'yes' ) {
    $values{'my_points_plus'} += 1; # internal stats
    # new max = send value
    $values{'strategy_minimal'}{'max'} = $values{'strategy_minimal'}{'send'};
    
    $values{'roundstats'}{"$values{'round_now'}"}{'yes_no'} = 0;
    
    &debug("sub::stratMinimal::value->my_points_plus", "$values{'my_points_plus'}") if ( $settings{'debug'} eq '1' );
    
    &debug("sub::stratMinimal::value->stategy_minimal->max", "$values{'strategy_minimal'}{'max'}") if ( $settings{'debug'} eq '1' );
    &debug("sub::stratMinimal::value->stategy_minimal->min", "$values{'strategy_minimal'}{'min'}") if ( $settings{'debug'} eq '1' );
  }
  # NEIN (offer was NOT accepted)
  # ------------------------------------------------------------------------------  
  elsif ( $s eq 'no' ) {
    $values{'my_points_negative'} += 1; # internal stats
    # new min = send value
    $values{'strategy_minimal'}{'min'} = $values{'strategy_minimal'}{'send'};
    
    $values{'roundstats'}{"$values{'round_now'}"}{'yes_no'} = 1;
    
    &debug("sub::stratMinimal::value->my_points_plus", "$values{'my_points_negative'}") if ( $settings{'debug'} eq '1' );
    
    &debug("sub::stratMinimal::value->stategy_minimal->max", "$values{'strategy_minimal'}{'max'}") if ( $settings{'debug'} eq '1' );
    &debug("sub::stratMinimal::value->stategy_minimal->min", "$values{'strategy_minimal'}{'min'}") if ( $settings{'debug'} eq '1' );
  }

  # Exit Strategy if the other bot has no fixed minimum value:
  # f: ( max - min ) < 1
  if ( ($values{'strategy_minimal'}{'max'}-$values{'strategy_minimal'}{'min'}) < '1' ) {
    $values{'strategy_works'}           = 'no';
    &debug("sub::stratMinimal::EXIT-STRATEGY", "max: $values{'strategy_minimal'}{'max'} # min: $values{'strategy_minimal'}{'min'}") if ( $settings{'debug'} eq '1' );
  }

}

# ##############################################################################
# gOffer implements the strategy when to take a offer.                         #
# ##############################################################################

sub gOffer {
  
  local $glevel = &GreatNessLevel(&pharse_value); 

  &debug("sub::gOffer::value->glevel", "$glevel") if ( $settings{'debug'} eq '1' );

  # good offer we will be taken
  if ( $glevel ge 0.3 ) {
    &gSendAnswer('yes');
    &debug("sub::gOffer::value->answer", "yes (LOCAL GreatNessLevel WAS good!") if ( $settings{'debug'} eq '1' );
  }
  # we take it only if the global greatness level is good
  elsif ($values{'GreatNessLevel'} ge "0.25") {
    &gSendAnswer('yes');
    &debug("sub::gOffer::value->answer", "yes (GLOBAL GreatNessLevel WAS good!") if ( $settings{'debug'} eq '1' );
  }
  else {
    &gSendAnswer('no');
    &debug("sub::gOffer::value->answer", "no (VERY BAD OVER ALL GreatNessLevel!)") if ( $settings{'debug'} eq '1' );
  }
  
}

# ##############################################################################
# Returns one of three strategies:                                             #
#   * strategy_aggresive                                                       #
#   * strategy_minimal                                                         #
#   * strategy_fair                                                            #
# ##############################################################################
sub strategy {
  
  &debug("sub::strategy", "<entered sub>") if ( $settings{'debug'} eq '1' );
  
  local $ret;
  
  # played 93% of all rounds AND
  # enemy has more points than me OR
  # enemy has less negative points than me
  if (  (  $values{'round_now'} >= ($values{'round_to_play'}/100*93)) &&
            (
              ( $values{'en_points'} > $values{'my_points'} ) ||
              ( $values{'en_points_negative'} < $values{'my_points_negative'} )
            )
     ) {
          $ret = 'strategy_aggresive';
          &debug("sub::strategy::strategy->return", "$ret") if ( $settings{'debug'} eq '1' );
       }
       
  # 0-93% of all games played
  else {
    # when minimal strategy works
    if ( ($values{'strategy_current'}  eq 'strategy_minimal') && 
         ($values{'strategy_works'}    eq 'yes')
       ) {
            $ret = 'strategy_minimal'; 
            &debug("sub::strategy::strategy->return", "$ret") if ( $settings{'debug'} eq '1' );
         }
    # else play fair :)
    else { 
            $ret = 'strategy_fair';
            &debug("sub::strategy::strategy->return", "$ret") if ( $settings{'debug'} eq '1' );
         }
  }

  &debug("sub::strategy", "<leaving sub>") if ( $settings{'debug'} eq '1' );
  
  return $ret;

}

# ##############################################################################
# "Calculates" the greatness of the other bot (could be solved better!)        #
# Inspired by SpamAssassin's idea to give points for specific actions... :)    #
# Needs the Offered Points as parameter.                                       #
# ##############################################################################
sub GreatNessLevel {

  &debug("sub::GreatNessLevel", "<entered sub>") if ( $settings{'debug'} eq '1' );
  
  local $val = shift;

  #                                          from:| to:
  # ---------------------------------------------------
  if    ( $val ge 600 ) { $tip =  0.5; }   # 1000 | 600
  elsif ( $val ge 580 ) { $tip =  0.4; }   #  600 | 580
  elsif ( $val ge 560 ) { $tip =  0.3; }   #  580 | 560
  elsif ( $val ge 540 ) { $tip =  0.3; }   #  560 | 540
  elsif ( $val ge 520 ) { $tip =  0.3; }   #  540 | 520
  elsif ( $val ge 500 ) { $tip =  0.3; }   #  520 | 500

  elsif ( $val ge 480 ) { $tip =  0.3; }   #  500 | 480
  elsif ( $val ge 460 ) { $tip =  0.3; }   #  480 | 460
  elsif ( $val ge 440 ) { $tip =  0.3; }   #  460 | 440
  elsif ( $val ge 420 ) { $tip =  0.3; }   #  440 | 420
  elsif ( $val ge 400 ) { $tip =  0.3; }   #  420 | 400

  elsif ( $val ge 380 ) { $tip =  0.3; }   #  400 | 380
  elsif ( $val ge 360 ) { $tip = -0.6; }   #  380 | 360
  elsif ( $val ge 340 ) { $tip = -0.7; }   #  360 | 340
  elsif ( $val ge 320 ) { $tip = -0.8; }   #  340 | 320
  elsif ( $val le 300 ) { $tip = -2.0; }   #  320 | 300

  # Greatness Level sum:
  $values{'GreatNessLevel'} += $tip; 
  
  &debug("sub::GreatNessLevel::result->value", "$tip") if ( $settings{'debug'} eq '1' );
  &debug("sub::GreatNessLevel::glevel_global->value", "$values{'GreatNessLevel'}") if ( $settings{'debug'} eq '1' );
  &debug("sub::GreatNessLevel", "<leaving sub>") if ( $settings{'debug'} eq '1' );
  
  return($tip);

}

# ##############################################################################
# "Calculates" the average for accepted & declined values for all played       #
# rounds Returns:                                                              #
#   * accepted                                                                 # 
#   * declined                                                                 #
# ##############################################################################
sub calc_lower_uper_level {

  &debug("sub::calc_lower_uper_level", "<entered sub>") if ( $settings{'debug'} eq '1' );

  local ($ya, $ys, $yc) = (1)x3;
  local ($na, $ns, $nc) = (1)x3;
  
  for $r (  keys(%{$values{'roundstats'}})  ) {
    if ($values{'roundstats'}{$r}{'yes_no'} eq 0) {
      $ys += $values{'roundstats'}{$r}{'value'};
      $yc += 1;
    } else {
      $ns += $values{'roundstats'}{$r}{'value'};
      $nc += 1;
    }
  }

  &debug("sub::calc_lower_uper_level::ys->value", "$ys") if ( $settings{'debug'} eq '1' );
  &debug("sub::calc_lower_uper_level::yc->value", "$yc") if ( $settings{'debug'} eq '1' );
  
  &debug("sub::calc_lower_uper_level::ns->value", "$ns") if ( $settings{'debug'} eq '1' );
  &debug("sub::calc_lower_uper_level::nc->value", "$nc") if ( $settings{'debug'} eq '1' );
  
  $ya = int(($ys / $yc));
  $na = int(($ns / $nc));
  
  &debug("sub::calc_lower_uper_level::ya->value", "$ya") if ( $settings{'debug'} eq '1' );
  &debug("sub::calc_lower_uper_level::na->value", "$na") if ( $settings{'debug'} eq '1' );

  &debug("sub::calc_lower_uper_level", "<leaving sub>") if ( $settings{'debug'} eq '1' );
  
  return($ya, $na);

}

# ##############################################################################
# END                                                                          #
# ##############################################################################
sub gEnd {

  # Clean exit
  exit 0;

}

# ##############################################################################
# Send Answer to server:                                                       #
#   * JA                                                                       #
#   * NEIN                                                                     #
#   * Value between: 0-1000                                                    #
# ##############################################################################
sub gSendAnswer {
  
  &debug("sub::gSendAnswer", "<entered sub>") if ( $settings{'debug'} eq '1' );
  
  local $a = shift;
  local $as = undef;

  if ( $a eq 'yes' ) { # JA
    $as="JA";
    $values{'en_points_plus'} += 1;
  }
  elsif ( $a eq 'no' ) { # NEIN
    $as="NEIN";
    $values{'en_points_negative'} += 1;
  }
  else { #offer
    $as=$a;
  }

  print "$as\n"; # send to stdout
  # debug:
  &debug("sub::gSendAnswer::send->value", "$as") if ( $settings{'debug'} eq '1' );
  &debug("sub::gSendAnswer", "<leaving sub>") if ( $settings{'debug'} eq '1' );
  
}

# ##############################################################################
# Saves Points from                                                            #
#   * My Bot                                                                   #
#   * Enemy Bot                                                                #
# ##############################################################################
sub gPoints {
  
  &debug("sub::gPoints", "<entered sub>") if ( $settings{'debug'} eq '1' );
  local $t = &pharse_value;
  $values{'my_points'} += $t;
  $values{'en_points'} = $values{'en_points'} + $settings{'max'} - $t;
  &debug("sub::pharse_value", "<leaving sub>") if ( $settings{'debug'} eq '1' );

}

# ##############################################################################
# Debug / print to file                                                        #
# ##############################################################################
sub debug {

  local ($note, $var) = @_;
  local $log = "/tmp/bot_debug_(" . $values{'botname'} . ").log";

  open(DEBUG, ">>$log") or die "could not open debug file!";
  if ( $note =~ "stdin" ) {
    print DEBUG "---------------------------------------------------------------------------\n"
  }
  print DEBUG sprintf("%-50s==> %-15s\n", $note, $var);
  close DEBUG;

}

# ##############################################################################
# Pharse incomming Values after Command                                        #
# ##############################################################################
sub pharse_value {
  
  &debug("sub::pharse_value", "<entered sub>") if ( $settings{'debug'} eq '1' );
  $input =~ m/([0-9]+)/;
  &debug("sub::pharse_value::retrurn->value", "$1") if ( $settings{'debug'} eq '1' );
  &debug("sub::pharse_value", "<leaving sub>") if ( $settings{'debug'} eq '1' );
  return $1;
  
}
