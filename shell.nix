{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  packages =
    with rubyPackages;
    [
      jekyll-archives
      jekyll-avatar
      jekyll-default-layout
      jekyll-feed
      jekyll-gist
      jekyll-github-metadata
      jekyll-mentions
      jekyll-readme-index
      jekyll-relative-links
      jekyll-remote-theme
      jekyll-seo-tag
      jekyll-sitemap
      jekyll-spaceship
      kramdown-parser-gfm
      netrc
    ];
}
