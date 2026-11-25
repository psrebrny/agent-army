import { notify } from '../../shared/notify';

export const columns = [
  { id: 'name', header: 'Name' },
  { id: 'createdAt', header: 'Created' },
];

export function EventDefinitionsTable({ rows, error }: { rows: Row[]; error?: Error }) {
  if (error) notify.error('Could not load event definitions');
  return <Table columns={columns} rows={rows} />;
}
