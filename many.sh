#!/bin/zsh

for i in {1..10}; do
  curl -s -XPOST "http://localhost:4001" -d"butt" &
  echo "Started request #$i (PID: $!)"
done

wait
