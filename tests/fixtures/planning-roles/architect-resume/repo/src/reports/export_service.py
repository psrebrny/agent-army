def build_failed_invoice_csv(owner_id: str, start_date: date, end_date: date) -> bytes:
    authorization.require_finance_owner(owner_id)
    rows = invoice_repository.failed_for_owner(owner_id, start_date, end_date)
    return csv_writer.encode(rows)
