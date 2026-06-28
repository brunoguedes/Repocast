import { ReactNode, CSSProperties } from "react";

/**
 * @startingPoint section="Core" subtitle="iOS button — filled, tinted, gray, plain, destructive" viewport="700x150"
 */
export interface ButtonProps {
  children?: ReactNode;
  /** Apple button prominence. @default "filled" */
  variant?: "filled" | "tinted" | "gray" | "plain" | "destructive";
  /** @default "medium" */
  size?: "small" | "medium" | "large";
  /** Capsule (pill) or continuous-rounded rect. @default "rounded" */
  shape?: "rounded" | "capsule";
  /** Lucide icon name (SF Symbol substitute). */
  icon?: string;
  /** Place the icon after the label. @default false */
  iconTrailing?: boolean;
  /** @default false */
  fullWidth?: boolean;
  /** @default false */
  disabled?: boolean;
  onClick?: () => void;
  style?: CSSProperties;
}

/**
 * iOS-style button with Apple's prominence variants and UIKit-like press
 * feedback. Use `filled` for the primary action, `plain` for nav-bar text
 * actions ("Cancel" / "Generate"), `destructive` for delete.
 */
export function Button(props: ButtonProps): JSX.Element;
