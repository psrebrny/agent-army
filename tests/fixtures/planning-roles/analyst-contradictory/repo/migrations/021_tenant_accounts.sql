CREATE TABLE accounts (
    tenant_id TEXT NOT NULL,
    account_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    PRIMARY KEY (tenant_id, account_id)
);
