'use client';

import { CssBaseline, ThemeProvider } from '@mui/material';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import type { ReactNode } from 'react';
import DictionaryContext from '../../context/DictionaryContext.ts';
import type { Dictionary } from '../../utils/getDictionary.ts';
import { createAppTheme } from '../../utils/theme.ts';

type Props = {
  children: ReactNode;
  lang: string;
  dictionary: Dictionary;
};

export default function OfflineProviders({
  children,
  lang,
  dictionary
}: Props) {
  const theme = createAppTheme(lang);

  return (
    <AppRouterCacheProvider>
      <ThemeProvider theme={theme}>
        <CssBaseline enableColorScheme />
        <DictionaryContext.Provider value={dictionary}>
          {children}
        </DictionaryContext.Provider>
      </ThemeProvider>
    </AppRouterCacheProvider>
  );
}
