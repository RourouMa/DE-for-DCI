"""Heuristic modular dependency selection; symbolic verification is mandatory."""
import json
from pathlib import Path
import sys
import time

def select(sample, targets, nrows):
    prime = sample['Prime']
    rows = [dict() for _ in range(nrows)]
    for r, c, value in sample['Entries']:
        if value % prime:
            rows[r-1][c-1] = value % prime
    pivots = {}
    for index in sorted(range(nrows), key=lambda i: (len(rows[i]), i)):
        row, provenance = rows[index].copy(), {index}
        while row:
            col = min(row)
            factor = row[col]
            if col not in pivots:
                inverse = pow(factor, -1, prime)
                pivots[col] = ({c: v*inverse % prime for c, v in row.items()}, provenance)
                break
            other, dependencies = pivots[col]
            provenance.update(dependencies)
            for c, value in other.items():
                result = (row.get(c, 0)-factor*value) % prime
                if result:
                    row[c] = result
                else:
                    row.pop(c, None)
    needed, visited, stack = set(), set(), [i-1 for i in targets]
    while stack:
        col = stack.pop()
        if col in visited or col not in pivots:
            continue
        visited.add(col)
        row, provenance = pivots[col]
        needed.update(provenance)
        stack.extend(c for c in row if c != col and c in pivots)
    return needed, len(pivots)

def main():
    source, destination = map(Path, sys.argv[1:3])
    data = json.loads(source.read_text())
    needed, reports = set(), []
    for sample in data['Samples']:
        started = time.monotonic()
        selected, rank = select(sample, data['Targets'], data['Rows'])
        needed.update(selected)
        reports.append(dict(Prime=sample['Prime'], Rank=rank, SelectedRows=len(selected),
                            Seconds=time.monotonic()-started))
    for sample, report in zip(data['Samples'], reports):
        subset = dict(sample, Entries=[entry for entry in sample['Entries'] if entry[0]-1 in needed])
        _, subset_rank = select(subset, [], data['Rows'])
        report['SelectedRank'] = subset_rank
    destination.write_text(json.dumps(dict(Rows=[i+1 for i in sorted(needed)], Samples=reports)))

if __name__ == '__main__':
    main()
