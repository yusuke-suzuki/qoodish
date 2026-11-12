import type { PinProperty, PinPropertyOption } from '../../types/index.ts';

export const PIN_PROPERTY_NAME_LIMIT = 30;

export const PIN_PROPERTY_OPTION_NAME_LIMIT = 16;

export type PinPropertyAppearance = Pick<PinProperty, 'icon' | 'color'>;

export type PinPropertyOptionChanges = Partial<
  Pick<PinPropertyOption, 'name' | 'icon'>
>;

export function optionIcon(
  property: Pick<PinProperty, 'icon'>,
  option: Pick<PinPropertyOption, 'icon'>
): string | null {
  return option.icon ?? property.icon;
}

export function chooseOptions(
  selectedIds: number[],
  property: PinProperty,
  optionIds: number[]
): number[] {
  const propertyOptionIds = new Set(
    property.options.map((option) => option.id)
  );

  return [
    ...selectedIds.filter((id) => !propertyOptionIds.has(id)),
    ...optionIds.filter((id) => propertyOptionIds.has(id))
  ];
}

export function matchesOptions(
  pinOptionIds: number[],
  pinProperties: PinProperty[],
  chosenIds: number[]
): boolean {
  return pinProperties.every((property) => {
    const chosen = property.options
      .map((option) => option.id)
      .filter((id) => chosenIds.includes(id));

    return chosen.length < 1 || chosen.some((id) => pinOptionIds.includes(id));
  });
}

export function offeredOptionIds(
  pinProperties: PinProperty[],
  optionIds: number[]
): number[] {
  const offered = new Set(
    pinProperties.flatMap((property) =>
      property.options.map((option) => option.id)
    )
  );

  return optionIds.filter((id) => offered.has(id));
}
