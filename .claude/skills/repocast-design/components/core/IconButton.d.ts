import { CSSProperties } from "react";

export interface IconButtonProps {
  /** Lucide icon name (SF Symbol substitute). */
  icon: string;
  /** @default "medium" */
  size?: "small" | "medium" | "large";
  /** @default "plain" */
  prominence?: "plain" | "tinted" | "gray" | "filled";
  /** @default "circle" */
  shape?: "circle" | "rounded";
  /** Accessible label (aria-label). */
  label?: string;
  disabled?: boolean;
  onClick?: () => void;
  style?: CSSProperties;
}

/**
 * Icon-only button for toolbars and transport controls. `filled` gives the
 * tinted-circle treatment used by the big play/pause control.
 */
export function IconButton(props: IconButtonProps): JSX.Element;
