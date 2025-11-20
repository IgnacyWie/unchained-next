import { NextResponse } from "next/server";
import { prisma } from "@repo/db";
import bcrypt from "bcryptjs"; // or your preferred hashing library

export async function POST(req: Request) {
  const { token, password } = await req.json();

  // 1. Find user with valid token and non-expired date
  const user = await prisma.user.findFirst({
    where: {
      resetToken: token,
      resetTokenExpiry: { gt: new Date() }, // Expiry must be in the future
    },
  });

  if (!user) {
    return NextResponse.json({ error: "Invalid token" }, { status: 400 });
  }

  // 2. Hash new password
  const hashedPassword = await bcrypt.hash(password, 10);

  // 3. Update user and clear token
  await prisma.user.update({
    where: { id: user.id },
    data: {
      password: hashedPassword,
      resetToken: null,
      resetTokenExpiry: null,
    },
  });

  return NextResponse.json({ message: "Password updated" });
}
