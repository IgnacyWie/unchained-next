"use client";

import { Button } from "@repo/design-system/components/ui/button"
import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function LoginPage() {
  const router = useRouter();
  const [data, setData] = useState({ email: "", password: "" });
  const [error, setError] = useState("");

  const loginUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    // This calls the 'authorize' function in [...nextauth]/route.ts
    const result = await signIn("credentials", {
      ...data,
      redirect: false, // We handle the redirect manually
    });

    if (result?.error) {
      setError("Invalid email or password");
    } else {
      router.push("/"); // Redirect to dashboard
      router.refresh();
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100">
      <div className="w-full max-w-md p-8 space-y-6 bg-white rounded shadow-md">
        <h2 className="text-2xl font-bold text-center text-gray-900">Sign In</h2>

        {error && <div className="p-3 text-sm text-red-500 bg-red-100 rounded">{error}</div>}

        <form onSubmit={loginUser} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              required
              className="w-full p-2 mt-1 border rounded focus:ring-blue-500 focus:border-blue-500 text-black"
              value={data.email}
              onChange={(e) => setData({ ...data, email: e.target.value })}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Password</label>
            <input
              type="password"
              required
              className="w-full p-2 mt-1 border rounded focus:ring-blue-500 focus:border-blue-500 text-black"
              value={data.password}
              onChange={(e) => setData({ ...data, password: e.target.value })}
            />
          </div>

          <Button
            type="submit"
            className="w-full"
          >
            Sign In
          </Button>
        </form>

        <p className="text-sm text-center text-gray-600">
          Don't have an account?{" "}
          <Link href="/register" className="text-blue-600 hover:underline">
            Register
          </Link>
        </p>
      </div>
    </div>
  );
}
