# Proposal — v0.4 Curl Installer

**Change**: v0.4-installer
**Project**: Nova2D

Single shell script (`install.sh`) that sets up a Nova2D project with one command: `curl -fsSL https://nova2d.dev/install.sh | bash`.

Script flow: detect OS → check curl + Love2D → download from GitHub → create project → install deps → welcome message.
