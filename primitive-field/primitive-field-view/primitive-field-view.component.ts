import { booleanAttribute, ChangeDetectionStrategy, Component, computed, input, InputSignal, InputSignalWithTransform, numberAttribute, Signal } from '@angular/core';
import { IconRegistry } from '@tylertech/forge';
import { ForgeCheckboxProxyModule, ForgeCircularProgressModule, ForgeIconModule, ForgeLabelValueModule, ForgeLinearProgressModule, ForgeSkeletonModule, ForgeSwitchModule, ForgeTooltipModule } from '@tylertech/forge-angular';
import { tylIconAttachMoney } from '@tylertech/tyler-icons';
import { PrimitiveFieldDensityEnum } from '../../../../types/primitives/primitive-field/enums/PrimitiveFieldDensityEnum';
import { PrimitiveFieldTypeEnum } from '../../../../types/primitives/primitive-field/enums/PrimitiveFieldTypeEnum';
import { NumberizeString } from '../../../../types/core/functions/NumberizeString';
import { PrimitiveValueType } from '../../../../types/core/PrimitiveValueType';

@Component({
  selector: 'consideracore-primitive-field-view',
  templateUrl: './primitive-field-view.component.html',
  styleUrl: './primitive-field-view.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    ForgeCheckboxProxyModule,
    ForgeCircularProgressModule,
    ForgeIconModule,
    ForgeLabelValueModule,
    ForgeSkeletonModule,
    ForgeSwitchModule,
    ForgeLinearProgressModule,
    ForgeTooltipModule,
  ],
})
export class PrimitiveFieldViewComponent {
  public readonly PrimitiveFieldTypeEnum = PrimitiveFieldTypeEnum;

  /**
   * The field's id suffix.
   * @default 'field'
   * @input
   */
  public readonly idSuffix: InputSignal<string> = input<string>('field');

  /**
   * The field's aria and tooltip description, hidden if description is empty.
   * @default ''
   * @input
   */
  public readonly description: InputSignal<string> = input<string>('');

  /**
   * The field's display label, hidden if label is empty.
   * @default ''
   * @input
   */
  public readonly label: InputSignal<string> = input<string>('');

  /**
   * Whether to render the view-mode value in a `<code>` element. Use for identifiers and other values a user
   * may need to compare character by character.
   * @default false
   * @toggle
   * @input
   */
  public readonly code: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(false, { transform: booleanAttribute });

  /**
   * Whether the value text is italic.
   * @default true
   * @toggle
   * @input
   */
  public readonly italic: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(true, { transform: booleanAttribute });

  /**
   * Whether the field value is currently loading. If true, a loading indicator is shown in place of the value.
   * @default false
   * @toggle
   * @input
   */
  public readonly loading: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(false, { transform: booleanAttribute });

  /**
   * Whether to show the N/A placeholder when the value is empty. If false, nothing will display.
   * @default true
   * @toggle
   * @input
   */
  public readonly showEmpty: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(true, { transform: booleanAttribute });

  /**
   * Whether the value text is bolded.
   * @default true
   * @toggle
   * @input
   */
  public readonly strong: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(true, { transform: booleanAttribute });

  /**
   * The number of decimal places to display for numeric values.
   * @default 0
   * @input
   */
  public readonly numberDecimals: InputSignalWithTransform<number, unknown> = input<number, unknown>(0, { transform: numberAttribute });

  /**
   * The field size density.
   * @default Default
   * @enums Small | Medium | Default
   * @input
   */
  public readonly density: InputSignal<PrimitiveFieldDensityEnum> = input<PrimitiveFieldDensityEnum>(PrimitiveFieldDensityEnum.Default);

  /**
   * The field type, which controls the form and how the value is displayed.
   * @default StringText
   * @enums StringText | NumberText | CurrencyText | Select | CheckboxToggle | SwitchToggle
   * @input
   */
  public readonly fieldType: InputSignal<PrimitiveFieldTypeEnum> = input<PrimitiveFieldTypeEnum>(PrimitiveFieldTypeEnum.StringText);

  public readonly value: InputSignal<PrimitiveValueType> = input<PrimitiveValueType>('Value');

  /**
   * The value rendered in view mode. Numeric input types are formatted with thousands separators (ex: 1,233.23).
   */
  protected readonly _displayValue: Signal<string> = computed(() => {
    const value = this.value();

    if (value === null || value === undefined || value === '') {
      return this.showEmpty() ? 'N/A' : '';
    }

    if (this.numberDecimals() !== undefined) {
      return NumberizeString(value, this.numberDecimals());
    }

    switch (this.fieldType()) {
      case PrimitiveFieldTypeEnum.NumberText:
      case PrimitiveFieldTypeEnum.CurrencyText:
        return NumberizeString(value, this.numberDecimals());
      default:
        return `${value}`;
    }
  });

  protected readonly _formValue: Signal<string> = computed(() => {
    switch (this.fieldType()) {
      case PrimitiveFieldTypeEnum.CheckboxToggle:
      case PrimitiveFieldTypeEnum.SwitchToggle:
        return this.value() === 'true' ? 'on' : 'off';
      default:
        return this.value().toString();
    }
  });

  protected readonly _isDenseNow: Signal<boolean> = computed(() => this.density() !== PrimitiveFieldDensityEnum.Default);

  protected readonly _isEmptyNow: Signal<boolean> = computed(() =>
    this.value() === null
    || this.value() === undefined
    || this.value() === '');

  static {
    IconRegistry.define([
      tylIconAttachMoney,
    ]);
  }
}
