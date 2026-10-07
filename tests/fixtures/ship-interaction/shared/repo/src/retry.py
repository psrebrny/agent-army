def record(key, amount, ledger):
    entry = {"id": len(ledger) + 1, "key": key, "amount": amount}
    ledger.append(entry)
    return entry
