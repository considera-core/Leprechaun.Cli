import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PrimitiveFieldEditComponent } from './primitive-field-edit.component';

describe('PrimitiveFieldEdit', () => {
  let component: PrimitiveFieldEditComponent;
  let fixture: ComponentFixture<PrimitiveFieldEditComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
                   imports: [PrimitiveFieldEditComponent],
                 })
                 .compileComponents();

    fixture = TestBed.createComponent(PrimitiveFieldEditComponent);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
