import { SidebarProvider } from "@repo/design-system/components/ui/sidebar";
import type { ReactNode } from "react";
import { GlobalSidebar } from "./components/sidebar";
import { redirect } from 'next/navigation'
import { getServerSession } from "next-auth";
import { authOptions } from '@/lib/auth'

type AppLayoutProperties = {
  readonly children: ReactNode;
};

const AppLayout = async ({ children }: AppLayoutProperties) => {
  const session = await getServerSession(authOptions)
  const user = session?.user;

  if (!user) {
    redirect("/api/auth/signin?callbackUrl=/");
  }

  return (
    <SidebarProvider>
      <GlobalSidebar>
        {children}
      </GlobalSidebar>
    </SidebarProvider>
  );
};

export default AppLayout;
