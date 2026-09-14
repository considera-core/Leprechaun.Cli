/**
 * Returns the member name for an enum value (ex: `PrimitiveFieldTypeEnum.Select` for `3`).
 */
export function GetEnumKey(enumObject: object, value: string | number): string {
  const entry = Object.entries(enumObject).find(([key, member]) => member === value && Number.isNaN(Number(key)));
  return entry ? entry[0] : `${value}`;
}
