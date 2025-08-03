#!/usr/bin/env -S sqlite3 -batch -init
SELECT value FROM moz_cookies WHERE host='.zhihu.com' AND name='d_c0';
SELECT value FROM moz_cookies WHERE host='.zhihu.com' AND name='z_c0';
