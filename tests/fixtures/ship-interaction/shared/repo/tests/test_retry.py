import unittest
from src.retry import record


class RetryTests(unittest.TestCase):
    def test_first_request(self):
        ledger = []
        result = record("a", 100, ledger)
        self.assertEqual(result["amount"], 100)
        self.assertEqual(len(ledger), 1)
