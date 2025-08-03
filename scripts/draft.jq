#!/usr/bin/env -S jq -SsRrf
{"can_reward": false, "delta_time": 30, "table_of_contents": false, "title": "\($title)", "content": "\(.)"} | tostring
