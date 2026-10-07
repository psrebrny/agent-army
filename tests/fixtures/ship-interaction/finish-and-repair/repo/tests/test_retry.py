import unittest
from src.retry import record


class RetryTests(unittest.TestCase):
    def test_first_request(self):
        ledger = []
        result = record("a", 100, ledger)
        self.assertEqual(result["amount"], 100)
        self.assertEqual(len(ledger), 1)

    def test_identical_retry(self):
        ledger = []
        first = record("a", 100, ledger)
        again = record("a", 100, ledger)
        self.assertEqual(len(ledger), 1)
        self.assertEqual(again["id"], first["id"])
