def record(key, amount, ledger):
    for entry in ledger:
        if entry["key"] == key and entry["amount"] == amount:
            return entry
    entry = {"id": len(ledger) + 1, "key": key, "amount": amount}
    ledger.append(entry)
    return entry
