#!/bin/bash



echo "Copying JS Plugin"

# $1 is the project path passed from Eclipse
cp -r $1/../www $1/assets
cp -r $1/../../www/phonegap $1/assets/www

echo "Done."
echo "Copying Java Plugin"

#cp -r $1/../../android/jp $1/src

echo "Done."