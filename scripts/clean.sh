#!/bin/bash
find . -type f \( \
    -name "xelab.*" \
    -o -name "xsim.*" \
    -o -name "xvlog.*" \
    -o -name "*.jou" \
    -o -name "*.log" \
    -o -name "*.pb" \
    -o -name "*.backup.*" \
    -o -name "*.wdb" \
\) -delete

find . -type d -name "xsim.dir" -exec rm -rf {} +

# waveform
# find . -type f \( -name "*.vcd" -o -name "*.vpd" \) -delete

echo "Done"