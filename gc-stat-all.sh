#!/bin/bash

################################################################################
# Java GC statistics shell scripts.
# Bridge Chen
# Shenzhen, China
# 2020-10-24
###############################################################################

jcmd | grep -v sun.tools.jcmd.JCmd | cut -d ' ' -f 1 | xargs -i -t gc-stat.sh {}
