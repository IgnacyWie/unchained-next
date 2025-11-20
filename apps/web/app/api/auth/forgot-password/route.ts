import { NextResponse } from "next/server";
import crypto from "crypto";
import { prisma } from "@repo/db"; // Adjust your prisma import
import { sendEmail } from "@/lib/email"; // You need an email service (Resend, SendGrid, etc)

export async function POST(req: Request) {
  try {
    const { email } = await req.json();

    // 1. Check if user exists
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      // Return 200 even if user doesn't exist to prevent email enumeration attacks
      return NextResponse.json({ message: "Email sent" }, { status: 200 });
    }

    // 2. Generate Reset Token
    const resetToken = crypto.randomBytes(32).toString("hex");
    // Token expires in 1 hour
    const passwordResetExpires = new Date(Date.now() + 3600000);

    // 3. Save to DB
    await prisma.user.update({
      where: { email },
      data: {
        resetToken,
        resetTokenExpiry: passwordResetExpires,
      },
    });

    // 4. Send Email
    const resetUrl = `${process.env.NEXTAUTH_URL}/reset-password?token=${resetToken}`;

    // Implementation depends on your email provider (Resend example below)
    await sendEmail({
      to: email,
      subject: "Reset your password",
      html: `<p>Click <a href="${resetUrl}">here</a> to reset your password.</p>`
    });

    return NextResponse.json({ message: "Email sent" }, { status: 200 });
  } catch (error) {
    return NextResponse.json({ message: "Error" }, { status: 500 });
  }
}
