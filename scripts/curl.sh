#!/usr/bin/env bash
# $ scripts/curl.sh title file.html [id]
# it will open https://zhuanlan.zhihu.com/p/$id/edit
set -e
cd "$(dirname "$(dirname "$(readlink -f "$0")")")"

cookies=($(scripts/select.sql ~/.mozilla/firefox/*.default-release/cookies.sqlite .quit))
d_c0="${cookies[0]}"
z_c0="${cookies[1]}"
title="$1"
html="$2"
id="$3"

if [ -z "$id" ]; then
  method=POST
  url=https://zhuanlan.zhihu.com/api/articles/drafts
else
  method=PATCH
  url="https://zhuanlan.zhihu.com/api/articles/$id/draft"
fi

curl -s -X "$method" "$url" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36" -H "Content-Type: application/json" -H "Cookie: d_c0=$d_c0; z_c0=$z_c0" -H "x-requested-with: fetch" -d "$(scripts/draft.jq --arg title "$title" "$html")" |
  jq -r .url |
  xargs -I{} xdg-open {}/edit
if [ -n "$id" ]; then
  xdg-open "https://zhuanlan.zhihu.com/p/$id/edit"
fi
