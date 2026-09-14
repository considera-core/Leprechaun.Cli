import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PrimitiveFieldComponent } from './primitive-field.component';

describe('CommonDynamicLabelValueComponent', () => {
  let component: PrimitiveFieldComponent;
  let fixture: ComponentFixture<PrimitiveFieldComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PrimitiveFieldComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(PrimitiveFieldComponent);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
