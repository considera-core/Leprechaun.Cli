/**
 * Returns the input values in first-seen order with duplicates and empty strings removed.
 */
export function GetDistinct(values: string[]): string[] {
  return values.filter((value, index) => !!value && values.indexOf(value) === index);
}
