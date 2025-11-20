import NextAuth, { AuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import { PrismaAdapter } from "@next-auth/prisma-adapter";
import { prisma } from "@repo/db"; // Importing from your shared package
import bcrypt from "bcryptjs";

export const authOptions: AuthOptions = {
  // 1. The Adapter: Handles reading/writing to the DB for you
  // (Crucial if you add Google/GitHub login later)
  adapter: PrismaAdapter(prisma),

  // 2. The Session Strategy
  // SaaS apps usually use "jwt" to avoid hitting the DB on every single page load.
  session: {
    strategy: "jwt",
  },

  // 3. The Secret (Must match your .env)
  secret: process.env.NEXTAUTH_SECRET,

  // 4. The Pages (Optional, but recommended)
  // If you don't define these, NextAuth gives you a generic ugly gray login page.
  pages: {
    signIn: "/login",
    // newUser: "/register", // If you want to redirect after sign up
  },

  // 5. The Providers
  providers: [
    CredentialsProvider({
      name: "Credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        // A. Input Validation
        if (!credentials?.email || !credentials?.password) {
          throw new Error("Missing email or password");
        }

        // B. Find User in DB
        const user = await prisma.user.findUnique({
          where: { email: credentials.email },
        });

        // C. Security Check:
        // If user not found, OR user has no password (e.g. they signed up via Google)
        if (!user || !user.password) {
          throw new Error("Invalid credentials");
        }

        // D. Compare Password Hash
        const isValid = await bcrypt.compare(
          credentials.password,
          user.password
        );

        if (!isValid) {
          throw new Error("Invalid credentials");
        }

        // E. Return the user (This object is passed to the JWT callback)
        return {
          id: user.id,
          name: user.name,
          email: user.email,
          // You can add 'plan: user.plan' here if you want it in the token
        };
      },
    }),
  ],

  // 6. Callbacks
  // This is how you get the 'id' onto the client side (req.session.user.id)
  callbacks: {
    async jwt({ token, user }) {
      // The 'user' argument is only passed the first time they sign in.
      if (user) {
        token.id = user.id;
        // token.plan = user.plan; // If you returned plan above
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        // Pass the ID from the token to the session
        // @ts-ignore (Typescript might complain about 'id' missing on default types)
        session.user.id = token.id as string;
        // session.user.plan = token.plan;
      }
      return session;
    },
  },
};

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };
