import { EventDefinitionsTable } from './EventDefinitionsTable';
import { useEventDefinitions } from './useEventDefinitions';

export function EventDefinitionsContent() {
  const { rows, error } = useEventDefinitions();
  return <EventDefinitionsTable rows={rows} error={error} />;
}
