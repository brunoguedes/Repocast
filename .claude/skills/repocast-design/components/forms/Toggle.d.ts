import { CSSProperties } from "react";

export interface ToggleProps {
  checked?: boolean;
  onChange?: (next: boolean) => void;
  disabled?: boolean;
  style?: CSSProperties;
}

/** iOS switch — green when on. Controlled. */
export function Toggle(props: ToggleProps): JSX.Element;
