POST -c 'text/xml' http://localhost:3333 < protocol/inform.xml
echo -e "\n\n";
echo | POST -c 'text/xml' http://localhost:3333 
echo -e "\n\n";
POST -c 'text/xml' http://localhost:3333 < protocol/thompson-GetRPCMethodsResponse
