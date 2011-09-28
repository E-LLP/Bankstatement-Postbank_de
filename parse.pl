#!/usr/bin/perl

use strict;
use warnings;

#use Data::Dumper;

# convert from german number format to perl float
sub to_float {
  my $value = shift;

  # remove the dot
  $value =~ s/\.//g;

  # change the comma to a dot
  $value =~ s/,/\./g;

  return $value;
}

my @filenames;
if (@ARGV) {
  @filenames = @ARGV;
}
else {
  @filenames = glob("konto*.pdf");
}

foreach my $filename (@filenames) {
  my @output = qx{ps2ascii $filename};

  my %kontoauszug;
  $kontoauszug{"Filename"} = $filename;

  # Start parsing:
  foreach my $line (@output) {
    chomp($line);

    # Date:
    if ($line =~ m{Datum \s* (\S*)}xm) {
      my @date_token = unpack("A2 A1 A2 A1 A4", $1);
      $kontoauszug{"Month"} = $date_token[2];
      $kontoauszug{"Year"}  = $date_token[4];
    }

    # Kontostand:
    if ($line =~ m{Neuer \s* Kontostand \s* (\w*) \s* (\S*) \s* (\S*)}xm) {
      my ($currency, $value, $prefix) = ($1, $2, $3);
      if (not defined $kontoauszug{"Kontostand"}) {
        $value = to_float($value);
        if ($prefix eq '+') {
          $prefix = "";
        }

        # save the interesting data:
        $kontoauszug{"Kontostand"} = $prefix . $value;
        $kontoauszug{"Currency"}   = $currency;
      }
    }

    # Zahlungseingänge:
    if ($line =~ m{Zahlungsei\S* \s* Euro \s* (\S*)}xm) {
      my $value = $1;
      $value = to_float($value);
      $kontoauszug{"Zahlungseingänge"} = $value;
    }

    # Zahlungsausgänge:
    if ($line =~ m{Zahlungsau\S* \s* Euro \s* (\S*)}xm) {
      my $value = $1;
      $value = to_float($value);
      $kontoauszug{"Zahlungsausgänge"} = $value;
    }

  }

  # Show what we got:
  #print Dumper(\%kontoauszug);
  print $kontoauszug{"Year"}
    . $kontoauszug{"Month"} . " "
    . $kontoauszug{"Zahlungseingänge"} . " -"
    . $kontoauszug{"Zahlungsausgänge"} . " "
    . $kontoauszug{"Kontostand"} . " "
    . ($kontoauszug{"Zahlungseingänge"} - $kontoauszug{"Zahlungsausgänge"})
    . "\n";
}
