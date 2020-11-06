#!/bin/bash
echo "warning: remove all version objects and folder you specified!!"
echo "execute this shell by ./S3-remove-all-versioned-folder.sh bucketname prefixname/, place / with folder name to distinguish"
bucket=$1
prefix=$2
SRCFN1=_DUMP_FILE1_
SRCFN2=_DUMP_FILE2_
FN=/tmp/_TMP_DELETE

lastword=`echo $prefix | cut -c $((${#prefix}))`
if [ "$lastword" != "/" ];then
echo "you must place folder name end with /"
exit 1
fi

aws s3api list-object-versions --bucket $bucket --prefix $prefix --query "[Versions,DeleteMarkers][].{Key: Key, VersionId: VersionId}" > $SRCFN1

rm $FN 2> /dev/null
s=0
c=`grep -c VersionId $SRCFN1`

while [ $s -lt $c ]
do
	((e=s+999))
	echo taking $s to $e
	(echo -n '{"Objects":';jq ".[$s:$e]" < $SRCFN1 2>&1 | sed 's#]$#] , "Quiet":true}#') > $FN
	aws s3api delete-objects --bucket $bucket --delete file://$FN && rm $FN
	((s=e+1))
	sleep 1
	echo s is $s and e is $e
	echo -n "."
done
### confirm deletion is clean
echo "confirm deletion is clean and run delete again"

aws s3api list-object-versions --bucket $bucket --prefix $prefix --query "[Versions,DeleteMarkers][].{Key: Key, VersionId: VersionId}" > $SRCFN2

rm $FN 2> /dev/null
s=0
c=`grep -c VersionId $SRCFN2`

while [ $s -lt $c ]
do
	((e=s+999))
	echo taking $s to $e
	(echo -n '{"Objects":';jq ".[$s:$e]" < $SRCFN2 2>&1 | sed 's#]$#] , "Quiet":true}#') > $FN
	aws s3api delete-objects --bucket $bucket --delete file://$FN && rm $FN
	((s=e+1))
	sleep 1
	echo s is $s and e is $e
	echo -n "."
done