#!/usr/bin/env bash
programs=(
  ruby-jekyll-archives
  ruby-jekyll-avatar
  ruby-jekyll-default-layout
  ruby-jekyll-feed
  # ruby-jekyll-gist
  ruby-jekyll-github-metadata
  ruby-jekyll-mentions
  ruby-jekyll-readme-index
  ruby-jekyll-relative-links
  ruby-jekyll-remote-theme
  ruby-jekyll-seo-tag
  ruby-jekyll-sitemap
  # ruby-jekyll-spaceship
  ruby-kramdown-parser-gfm
  ruby-netrc
)
if command -v yay &>/dev/null; then
  yay -S --noconfirm "${programs[@]}"
else
  echo please install yay!
  exit 1
fi
