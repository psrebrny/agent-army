# Operations notes

- Hosting: one managed app server and a managed Postgres database.
- Backups: automatic daily database backups are enabled (provider default, 7-day retention).
  We have never restored one.
- Payments: card payments through a payment provider; failed-payment emails are the provider's defaults.
- Monitoring: none yet; errors go to the server log.
- Support: contact form sends to the founder's inbox.
- Cancellation: users email us and we cancel by hand.
