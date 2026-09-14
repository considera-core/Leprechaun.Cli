import { ConvertStateToData } from '../../../core/functions/ConvertStateToData';
import { GetDistinct } from '../../../core/functions/GetDistinct';
import { IPrimitiveFieldData } from '../interfaces/IPrimitiveFieldData';
import { IPrimitiveFieldPlaygroundToggleState } from '../interfaces/IPrimitiveFieldPlaygroundToggleState';
import { PrimitiveFieldStateType } from '../interfaces/PrimitiveFieldStateType';
import { GetPrimitiveFieldSignalField } from './GetPrimitiveFieldSignalField';
import { IsSignalTrue } from '../../../core/functions/IsSignalTrue';
import { PrimitiveFieldProperties } from '../constants/PrimitiveFieldProperties';

/**
 * Generates the component class backing {@link ConvertPrimitiveFieldPlaygroundConfigToHtml}. Dynamic inputs
 * get a backing signal, static enum inputs get a class member for their template reference, and imports are
 * only emitted when something actually uses them.
 */
export function GetPrimitiveFieldTsCode(
  valuesState: PrimitiveFieldStateType<string>,
  includeState: IPrimitiveFieldPlaygroundToggleState,
  dynamicState: IPrimitiveFieldPlaygroundToggleState,
): string {
  const valuesData = ConvertStateToData(valuesState, PrimitiveFieldProperties) as IPrimitiveFieldData;
  const included = PrimitiveFieldProperties.filter(property => IsSignalTrue(includeState[property.key as keyof IPrimitiveFieldPlaygroundToggleState]));
  const dynamicProperties = included.filter(property => IsSignalTrue(dynamicState[property.key as keyof IPrimitiveFieldPlaygroundToggleState]));
  const staticProperties = included.filter(property => !IsSignalTrue(dynamicState[property.key as keyof IPrimitiveFieldPlaygroundToggleState]));

  // Every included enum needs its import; only static enum bindings reference the class member.
  const enumImports = GetDistinct(included.filter(property => property.kind === 'enum').map(property => property.enumName ?? ''));
  const staticEnumMembers = GetDistinct(staticProperties.filter(property => property.kind === 'enum').map(property => property.enumName ?? ''));
  const needsSignal = dynamicProperties.length > 0;
  const needsSelectOption = dynamicProperties.some(property => property.kind === 'selectOptions');

  const angularImports = ['ChangeDetectionStrategy', 'Component', ...(needsSignal ? ['signal'] : [])];
  const extensionImports = ['PrimitiveFieldComponent', ...enumImports];

  const importLines = [
    `import { ${angularImports.join(', ')} } from '@angular/core';`,
    `import { ${extensionImports.join(', ')} } from '@consideracore/angular-extensions';`,
    ...(needsSelectOption ? [`import { ISelectOption } from '@tylertech/forge';`] : []),
  ];

  const bodyDeclarations = [
    ...staticEnumMembers.map(enumName => `  protected readonly ${enumName} = ${enumName};`),
    ...dynamicProperties.map(property => GetPrimitiveFieldSignalField(property, valuesData, valuesState)),
  ];

  const classBody = bodyDeclarations.length > 0 ? `\n${bodyDeclarations.join('\n\n')}\n` : '';

  return [
    ...importLines,
    ``,
    `@Component({`,
    `  selector: 'app-primitive-field-example',`,
    `  templateUrl: './primitive-field-example.component.html',`,
    `  styleUrl: './primitive-field-example.component.scss',`,
    `  changeDetection: ChangeDetectionStrategy.OnPush,`,
    `  imports: [PrimitiveFieldComponent],`,
    `})`,
    `export class PrimitiveFieldExampleComponent {${classBody}}`,
  ].join('\n');
}
