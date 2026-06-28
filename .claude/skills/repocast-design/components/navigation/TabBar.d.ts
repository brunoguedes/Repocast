import { CSSProperties } from "react";

export interface TabItem {
  value: string | number;
  label: string;
  /** Lucide icon name. */
  icon: string;
}

export interface TabBarProps {
  items: TabItem[];
  value: string | number;
  onChange?: (value: string | number) => void;
  style?: CSSProperties;
}

/** Frosted iOS tab bar; active tab is tinted. Controlled. */
export function TabBar(props: TabBarProps): JSX.Element;
