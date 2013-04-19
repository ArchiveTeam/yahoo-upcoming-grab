#!/bin/bash
./wget-lua \
  -U "Mozilla/5.0 (Windows NT 6.2) AppleWebKit/257.6 (KHTML, like Gecko) Chrome/20.0.3010.0 Safari/855.6" \
  -e "robots=off" \
  --lua-script upcoming.lua \
  --warc-file upcoming-test \
  -O t.html \
  --truncate-output \
  --page-requisites --span-hosts \
  -nv \
  --reject-regex='\.bc\.yahoo\.com|analytics\.yahoo\.com|overture\.com|l\.yimg\.com/d/combo' \
  http://upcoming.yahoo.com/venue/750802
  http://upcoming.yahoo.com/event/148676

