#! /bin/bash

POST -ec 'text/xml' http://localhost:3333 < protocol/inform.xml
echo -e "\n\n"
#POST -c 'text/xml' http://localhost:3333 < protocol/getrpcmethods.xml
