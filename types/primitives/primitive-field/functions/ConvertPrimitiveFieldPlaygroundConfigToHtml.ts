import { ConvertStateToData } from '../../../core/functions/ConvertStateToData';
import { PrimitiveFieldProperties } from '../constants/PrimitiveFieldProperties';
import { IPrimitiveFieldData } from '../interfaces/IPrimitiveFieldData';
import { PrimitiveFieldStateType } from '../interfaces/PrimitiveFieldStateType';
import { GetPropertyAttributes } from './GetPropertyAttributes';

/**
 * Generates the template for the configured primitive field. Each input is omitted when it is not included,
 * bound to a signal when it is dynamic, or written as a literal (with an optional `i18n-` marker) otherwise.
 */
export function ConvertPrimitiveFieldPlaygroundConfigToHtml(
  valuesState: PrimitiveFieldStateType<string>,
  includeState: PrimitiveFieldStateType<boolean>,
  dynamicState: PrimitiveFieldStateType<boolean>,
  localizationState: PrimitiveFieldStateType<boolean>,
): string {
  const valuesData = ConvertStateToData(valuesState, PrimitiveFieldProperties) as IPrimitiveFieldData;

  const lines = PrimitiveFieldProperties
    .map(property => GetPropertyAttributes(property, valuesData, valuesState, includeState, dynamicState, localizationState))
    .filter(parts => parts.length > 0)
    .map(parts => `  ${parts.join(' ')}`);

  return `<consideracore-primitive-field\n${lines.join('\n')}\n/>`;
}
