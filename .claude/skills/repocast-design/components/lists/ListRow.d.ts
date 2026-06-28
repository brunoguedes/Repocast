import { ReactNode, CSSProperties } from "react";

/**
 * @startingPoint section="Lists" subtitle="iOS grouped list row — icon, value, accessory" viewport="700x240"
 */
export interface ListRowProps {
  title: ReactNode;
  subtitle?: ReactNode;
  /** Trailing value text (right-aligned, secondary color). */
  value?: ReactNode;
  /** Lucide icon name, or any node, for the leading slot. */
  icon?: string | ReactNode;
  /** Tint of a bare leading icon. @default "var(--tint)" */
  iconColor?: string;
  /** If set, the icon sits in a rounded color tile (Settings style). */
  iconBg?: string;
  /** "disclosure" chevron, "checkmark", or a custom node (e.g. a Toggle). */
  accessory?: "disclosure" | "checkmark" | ReactNode;
  /** Extra trailing node placed before the accessory. */
  trailing?: ReactNode;
  /** Omit the bottom hairline (last row in a section). @default false */
  last?: boolean;
  /** Render the title in destructive red. @default false */
  destructive?: boolean;
  onClick?: () => void;
  style?: CSSProperties;
}

/**
 * One row in an iOS grouped list / Form. Compose inside a `Card`.
 */
export function ListRow(props: ListRowProps): JSX.Element;
