import { PrimitiveValueType } from '../PrimitiveValueType';

export function NumberizeString(value: PrimitiveValueType, decimals: number): string {
  const stringValue = `${value}`;
  const trimmedValue = stringValue.trim();
  const numericValue = Number(trimmedValue);

  if (trimmedValue === '' || Number.isNaN(numericValue)) {
    return stringValue;
  }

  return numericValue.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}
