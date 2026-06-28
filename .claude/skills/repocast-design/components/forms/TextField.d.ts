import { CSSProperties } from "react";

export interface TextFieldProps {
  value?: string;
  onChange?: (value: string) => void;
  placeholder?: string;
  /** Tall TextEditor (New Track sheet). @default false */
  multiline?: boolean;
  rows?: number;
  /** "filled" rounded fill, or "plain" to sit flush in a grouped ListRow. @default "filled" */
  variant?: "filled" | "plain";
  disabled?: boolean;
  style?: CSSProperties;
}

/** iOS text field / multiline editor. Controlled. */
export function TextField(props: TextFieldProps): JSX.Element;
