#!/bin/bash

if [[ -v VBAN_HOST ]] && [[ -v VBAN_PORT ]] && [[ -v VBAN_STREAMNAME ]]; then
    while true; do vban_receptor -i$VBAN_HOST -p$VBAN_PORT -s$VBAN_STREAMNAME; done &
fi
