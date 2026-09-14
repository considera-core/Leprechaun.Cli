import { booleanAttribute, ChangeDetectionStrategy, Component, computed, input, InputSignal, InputSignalWithTransform, model, ModelSignal, Signal, signal, WritableSignal } from '@angular/core';
import { ControlValueAccessor } from '@angular/forms';
import { CheckboxComponent, IconRegistry, ISelectOption, SwitchComponent } from '@tylertech/forge';
import { ForgeCheckboxProxyModule, ForgeIconModule, ForgeSelectProxyModule, ForgeSwitchModule, ForgeTextFieldModule } from '@tylertech/forge-angular';
import { tylIconAttachMoney } from '@tylertech/tyler-icons';
import { PrimitiveFieldDensityEnum } from '../../../../types/primitives/primitive-field/enums/PrimitiveFieldDensityEnum';
import { PrimitiveFieldTypeEnum } from '../../../../types/primitives/primitive-field/enums/PrimitiveFieldTypeEnum';
import { PrimitiveValueType } from '../../../../types/core/PrimitiveValueType';

@Component({
  selector: 'consideracore-primitive-field-edit',
  templateUrl: './primitive-field-edit.component.html',
  styleUrl: './primitive-field-edit.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    ForgeCheckboxProxyModule,
    ForgeIconModule,
    ForgeSelectProxyModule,
    ForgeTextFieldModule,
    ForgeSwitchModule,
  ],
})
export class PrimitiveFieldEditComponent implements ControlValueAccessor {
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
   * <b>NOTE: Only use if this component is not being used in a form. If this component is being used in a form, use the form control's disabled state instead.
   * Whether the field is disabled. If true, the field is not interactable and editable.
   * @default false
   * @toggle
   * @input
   */
  public readonly disabled: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(false, { transform: booleanAttribute });

  /**
   * Whether the value is invalid. If true, the value text is rendered in red.
   * @default false
   * @toggle
   * @input
   */
  public readonly invalid: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(false, { transform: booleanAttribute });

  /**
   * Whether the field value is currently loading. If true, a loading indicator is shown in place of the value.
   * @default false
   * @toggle
   * @input
   */
  public readonly loading: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(false, { transform: booleanAttribute });

  /**
   * Shows a red asterisk indicating that the field is required. Only shows in edit value mode.
   * @default false
   * @toggle
   * @input
   */
  public readonly required: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(false, { transform: booleanAttribute });

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

  public readonly selectOptions: InputSignal<ISelectOption[]> = input<ISelectOption[]>([]);

  public readonly value: ModelSignal<PrimitiveValueType> = model<PrimitiveValueType>('Value');

  protected readonly _formDisabled: WritableSignal<boolean> = signal<boolean>(false);

  protected readonly _formValue: Signal<string> = computed(() => {
    switch (this.fieldType()) {
      case PrimitiveFieldTypeEnum.CheckboxToggle:
      case PrimitiveFieldTypeEnum.SwitchToggle:
        return this.value() === 'true' ? 'on' : 'off';
      default:
        return this.value().toString();
    }
  });

  protected readonly _isDenseNow: Signal<boolean> = computed(() =>
    this.density() !== PrimitiveFieldDensityEnum.Default);

  protected readonly _isDisabledNow: Signal<boolean> = computed(() =>
    this.disabled()
    || this._formDisabled());

  protected readonly _labelPosition: Signal<'inset' | 'inline-start' | 'none'> = computed(() => {
    if (this.required()) {
      return this._isDenseNow() ? 'inline-start' : 'inset';
    }

    return this.label() ? 'inset' : 'none';
  });

  protected readonly _labelAlignment: Signal<'default' | 'baseline'> = computed(() => {
    return this._labelPosition() === 'inline-start' ? 'baseline' : 'default';
  });

  private _onChangeFn: (value: PrimitiveValueType) => void = (value: PrimitiveValueType) => {};

  private _onTouchedFn: () => void = () => {};

  public registerOnChange(fn: (value: PrimitiveValueType) => void): void {
    this._onChangeFn = fn;
  }

  public registerOnTouched(fn: () => void): void {
    this._onTouchedFn = fn;
  }

  public setDisabledState?(state: boolean): void {
    this._formDisabled.set(state);
  }

  public writeValue(value: string): void {
    this.value.set(value);
  }

  protected _onChange(event: Event): void {
    const inputElement = event.target as HTMLInputElement;
    this.value.set(inputElement.value);
    this._onChangeFn(inputElement.value);
    this._onTouchedFn();
  }

  protected _onCheckboxChange(event: Event): void {
    const checkboxCmp = event.target as CheckboxComponent;
    this.value.set(checkboxCmp.checked ? 'true' : 'false');
    this._onChangeFn(checkboxCmp.checked ? 'true' : 'false');
    this._onTouchedFn();
  }

  protected _onSwitchChange(event: Event): void {
    const switchCmp = event.target as SwitchComponent;
    this.value.set(switchCmp.checked ? 'true' : 'false');
    this._onChangeFn(switchCmp.checked ? 'true' : 'false');
    this._onTouchedFn();
  }

  protected _onSelect(event: CustomEvent<string>): void {
    this.value.set(event.detail);
    this._onChangeFn(event.detail);
    this._onTouchedFn();
  }

  static {
    IconRegistry.define([
      tylIconAttachMoney,
    ]);
  }
}
