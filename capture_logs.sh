#!/bin/bash

set -e

echo "Loading test.env"
. test.env || true

i=1
for p in "$PREFIX" "$PREFIX2" "$PREFIX3"; do
    $p journalctl > node${i}.log
    (( i=i+1 ))
done
