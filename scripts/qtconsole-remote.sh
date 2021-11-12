#!/bin/bash
scp john-vision:/home/sam/.jupyter/kernel-config-sam.json ~/.jupyter/kernel-config-sam.json
jupyter qtconsole --ssh=john-vision --existing ~/.jupyter/kernel-config-sam.json
