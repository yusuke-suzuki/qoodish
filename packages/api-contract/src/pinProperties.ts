export type PinPropertyOption = {
  id: number;
  name: string;
  position: number;
  icon: string | null;
};

export type PinProperty = {
  id: number;
  name: string;
  multiple: boolean;
  position: number;
  icon: string | null;
  color: string | null;
  options: PinPropertyOption[];
};
