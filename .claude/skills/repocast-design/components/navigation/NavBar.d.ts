import { ReactNode, CSSProperties } from "react";

export interface NavBarProps {
  title?: ReactNode;
  /** Render the big left-aligned large title below the bar. @default false */
  largeTitle?: boolean;
  /** Leading nav action(s) — typically a plain Button. */
  leading?: ReactNode;
  /** Trailing nav action(s). */
  trailing?: ReactNode;
  style?: CSSProperties;
}

/** Frosted iOS navigation bar with inline or large title + leading/trailing actions. */
export function NavBar(props: NavBarProps): JSX.Element;
