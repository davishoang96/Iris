import React from "react";

interface IconProps {
  size?: number;
  style?: React.CSSProperties;
  className?: string;
}

interface StarProps extends IconProps {
  filled?: boolean;
}

function Svg({ children, size = 18, style, className, ...rest }: IconProps & { children: React.ReactNode }) {
  return (
    <svg
      viewBox="0 0 20 20"
      width={size}
      height={size}
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      style={style}
      className={className}
      {...rest}
    >
      {children}
    </svg>
  );
}

export const IconRotateLeft = (p: IconProps) => (
  <Svg {...p}>
    <path d="M4.2 9.5a6 6 0 1 1 .9 4.3" />
    <path d="M4 5.5v4h4" />
  </Svg>
);

export const IconRotateRight = (p: IconProps) => (
  <Svg {...p}>
    <path d="M15.8 9.5a6 6 0 1 0-.9 4.3" />
    <path d="M16 5.5v4h-4" />
  </Svg>
);

export const IconFlipH = (p: IconProps) => (
  <Svg {...p}>
    <path d="M10 3v14" strokeDasharray="1.5 2" />
    <path d="M3.5 6.5l4 3.5-4 3.5z" />
    <path d="M16.5 6.5l-4 3.5 4 3.5z" />
  </Svg>
);

export const IconFlipV = (p: IconProps) => (
  <Svg {...p}>
    <path d="M3 10h14" strokeDasharray="1.5 2" />
    <path d="M6.5 3.5l3.5 4 3.5-4z" />
    <path d="M6.5 16.5l3.5-4 3.5 4z" />
  </Svg>
);

export const IconCrop = (p: IconProps) => (
  <Svg {...p}>
    <path d="M5 2.5v12.5h12.5" />
    <path d="M2.5 5h12.5v12.5" />
  </Svg>
);

export const IconStraighten = (p: IconProps) => (
  <Svg {...p}>
    <path d="M2.5 13.5l11-11 4 4-11 11z" />
    <path d="M11 5l1.5 1.5M8.5 7.5L10 9M6 10l1.5 1.5M3.5 12.5L5 14" />
  </Svg>
);

export const IconFit = (p: IconProps) => (
  <Svg {...p}>
    <path d="M3 7V3h4M17 7V3h-4M3 13v4h4M17 13v4h-4" />
  </Svg>
);

export const IconOneToOne = (p: IconProps) => (
  <Svg {...p}>
    <text
      x="10" y="14"
      textAnchor="middle"
      fontSize="9"
      fontFamily="ui-sans-serif, sans-serif"
      fontWeight="600"
      fill="currentColor"
      stroke="none"
    >
      1:1
    </text>
  </Svg>
);

export const IconFill = (p: IconProps) => (
  <Svg {...p}>
    <rect x="3" y="3" width="14" height="14" rx="1.5" />
    <rect x="6" y="6" width="8" height="8" rx="0.5" fill="currentColor" stroke="none" opacity=".25" />
  </Svg>
);

export const IconZoomOut = (p: IconProps) => (
  <Svg {...p}>
    <circle cx="9" cy="9" r="5" />
    <path d="M13 13l4 4M6.5 9h5" />
  </Svg>
);

export const IconZoomIn = (p: IconProps) => (
  <Svg {...p}>
    <circle cx="9" cy="9" r="5" />
    <path d="M13 13l4 4M6.5 9h5M9 6.5v5" />
  </Svg>
);

export const IconShare = (p: IconProps) => (
  <Svg {...p}>
    <path d="M10 13V3M6.5 6.5L10 3l3.5 3.5" />
    <path d="M4.5 11v5a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-5" />
  </Svg>
);

export const IconInfo = (p: IconProps) => (
  <Svg {...p}>
    <circle cx="10" cy="10" r="7" />
    <path d="M10 9.5v4.5M10 6.5v.5" />
  </Svg>
);

export const IconSlideshow = (p: IconProps) => (
  <Svg {...p}>
    <rect x="2.5" y="4" width="15" height="10" rx="1.5" />
    <path d="M8.5 7.5v3l3-1.5z" fill="currentColor" stroke="none" />
    <path d="M5 16.5h10" />
  </Svg>
);

export const IconChevron = (p: IconProps) => (
  <Svg {...p}>
    <path d="M7.5 5l5 5-5 5" />
  </Svg>
);

export const IconFolder = (p: IconProps) => (
  <Svg {...p}>
    <path d="M2.5 6a1.5 1.5 0 0 1 1.5-1.5h3l1.5 1.5h7A1.5 1.5 0 0 1 17 7.5v7A1.5 1.5 0 0 1 15.5 16h-11A1.5 1.5 0 0 1 3 14.5z" />
  </Svg>
);

export const IconStar = ({ filled, ...p }: StarProps) => (
  <Svg {...p}>
    <path
      d="M10 3l2.2 4.5 5 .7-3.6 3.5.85 5L10 14.4l-4.45 2.3.85-5L2.8 8.2l5-.7z"
      fill={filled ? "currentColor" : "none"}
    />
  </Svg>
);

export const IconSearch = (p: IconProps) => (
  <Svg {...p}>
    <circle cx="9" cy="9" r="5" />
    <path d="M13 13l4 4" />
  </Svg>
);
