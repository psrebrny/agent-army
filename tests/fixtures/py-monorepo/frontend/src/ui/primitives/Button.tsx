// Design-system primitive. Feature components must use THIS, never a raw <button>.
import type { ReactNode } from "react";

export function Button({ onClick, children }: { onClick: () => void; children: ReactNode }) {
  return (
    <button className="ds-button" onClick={onClick}>
      {children}
    </button>
  );
}
