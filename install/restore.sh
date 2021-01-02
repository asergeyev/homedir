#!/bin/bash -x


ls -d /Volumes/Backup*/Backups.backupdb/*/Latest  || exit -1


sudo tmutil restore /Volumes/Backup*/Backups.backupdb/*/Latest/*/Users/asergeyev/projects ~/restored.projects
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/*/Latest/*/etc ~/restored.etc
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/*/Latest/*/Users/asergeyev/Documents ~/restored.documents

sudo tmutil restore /Volumes/Backup*/Backups.backupdb/*/Latest/*/Users/asergeyev/.config ~/restored.config
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/*/Latest/*/Users/asergeyev/.gnupg ~/restored.gnupg

sudo chown -R "$(id -un):$(id -gn)" ~/restored.* 
