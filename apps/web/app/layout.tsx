import "./styles.css";

import type { Metadata } from "next";
import { Inter } from "next/font/google";
import Script from 'next/script'
import { Providers } from "./providers";
import { DesignSystemProvider } from "@repo/design-system";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Unchained Next",
  description: "Built with Next.js and Turbo",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <Providers>
        <DesignSystemProvider>
          <Script src='https://a.wie.dev/umami' data-website-id='49eedf35-7f07-4e96-a023-c4b1503bfd7a' strategy='beforeInteractive' />
          <body className={inter.className}>{children}</body>
        </DesignSystemProvider>
      </Providers>
    </html>
  );
}
