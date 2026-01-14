#!/bin/bash

./clean.sh

if [ $# -eq 0 ]; then
    echo "Usage: $0 <testbench_name> [commands_file] [snapshot_name]"
    exit 1
fi

TB_NAME=$1
CMDS_FILE=${2:-"sim_build/cmds.f"}  # Changed from sim_builds to sim_build
SNAPSHOT=${3:-"sim"}

# Check if file exists before proceeding
if [ ! -f "$CMDS_FILE" ]; then
    echo "ERROR: Commands file '$CMDS_FILE' not found!"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Convert to absolute path
CMDS_FILE_ABS=$(realpath "$CMDS_FILE")

echo "### COMPILING ###"
echo "Commands file: $CMDS_FILE_ABS"
xvlog -sv -f "$CMDS_FILE_ABS"
if [ $? -ne 0 ]; then
    echo "### COMPILATION FAILED ###"
    exit 10
fi

echo ""
echo "### ELABORATING ###"
xelab $TB_NAME -s $SNAPSHOT
if [ $? -ne 0 ]; then
    echo "### ELABORATION FAILED ###"
    exit 11
fi

echo ""
echo "### RUNNING SIMULATION ###"
xsim $SNAPSHOT -R
if [ $? -ne 0 ]; then
    echo "### SIMULATION FAILED ###"
    exit 12
fi

echo ""
echo "### SIMULATION COMPLETE ###"
