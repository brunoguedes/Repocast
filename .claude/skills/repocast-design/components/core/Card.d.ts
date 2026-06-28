import { ReactNode, CSSProperties } from "react";

/**
 * @startingPoint section="Core" subtitle="iOS grouped / elevated card container" viewport="700x200"
 */
export interface CardProps {
  children?: ReactNode;
  /** @default "grouped" */
  variant?: "grouped" | "plain" | "elevated";
  /** Small uppercase caption above the card (grouped-section header). */
  header?: ReactNode;
  /** Small caption below the card (grouped-section footer / help text). */
  footer?: ReactNode;
  /** Add internal padding (off by default so ListRows sit flush). @default false */
  padded?: boolean;
  style?: CSSProperties;
}

/**
 * iOS grouped container. Wrap ListRows in a `grouped` card for the inset
 * Settings/Form look; use `elevated` for a floating tile.
 */
export function Card(props: CardProps): JSX.Element;
