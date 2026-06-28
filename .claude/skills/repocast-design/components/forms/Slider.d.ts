import { CSSProperties } from "react";

export interface SliderProps {
  value?: number;
  min?: number;
  max?: number;
  step?: number;
  onChange?: (value: number) => void;
  /** Lucide icon left of the track (e.g. "turtle"). */
  minIcon?: string;
  /** Lucide icon right of the track (e.g. "rabbit"). */
  maxIcon?: string;
  disabled?: boolean;
  style?: CSSProperties;
}

/** iOS slider with tint fill + white knob; optional flanking icons. Controlled. */
export function Slider(props: SliderProps): JSX.Element;
