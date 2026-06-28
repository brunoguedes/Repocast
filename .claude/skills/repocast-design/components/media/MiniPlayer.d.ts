import { CSSProperties } from "react";

/**
 * @startingPoint section="Media" subtitle="Frosted mini-player transport bar" viewport="390x64"
 */
export interface MiniPlayerProps {
  title?: string;
  /** Formatted current time, e.g. "1:23". */
  currentTime?: string;
  /** Formatted total duration, e.g. "12:48". */
  duration?: string;
  playing?: boolean;
  onTogglePlay?: () => void;
  /** Tap the bar (outside the play button) to open Now Playing. */
  onOpen?: () => void;
  style?: CSSProperties;
}

/**
 * Frosted mini-player bar (Apple Podcasts pattern) — sits above the tab bar.
 */
export function MiniPlayer(props: MiniPlayerProps): JSX.Element;
