import { booleanAttribute, ChangeDetectionStrategy, Component, input, InputSignal, InputSignalWithTransform, model, ModelSignal, numberAttribute, signal, WritableSignal } from '@angular/core';
import { ControlValueAccessor, FormsModule, NG_VALUE_ACCESSOR, ReactiveFormsModule } from '@angular/forms';
import { CheckboxComponent, IconRegistry, ISelectOption } from '@tylertech/forge';
import { ForgeCheckboxModule, ForgeCircularProgressModule, ForgeIconModule, ForgeInlineMessageModule, ForgeLabelValueModule, ForgeSelectModule, ForgeSkeletonModule, ForgeTextFieldModule } from '@tylertech/forge-angular';
import { tylIconAttachMoney, tylIconExposurePlus1, tylIconTextFields } from '@tylertech/tyler-icons';
import { PrimitiveFieldDensityEnum } from '../../../types/primitives/primitive-field/enums/PrimitiveFieldDensityEnum';
import { PrimitiveFieldOperationEnum } from '../../../types/primitives/primitive-field/enums/PrimitiveFieldOperationEnum';
import { PrimitiveFieldTypeEnum } from '../../../types/primitives/primitive-field/enums/PrimitiveFieldTypeEnum';
import { IPrimitiveFieldState } from '../../../types/primitives/primitive-field/interfaces/IPrimitiveFieldState';
import { PrimitiveValueType } from '../../../types/core/PrimitiveValueType';
import { PrimitiveFieldEditComponent } from './primitive-field-edit/primitive-field-edit.component';
import { PrimitiveFieldViewComponent } from './primitive-field-view/primitive-field-view.component';

@Component({
  selector: 'consideracore-primitive-field',
  templateUrl: './primitive-field.component.html',
  styleUrl: './primitive-field.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    ForgeLabelValueModule,
    ForgeSkeletonModule,
    ForgeTextFieldModule,
    FormsModule,
    ReactiveFormsModule,
    ForgeSelectModule,
    ForgeCheckboxModule,
    ForgeCircularProgressModule,
    ForgeIconModule,
    PrimitiveFieldViewComponent,
    PrimitiveFieldEditComponent,
    ForgeInlineMessageModule,
  ],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: PrimitiveFieldComponent,
      multi: true,
    },
  ],
})
export class PrimitiveFieldComponent implements ControlValueAccessor {
  public readonly PrimitiveFieldTypeEnum = PrimitiveFieldTypeEnum;

  public readonly PrimitiveFieldOperationEnum = PrimitiveFieldOperationEnum;

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
   * Whether the field can be interacted with and editable.
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
   * Shows a red asterisk indicating that the field is required. Only shows in edit value mode.
   * @default false
   * @toggle
   * @input
   */
  public readonly required: InputSignalWithTransform<boolean, unknown> = input<boolean, unknown>(false, { transform: booleanAttribute });

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

  /**
   * The field operation, which controls whether the field is in view or edit mode.
   * @default View
   * @enums View | Edit
   * @input
   */
  public readonly fieldOperation: InputSignal<PrimitiveFieldOperationEnum> = input<PrimitiveFieldOperationEnum>(PrimitiveFieldOperationEnum.View);

  public readonly selectOptions: InputSignal<ISelectOption[]> = input<ISelectOption[]>([]);

  public readonly value: ModelSignal<string | boolean | number> = model<string | boolean | number>('Value');

  protected readonly _formDisabled: WritableSignal<boolean> = signal<boolean>(false);

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

  /**
   * Propagates value changes from the edit field to this component's model and form control.
   */
  protected _onValueChange(value: PrimitiveValueType): void {
    this.value.set(value);
    this._onChangeFn(value);
    this._onTouchedFn();
  }

  protected _onChange(event: Event): void {
    const inputElement = event.target as HTMLInputElement;
    this.value.set(inputElement.value);
    this._onChangeFn(inputElement.value);
    this._onTouchedFn();
  }

  protected _onCheckboxChange(event: Event): void {
    const checkbox = event.target as CheckboxComponent;
    this.value.set(checkbox.checked ? 'true' : 'false');
    this._onChangeFn(checkbox.checked ? 'true' : 'false');
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
      tylIconTextFields,
      tylIconExposurePlus1,
    ]);
  }
}
