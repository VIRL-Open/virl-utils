curl -X POST \
-u guest:guest -v \
 --header "Content-Type:text/xml;charset=UTF-8" \
--data @square.virl \
http://devnet:19399/simengine/rest/launch?session=square2
