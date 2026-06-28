import { ReactNode, CSSProperties } from "react";

export interface SectionHeaderProps {
  children?: ReactNode;
  /** Optional trailing action node (e.g. an "Edit" Button). */
  action?: ReactNode;
  style?: CSSProperties;
}

/** Uppercase grouped-list section header placed above a Card. */
export function SectionHeader(props: SectionHeaderProps): JSX.Element;
