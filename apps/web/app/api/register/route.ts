import { NextResponse } from "next/server";
import { prisma } from "@repo/db"; // Your shared DB package
import bcrypt from "bcryptjs";

export async function POST(req: Request) {
  try {
    const { email, password, name } = await req.json();

    if (!email || !password) {
      return new NextResponse("Missing email or password", { status: 400 });
    }

    // 1. Check if user exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return new NextResponse("User already exists", { status: 400 });
    }

    // 2. Hash Password
    const hashedPassword = await bcrypt.hash(password, 10);

    // 3. Create User
    const user = await prisma.user.create({
      data: {
        email,
        name,
        password: hashedPassword,
        plan: "free", // Default SaaS plan
      },
    });

    // Return the user without the password
    const { password: newUserPassword, ...userWithoutPassword } = user;

    return NextResponse.json(userWithoutPassword);
  } catch (error) {
    console.error("Registration Error:", error);
    return new NextResponse("Internal Error", { status: 500 });
  }
}
