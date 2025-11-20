"use client";

import { useState } from "react";
import { Button } from "@repo/design-system/components/ui/button"
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function RegisterPage() {
  const router = useRouter();
  const [data, setData] = useState({ name: "", email: "", password: "" });
  const [error, setError] = useState("");

  const registerUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    const response = await fetch("/api/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });

    if (response.ok) {
      router.push("/login"); // Redirect to login after success
    } else {
      const text = await response.text();
      setError(text);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100">
      <div className="w-full max-w-md p-8 space-y-6 bg-white rounded shadow-md">
        <h2 className="text-2xl font-bold text-center text-gray-900">Create Account</h2>

        {error && <div className="p-3 text-sm text-red-500 bg-red-100 rounded">{error}</div>}

        <form onSubmit={registerUser} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Name</label>
            <input
              type="text"
              className="w-full p-2 mt-1 border rounded focus:ring-blue-500 focus:border-blue-500 text-black"
              value={data.name}
              onChange={(e) => setData({ ...data, name: e.target.value })}
            />
          </div>

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
            Register
          </Button>
        </form>

        <p className="text-sm text-center text-gray-600">
          Already have an account?{" "}
          <Link href="/login" className="text-blue-600 hover:underline">
            Sign In
          </Link>
        </p>
      </div>
    </div>
  );
}
