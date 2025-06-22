#!/bin/bash

# Conda activation helper script
# Usage: source /opt/ai-dock/bin/conda-activate.sh [environment_name]

if [ -z "$1" ]; then
    echo "Usage: source $0 [environment_name]"
    echo "Available environments:"
    conda env list
    return 1
fi

# Initialize conda if not already done
if ! command -v conda &> /dev/null; then
    export PATH="/opt/miniconda/bin:$PATH"
    source /opt/miniconda/etc/profile.d/conda.sh
fi

# Activate the specified environment
conda activate "$1"

echo "Activated conda environment: $1"
echo "Python path: $(which python)"
echo "Python version: $(python --version)"
