#!/bin/bash

#servers=$(<test)
servers=$(terraform output -json)

for x in `echo ${servers} | jq -r 'keys | .[]' | grep -v _ip`;
do 
   length=$(echo ${servers} | jq -r ".${x}.value[] | length") 
   counter=0
   while [ $counter -lt $length ];
   do
     line=$(echo ${servers} | jq -r ".${x}_ip.value[][${counter}],.${x}.value[][${counter}]" | tr '\n' ' ')
     echo ${line} 
     counter=$(( $counter + 1 ))
   done
done


