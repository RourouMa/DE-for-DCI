"""Independent dense-field oracle for the optional sparse row selector."""
import importlib.util
from pathlib import Path
import random
import unittest

spec = importlib.util.spec_from_file_location(
    "coefficient_provenance",
    Path(__file__).resolve().parents[1] / "Adapters" / "coefficient_provenance.py")
selector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selector)


def reference(matrix, columns, prime, targets):
    a = [[v % prime for v in row] for row in matrix]
    rank, pivots = 0, []
    for col in range(columns):
        candidate = next((i for i in range(rank, len(a)) if a[i][col]), None)
        if candidate is None:
            continue
        a[rank], a[candidate] = a[candidate], a[rank]
        inv = pow(a[rank][col], -1, prime)
        a[rank] = [v*inv % prime for v in a[rank]]
        for i in range(len(a)):
            if i != rank:
                factor = a[i][col]
                a[i] = [(u-factor*v) % prime for u, v in zip(a[i], a[rank])]
        pivots.append(col)
        rank += 1
    forms = []
    for target in targets:
        form = [int(c == target-1) for c in range(columns)]
        for pivot, row in zip(pivots, a):
            factor = form[pivot]
            form = [(u-factor*v) % prime for u, v in zip(form, row)]
        forms.append([[c+1, value] for c, value in enumerate(form) if value])
    return rank, forms


def payload(matrix, nc, prime, targets):
    return dict(Rows=len(matrix), Columns=nc, Targets=targets, Samples=[dict(
        Prime=prime, Entries=[[i+1, j+1, v] for i, row in enumerate(matrix)
                             for j, v in enumerate(row) if v])])


class CoefficientProvenanceTests(unittest.TestCase):
    def test_random_dense_oracle_and_selected_span(self):
        rng = random.Random(260926)
        for prime in (2, 101, 42013):
            for case in range(45):
                nr, nc = rng.randrange(0, 14), rng.randrange(1, 12)
                matrix = [[rng.randrange(-4, 5) if rng.random() < .32 else 0
                           for _ in range(nc)] for _ in range(nr)]
                if nr > 3:
                    matrix[-1] = [u+v for u, v in zip(matrix[0], matrix[1])]
                targets = rng.sample(range(1, nc+1), rng.randrange(nc+1))
                with self.subTest(prime=prime, case=case):
                    data = payload(matrix, nc, prime, targets)
                    data["ShortRowsFirst"] = bool(case % 2)
                    result = selector.select_rows(data)
                    rank, forms = reference(matrix, nc, prime, targets)
                    selected = [matrix[i-1] for i in result["Rows"]]
                    self.assertEqual(result["Rank"], rank)
                    self.assertEqual(result["TargetNormalForms"], forms)
                    self.assertEqual(reference(selected, nc, prime, targets)[1], forms)
                    self.assertTrue(result["AllOriginalRowCertificatesChecked"])

    def test_source_constraint_and_free_target(self):
        # g - b1 = 0, b1 - 3*b2 = 0. Source-only rows must survive.
        data = payload([[1, -1, 0], [0, 1, -3]], 3, 101, [1, 3])
        result = selector.select_rows(data)
        self.assertEqual(result["Rows"], [1, 2])
        self.assertEqual(result["TargetNormalForms"], [[[3, 3]], [[3, 1]]])

    def test_duplicate_entries_accumulate(self):
        data = payload([[1, 0]], 2, 101, [1])
        data["Samples"][0]["Entries"].extend([[1, 1, -1], [1, 2, 3]])
        result = selector.select_rows(data)
        self.assertEqual(result["Rows"], [])
        self.assertEqual(result["TargetNormalForms"], [[[1, 1]]])

    def test_bad_field_and_coordinates(self):
        for prime in (0, 1, 9, 42013.0):
            with self.assertRaises(ValueError):
                selector.select_rows(payload([[1]], 1, prime, [1]))
        with self.assertRaises(ValueError):
            selector.select_rows(payload([[1]], 1, 101, [2]))

    def test_aggregate_selected_span_against_dense_oracle(self):
        rng = random.Random(92626)
        for case in range(45):
            nr, nc = rng.randrange(0, 14), rng.randrange(1, 12)
            matrix = [[rng.randrange(-4, 5) if rng.random() < .32 else 0
                       for _ in range(nc)] for _ in range(nr)]
            targets = rng.sample(range(1, nc+1), rng.randrange(nc+1))
            with self.subTest(case=case):
                data = payload(matrix, nc, 42013, targets)
                data["ShortRowsFirst"] = bool(case % 2)
                result = selector.select_aggregate_rows(data)
                rank, forms = reference(matrix, nc, 42013, targets)
                selected = [matrix[i-1] for i in result["Rows"]]
                self.assertEqual(result["Rank"], rank)
                self.assertEqual(reference(selected, nc, 42013, targets)[1], forms)
                self.assertTrue(result["AggregateIdentitiesChecked"])
                self.assertTrue(result["FullPhysicalTargetVerificationRequired"])
                self.assertFalse(result["AllOriginalRowCertificatesChecked"])

    def test_aggregate_cancellation_is_not_a_target_certificate(self):
        # Modulo 2 both random weights are necessarily 1: the combination
        # g1+g2 needs only row 1, whereas either physical target needs row 2.
        matrix = [[1, 1, 0], [0, 1, 1]]
        result = selector.select_aggregate_rows(payload(matrix, 3, 2, [1, 2]))
        self.assertEqual(result["Rows"], [1])
        self.assertTrue(result["AggregateIdentitiesChecked"])
        self.assertFalse(result["AllOriginalRowCertificatesChecked"])
        self.assertNotEqual(reference([matrix[0]], 3, 2, [1, 2])[1],
                            reference(matrix, 3, 2, [1, 2])[1])

    def test_aggregate_invalid_options(self):
        data = payload([[1]], 1, 101, [1])
        for trials in (0, -1, 33, 2.0):
            with self.assertRaises(ValueError):
                selector.select_aggregate_rows(data, trials=trials)
        with self.assertRaises(ValueError):
            selector.select_aggregate_rows(payload([[1]], 1, 9, [1]))


if __name__ == "__main__":
    unittest.main()
