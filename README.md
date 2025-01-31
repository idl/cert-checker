# cert-checker
Simple Perl script to check whether SSL certificates are expiring "soon"

Invocation:  /path/to/perl cert-checker.pl sample-sites-file.txt

You should edit the Perl file and configure your SMTP settings so the mail can be delivered.  Also, set $threshold variable (in number of days): e.g., if you want to be warned about certificates expiring within 21 days, set $threshold = 21.  We are using this script to check on about 30 sites, nothing fancy, no load balancers, for instance.

On our Debian systems, we had to install some prerequisite Perl libs:

- Net::SSL
- Time::Local
- Crypt::X509
- Net::SMTP

which are easy enough to find.  For instance, what Perl calls 'Net::SSL' is in Debian package 'libnet-ssleay-perl'.  (i.e., "apt-cache search Net::SSL").  So it is a two-part process to use apt-cache to search for the module by Perl's name for it, find out what Debian package it is in, and then "apt install libnet-ssleay-perl".

This is provided as-is, no warranties, use at your own risk.
