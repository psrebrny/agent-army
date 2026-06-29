// Feature component. Law: design-system primitives only; data via props, no fetch here.
import { Button } from "../ui/primitives/Button";

export function TransferForm({ onSubmit }: { onSubmit: (amount: number) => void }) {
  return (
    <form>
      <Button onClick={() => onSubmit(100)}>Send</Button>
    </form>
  );
}
