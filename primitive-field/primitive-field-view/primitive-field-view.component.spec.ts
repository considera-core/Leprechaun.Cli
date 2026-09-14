import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PrimitiveFieldViewComponent } from './primitive-field-view.component';

describe('PrimitiveFieldView', () => {
  let component: PrimitiveFieldViewComponent;
  let fixture: ComponentFixture<PrimitiveFieldViewComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
                   imports: [PrimitiveFieldViewComponent],
                 })
                 .compileComponents();

    fixture = TestBed.createComponent(PrimitiveFieldViewComponent);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
