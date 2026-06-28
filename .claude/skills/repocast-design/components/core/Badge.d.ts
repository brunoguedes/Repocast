import { ReactNode, CSSProperties } from "react";

export interface BadgeProps {
  children?: ReactNode;
  /** System color token name. @default "blue" */
  tint?: "blue" | "green" | "red" | "orange" | "yellow" | "purple" | "indigo" | "teal" | "pink" | "gray";
  /** @default "tinted" */
  variant?: "tinted" | "solid";
  /** Lucide icon name. */
  icon?: string;
  style?: CSSProperties;
}

/** Capsule status pill — track status, source kind, counts. */
export function Badge(props: BadgeProps): JSX.Element;
