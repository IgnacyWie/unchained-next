"use client";

import { useSession, signIn, signOut } from "next-auth/react";
import { Button } from "@repo/ui/button"

export default function Home() {
  const { data: session, status } = useSession();

  if (status === "loading") {
    return <div className="p-10">Loading session...</div>;
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-gray-100 text-black">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex flex-col gap-6 bg-white p-10 rounded-xl shadow-lg">

        <h1 className="text-3xl font-bold mb-4">NextAuth Credentials Provider + Next.js Integration</h1>

        {status === "authenticated" ? (
          <div className="w-full text-center space-y-4">
            <div className="p-4 bg-green-100 text-green-800 rounded border border-green-300">
              <p className="font-bold">✅ Authenticated</p>
              <p>Welcome, {session.user?.name}</p>
              <p className="text-xs mt-2 text-gray-600">Email: {session.user?.email}</p>
            </div>

            <div className="bg-gray-50 p-4 rounded text-left overflow-auto max-h-60">
              <p className="font-bold mb-2">Session Data:</p>
              <pre className="text-xs">{JSON.stringify(session, null, 2)}</pre>
            </div>

            <Button
              onClick={() => signOut()}
            >
              Sign Out
            </Button>
          </div>
        ) : (
          <div className="w-full text-center space-y-4">
            <div className="p-4 bg-yellow-100 text-yellow-800 rounded border border-yellow-300">
              <p className="font-bold">🔒 Not Authenticated</p>
              <p>You are currently a guest.</p>
            </div>

            <Button
              onClick={() => signIn()}
              className="px-6 py-3 bg-blue-600 text-white font-bold rounded hover:bg-blue-700 transition"
            >
              Sign In
            </Button>
          </div>
        )}

      </div>
    </main>
  );
}
