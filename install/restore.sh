#!/bin/bash -x


ls -d /Volumes/Backup*/Backups.backupdb/*/Latest  || exit -1

mkdir ~/restored

sudo tmutil restore /Volumes/Backup*/Backups.backupdb/R/Latest/*/Users/asergeyev/Documents ~/restored/documents
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/R/Latest/*/Users/asergeyev/.config ~/restored/config
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/R/Latest/*/Users/asergeyev/.gnupg ~/restored/gnupg
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/R/Latest/*/Users/asergeyev/.ssh ~/restored/ssh
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/R/Latest/*/Users/asergeyev/projects ~/restored/projects
sudo tmutil restore /Volumes/Backup*/Backups.backupdb/R/Latest/*/Users/asergeyev/Library ~/restored/Library

sudo chown -R "$(id -un):$(id -gn)" ~/restored/* 
