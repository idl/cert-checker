#!/bin/perl

use strict;
use warnings;
use Net::SSL;    # For SSL connection
use Time::Local; # For date calculations
use Crypt::X509;
use Net::SMTP;

# This script will email to let you know if your SSL certificates are soon to expire.
# How many days is "soon":
my $threshold = 21; # days

my $smtp_host = 'localhost';  # set to your mail server
my $smtp_port = 25;
my $subject = 'SSL Certificates Report!';
my $mail_from = 'SSL Checker Cron <cert-checker-cron@yourdomain.com>';
my @mail_to = ('your-email@yourdomain.com');  # trouble reports.  Can have multiple addresses.

my ($infile, $website, $fh, @trouble, @okay);
my ($ssl, $cert, $end_time, $end_date_str, $sec, $min, $hour, $day, $mon, $year, $now, $days_left);

sub sendmail {
  my ($mail_from, $subject, $body, @mail_to) = @_;
  my $m;
  $m = new Net::SMTP("$smtp_host:$smtp_port", Debug => 0);
  $m->mail($mail_from);
  $m->recipient(@mail_to);
  $m->data();
  $m->datasend("From: $mail_from\n");
  $m->datasend("To: $_\n") foreach (@mail_to);
  $m->datasend("Subject: $subject\n");
  $m->datasend("\n");
  $m->datasend("$body\n");
  $m->dataend();
  $m->quit();
}

#### main ###########################################################################

# Get the list of websites from file $ARGV[0]
if (!$ARGV[0]) {
  print "Usage: $0 {filename}.\nExiting.\n";
  exit 1;
} elsif (!-f $ARGV[0]) {
  print "Error: cannot open file $ARGV[0].\n";
  exit 2;
}

$infile = $ARGV[0];

open $fh, "<", $infile or die "Could not open file '$infile': $!";

while ($website = <$fh>) {
  chomp $website; # Remove newline

  eval { # Use eval to catch errors
    $ssl = Net::SSL->new(
      PeerAddr => $website,
      PeerPort => 443, # Or other port if needed
      # Add ServerName for SNI if required:
      # ServerName => $website,
    ) or die "SSL connection failed: $@";

    $cert = $ssl->get_peer_certificate() or die "Could not get certificate: $@";
    $end_date_str = $cert->not_after();


    # Parse the date string (adjust format if needed)
    $end_date_str =~ s/\s.*$//;  # don't care about hours, mins, secs, just date.
    ($year, $mon, $day) = split/-/,$end_date_str;
    $end_time = timelocal(0, 0, 0, $day, $mon - 1, $year);  # Perl wants an ordinal month
    $now = time();
    $days_left = int(($end_time - $now) / (60 * 60 * 24));

    if ($days_left <= $threshold) {
      push @trouble, "$website: Expiry: $end_date_str ($days_left days left)";
    } else {
      push @okay, "$website: Expiry: $end_date_str ($days_left days left)";
    }
  };

  if ($@) { # Catch and print any errors from the eval block
    push @trouble, "Error checking $website: $@";
  }
}

close $fh;

# We are only sending an email report if there is trouble, but if we are sending
# an email, we will report everything: what's @trouble-ing and what's @okay.
if ($#trouble >= 0) {
  my $body = "SSL Certificate Cron Report\n\n";
  $body .= "\nThese sites use SSL certificates that are expiring within $threshold days:\n\n";
  foreach (sort @trouble) {
    $body .= "$_\n";
  }
  $body .= "\nAnd now for the good news:\n\n";
  foreach (sort @okay) {
    $body .= "$_\n";
  }
  $body .= "\nThis report was generated by $0 on somehost.yourdomain.com.  Have a great day, or else!\n";
  sendmail($mail_from, $subject, $body, @mail_to);
}
