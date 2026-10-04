def test_failed_invoice_export_is_owner_scoped():
    authorization.allow_finance_owner("owner-1")

    csv = build_failed_invoice_csv("owner-1", date(2026, 1, 1), date(2026, 1, 31))

    assert b"invoice-7" in csv
