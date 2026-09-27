"""Convenience wrapper for the audited ladder fixtures; use the generic adapter for a new topology."""
import argparse,os,sys
from pathlib import Path
p=Path(__file__).resolve().parent
sys.path.insert(0,str(p.parents[1]/'Adapters'))
from TropicalMonteCarlo import main
if __name__=='__main__':
    # Usage: run_feyntrop.py top NEW_OUTPUT --samples ... --seed ... --executable ...
    if len(sys.argv)<2 or sys.argv[1] not in ('top','boundary','boundary_merged','oneloop'):
        raise SystemExit('First argument must be top, boundary, boundary_merged or oneloop')
    sys.argv[1]=str(p/(sys.argv[1]+'-input.json'))
    raise SystemExit(main())
