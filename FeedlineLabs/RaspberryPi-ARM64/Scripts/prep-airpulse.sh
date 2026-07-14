#!/bin/bash
set -e

cd ~/airpulse 
sed -i '1s/^\xEF\xBB\xBF//' Scripts/*.sh 
sed -i 's/\r$//' Scripts/*.sh

echo "Preparing AirPulse install folder..."

mkdir -p "$HOME/airpulse"

cd "$HOME/airpulse"

echo "Setting executable permissions..."

chmod +x AirPulse.Updater
chmod +x Scripts/*.sh

echo "AirPulse folder ready:"
pwd

echo "Contents:"
ls -la

echo "Scripts:"
ls -la Scripts

echo "Done."