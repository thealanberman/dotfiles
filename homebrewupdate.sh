#!/usr/bin/env zsh

echo "$(date): RUNNING: brew update"
brew update
echo "$(date): FINISHED: brew update"

echo "$(date): RUNNING: brew upgrade"
brew upgrade
echo "$(date): FINISHED: brew upgrade"

echo "$(date): RUNNING: brew cleanup"
brew cleanup
echo "$(date): FINISHED: brew cleanup"
