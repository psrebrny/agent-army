@router.get("/finance/reports/failed-invoices.csv")
def download_failed_invoices_csv(request: Request, start: date, end: date) -> Response:
    return attachment(build_failed_invoice_csv(request.owner_id, start, end))
