import { ModeToggle } from "@repo/design-system/components/mode-toggle";
import { Suspense } from 'react';
import { TriangleDashedIcon } from "lucide-react";
import type { ReactNode } from "react";

// 1. Add these imports for server-side session checking
import { redirect } from 'next/navigation';
import { getServerSession } from "next-auth";
import { authOptions } from '@/lib/auth';

type AuthLayoutProps = {
  readonly children: ReactNode;
};

// 2. Make the component async
const AuthLayout = async ({ children }: AuthLayoutProps) => {

  // 3. Check the session
  const session = await getServerSession(authOptions);

  // 4. If user exists, redirect them to home (or dashboard)
  if (session?.user) {
    redirect("/");
  }

  return (
    <div className="relative flex h-dvh w-full flex-col items-center justify-center overflow-hidden bg-gray-50 dark:bg-zinc-950">

      {/* --- BACKGROUND LAYERS --- */}

      {/* 1. Gradient Mesh Orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -left-[10%] -top-[10%] h-[50vw] w-[50vw] rounded-full bg-purple-700/20 blur-[120px] filter" />
        <div className="absolute -right-[10%] -bottom-[20%] h-[50vw] w-[50vw] rounded-full bg-indigo-700/20 blur-[120px] filter" />
        <div className="absolute top-1/2 left-1/2 h-[40vw] w-[40vw] -translate-x-1/2 -translate-y-1/2 rounded-full bg-cyan-600/10 blur-[100px] filter" />
      </div>

      {/* 2. Technical Grid Pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px] pointer-events-none">
        <div className="absolute inset-0 bg-[radial-gradient(circle_800px_at_center,#00000000,transparent)]" />
      </div>

      {/* --- ABSOLUTE UI ELEMENTS (Corners) --- */}

      <div className="absolute top-8 left-8 z-20 flex items-center font-medium text-lg text-black dark:text-white">
        <TriangleDashedIcon className="mr-2 h-6 w-6" />
        Unchained Next
      </div>

      <div className="absolute top-8 right-8 z-20">
        <ModeToggle />
      </div>

      <div className="absolute bottom-8 right-8 z-20 hidden max-w-md text-black dark:text-white lg:block">
        <blockquote className="space-y-2">
          <p className="text-lg text-right">
            &ldquo;I was sick of paying per-user fees for simple auth and databases. This stack saved me thousands in yearly SaaS costs and countless hours of DevOps headaches.&rdquo;
          </p>
          <footer className="text-sm opacity-80 text-right">Ignacy Wielogórski</footer>
        </blockquote>
      </div>

      {/* --- CENTER CONTENT --- */}

      <div className="relative z-30 w-full max-w-[600px] px-4">
        <Suspense>
          {children}
        </Suspense>
      </div>

    </div>
  );
};

export default AuthLayout;
