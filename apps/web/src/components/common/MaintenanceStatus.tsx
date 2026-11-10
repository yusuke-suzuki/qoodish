import { connection } from 'next/server';
import { getMaintenance, maintenanceMessage } from '../../lib/maintenance.ts';
import { getDictionary } from '../../utils/getDictionary.ts';
import MaintenanceNotice from './MaintenanceNotice.tsx';

type Props = {
  lang: string;
};

export default async function MaintenanceStatus({ lang }: Props) {
  // The build prerenders this with no Workers context to read the flag from.
  await connection();

  const message = maintenanceMessage(
    await getMaintenance(),
    lang,
    getDictionary(lang)
  );

  return <MaintenanceNotice message={message} />;
}
