import { CSSProperties } from "react";

export interface SegmentOption {
  label: string;
  value: string | number;
}

export interface SegmentedControlProps {
  options: SegmentOption[];
  value: string | number;
  onChange?: (value: string | number) => void;
  style?: CSSProperties;
}

/** iOS segmented control with a sliding thumb — e.g. the playback-speed picker. */
export function SegmentedControl(props: SegmentedControlProps): JSX.Element;
