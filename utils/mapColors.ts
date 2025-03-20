export function rgbToHex(rgb: [number, number, number]): string {
  return (
    '#' +
    rgb
      .map((component) => {
        const hex = component.toString(16);
        return hex.length === 1 ? '0' + hex : hex;
      })
      .join('')
  );
}

const colorPaletteHex = ['#9FEE6B'];

export const getColorById = (id: number) => {
  const index = id % colorPaletteHex.length;
  return colorPaletteHex[index];
};
