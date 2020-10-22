#!/bin/bash

for i in `seq 0 12`
do
  echo "[$i]" ` date '+%y/%m/%d %H:%M:%S'` "connected."
  open https://colab.research.google.com/drive/1pMfOZRqvISrw1anQnFU32-VBZVB5R7c8?hl=ja#scrollTo=7oXpOnT3ulW5
  sleep 3600
done
