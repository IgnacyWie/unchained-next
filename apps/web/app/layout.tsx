import "./styles.css";

import type { Metadata } from "next";
import { Inter } from "next/font/google";
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
          <body className={inter.className}>{children}</body>
        </DesignSystemProvider>
      </Providers>
    </html>
  );
}
