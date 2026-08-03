#!/usr/bin/env bash
set -e

cd ~/projects/canonical_policy

MUJOCO_GL=osmesa \
PYTHONUNBUFFERED=1 \
python canonical_policy/scripts/dataset_states_to_obs.py \
  --input data/robomimic/datasets/stack_d1/stack_d1.hdf5 \
  --output data/robomimic/datasets/stack_d1/stack_d1_voxel_test.hdf5 \
  --num_workers=1 \
  --n=1
