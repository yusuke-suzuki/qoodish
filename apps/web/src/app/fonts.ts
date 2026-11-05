import { Lobster, Shippori_Mincho } from 'next/font/google';

const lobster = Lobster({
  subsets: ['latin'],
  weight: '400',
  variable: '--font-lobster',
  display: 'swap'
});

const shipporiMincho = Shippori_Mincho({
  weight: ['400', '700'],
  subsets: ['latin'],
  variable: '--font-shippori-mincho',
  display: 'swap',
  preload: false
});

export const fontVariables = `${lobster.variable} ${shipporiMincho.variable}`;
