#!/bin/bash

DEVICE=$1

d=$(date +%Y%m%d)

FILENAME="lineage-20.0-${d}-UNOFFICIAL-${DEVICE}.zip"

oldd=$(grep "filename" $DEVICE.json | cut -d '-' -f 3)
md5=$(md5sum ../out/target/product/$DEVICE/$FILENAME | cut -d ' ' -f 1)
oldmd5=$(grep '"id"' $DEVICE.json | cut -d':' -f 2)
utc=$(grep ro.build.date.utc ../out/target/product/$DEVICE/system/build.prop | cut -d '=' -f 2)
oldutc=$(grep "datetime" $DEVICE.json | cut -d ':' -f 2)
size=$(wc -c ../out/target/product/$DEVICE/$FILENAME | cut -d ' ' -f 1)
oldsize=$(grep "size" $DEVICE.json | cut -d ':' -f 2)
oldurl=$(grep "url" $DEVICE.json | cut -d ':' -f 2-3)

# Generate the Changelog
echo "" > changelog.txt

for repo in $(find .. -name .git ! -path "../Lineage-OTA/*")
do
    if [[ $(git --git-dir "${repo}" log --since="${oldutc}") ]];
    then
    	echo "########################################" >> changelog.txt
    	echo "${repo} Changes:" >> changelog.txt
    	git --git-dir "${repo}" log --since="${oldutc}" >> changelog.txt
    fi
done

echo "########################################" >> changelog.txt

#Update $DEVICE.json
TAG=$(echo "${DEVICE}-${d}")
url="https://github.com/ChzeRub/Lineage-20.0/releases/download/${TAG}/${FILENAME}"
sed -i "s!${oldurl}! \"${url}\",!g" $DEVICE.json

sed -i "s!${oldmd5}! \"${md5}\",!g" $DEVICE.json
sed -i "s!${oldutc}! \"${utc}\",!g" $DEVICE.json
sed -i "s!${oldsize}! \"${size}\",!g" $DEVICE.json
sed -i "s!${oldd}!${d}!" $DEVICE.json

git add $DEVICE.json
git commit -m "lineage-20.0-${d}-UNOFFICIAL-${DEVICE}"
git push

hub release create -a ../out/target/product/$DEVICE/$FILENAME -a changelog.txt -m "${TAG}" "${TAG}"
