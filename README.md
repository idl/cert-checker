# cert-checker
Simple Perl script to check whether SSL certificates are expiring "soon"

Invocation:  /path/to/perl cert-checker.pl sample-sites-file.txt

You should edit the Perl file and configure your SMTP settings so the mail can be delivered.  Also, set $threshold variable (in number of days): e.g., if you want to be warned about certificates expiring within 21 days, set $threshold = 21.  We are using this script to check on about 30 sites, nothing fancy, no load balancers, for instance.

This is provided as-is, no warranties, use at your own risk.
