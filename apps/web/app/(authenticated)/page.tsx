import { prisma } from "@repo/db";
import type { Metadata } from "next";
import dynamic from "next/dynamic";
import { notFound } from "next/navigation";
import { Header } from "./components/header";
import { getServerSession } from "next-auth";
import { authOptions } from "@/app/api/auth/[...nextauth]/route"; // Import from your API file

const title = "Acme Inc";
const description = "My application.";


export const metadata: Metadata = {
  title,
  description,
};

const App = async () => {

  return (
    <>
      <Header page="Data Fetching" pages={["Building Your Application"]}>
      </Header>
      <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
        <div className="grid auto-rows-min gap-4 md:grid-cols-3">
        </div>
        <div className="min-h-[100vh] flex-1 rounded-xl bg-muted/50 md:min-h-min" />
      </div>
    </>
  );
};

export default App;
